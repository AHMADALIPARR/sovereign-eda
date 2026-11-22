# Sovereign EDA

## Malbolge, Ternary Machines, and the Hardware That Runs Them

![License](https://img.shields.io/badge/license-SNAPKITTY%20Opaque%20Source%201.0-blue)
![C11](https://img.shields.io/badge/C-11-00599C)
![VHDL](https://img.shields.io/badge/VHDL-2008-1D3557)
![WhyML](https://img.shields.io/badge/WhyML-Why3-6A1B9A)
![Cryptol](https://img.shields.io/badge/Cryptol-3.0-0B6E8F)
![CUDA](https://img.shields.io/badge/CUDA-sm__70-76B900)
![Lean](https://img.shields.io/badge/Lean-4-4A90D9)
![AWK](https://img.shields.io/badge/AWK-POSIX-4EAA25)

Sovereign EDA is an electronic design automation workspace. It holds two projects in one tree. The first is Malbolge, the ternary virtual machine, carried from the reference interpreter through a bit-precise hardware ALU, a formal semantics, and a GPU execution engine. A machine word is ten trits wide. Memory holds 59049 words. Code and data share the same memory, and a program rewrites itself as it runs. The second is the board: a plain-text circuit board format and a zero-dependency POSIX awk EDA compiler, with a pure-awk circuit solver, a dual-circuit project with formal semantics and proof gates, and an SRAM write-cell.

The repository is the machines and their evidence in one place. The reference interpreter runs the Malbolge machine. The VHDL ALU computes the same operations in hardware. The WhyML and Cryptol layers state the same operations as contracts. The Lean formalization states the processor, its invariants, and its determinism. The CUDA and PTX kernels run the same operations on the GPU, one Malbolge virtual machine per thread. The board compiler turns a plain-text board into a SPICE deck, a Verilog-A file, a structural netlist, or a KiCad netlist, with no dependency beyond awk. The chain is:

$$\text{Interpreter} \;\to\; \text{ALU} \;\to\; \text{Contracts} \;\to\; \text{Formalization} \;\to\; \text{GPU}$$

and, for the board:

$$\text{board.txt} \;\to\; \text{eda.awk} \;\to\; \text{SPICE / Verilog-A / netlist / KiCad}$$

with each layer agreeing with the others on the same operations, the same encodings, and the same semantics.

## At a glance

| Property | Value |
| --- | --- |
| Machine | Malbolge, ternary virtual machine |
| Word | 10 trits, values 0 to 59048 |
| Memory | 59049 words, code and data share one space |
| Registers | `a` accumulator, `c` code pointer, `d` data pointer |
| Arithmetic | Crazy operation, tritwise rotate, mod-3 add and subtract |
| Tryte packing | 20-bit `uint32_t`, 10 trits at 2 bits per trit, 00 = Zero, 01 = One, 10 = Two |
| Decode | `(c + mem[c]) mod 94` |
| Encipherment | 94-character permutation applied to the word at the code pointer after each non-halting step |
| Reference interpreter | Ben Olmstead 1998 public-domain C, full machine executable |
| Hardware ALU | 16-bit encoded combinational 10-trit ALU: crazy, rotate, valid |
| Formal semantics | WhyML definitions and proof obligations; Cryptol port contract; SAW/Yosys equivalence |
| Lean formalization | Trit, Tryte, MalbolgeProcessor, invariants, determinism, entropy-gated kernel |
| GPU kernels | CUDA C++ and PTX assembly, sm_70, one 59049-tryte VM per thread |
| GPU arithmetic | Elementwise tritAdd, tritSub, crazyOp, permuteTryte over packed trytes |
| Board format | Plain-text, one component per line, whitespace-delimited, `#` comments |
| Board compiler | Zero-dependency POSIX awk: SPICE, Verilog-A, netlist, KiCad modes |
| Board solver | Pure-awk MNA, DC and transient, nonlinear diodes by Newton-Raphson |
| Dual-circuit state machine | Idle, Calibrate, Run, Fault; mode as 2 bits; locked when running |
| Dual-circuit layers | WhyML semantics, Cryptol contracts, SAW proof gates, VHDL RTL, Verilog-A analog, PSL properties |
| Dual-circuit RTL | p4_controller, dual_circuit structural top, sram_bank, phase_calibrator |
| SRAM write-cell | WhyML semantics, Cryptol contract, SAW equivalence, VHDL RTL |
| Implementation languages | C11, VHDL-2008, WhyML, Cryptol, Lean 4, CUDA C++, PTX, POSIX awk, Verilog-A |
| License | SNAPKITTY OPAQUE SOURCE LICENSE v1.0 |

## How it works

The machine fetches the word at the code pointer, decodes it, executes it, encrypts the word it just ran, and increments both pointers. The decode is position-sensitive: the instruction is `(c + mem[c]) mod 94`, so the same word means different things at different addresses.

| Value | Instruction |
| --- | --- |
| 4 | `c = mem[d]`, jump |
| 5 | Output `a mod 256` |
| 23 | `a = input`, EOF reads 59048 |
| 39 | `a = mem[d] = rotate(mem[d])` |
| 40 | `d = mem[d]` |
| 62 | `a = mem[d] = crazy(a, mem[d])` |
| 68 | No operation |
| 81 | Halt, before encryption and increments |
| other | No operation |

After a non-halting instruction runs, the word at the code pointer is replaced through a 94-character permutation indexed by the word's value minus 33. Then `c` and `d` each increment mod 59049. The program rewrites itself as it runs: an instruction is never executed twice from the same memory state.

## The crazy operation

The machine's arithmetic is the crazy operation, a tritwise lookup over the accumulator trit and the data trit:

| [D] \ A | 0 | 1 | 2 |
| ------- | - | - | - |
| 0       | 1 | 0 | 0 |
| 1       | 1 | 0 | 2 |
| 2       | 2 | 2 | 1 |

The Lean formalization and the GPU kernels use the owner's own crazy table, which differs from the standard table in rows 1 and 2:

| a \ b | 0 | 1 | 2 |
| ----- | - | - | - |
| 0     | 1 | 0 | 0 |
| 1     | 2 | 2 | 1 |
| 2     | 0 | 2 | 2 |

The two tables live in different layers. The circuit and the reference interpreter run the original Malbolge table. The Lean and GPU layers run the owner's variant. The GPU encodes the variant as a 32-bit lookup table, `0x00281A01`, indexed by `(a << 2) | b` with 2 bits per entry.

The other trit operations are mod-3 addition and subtraction, and permute: rotate the tryte left by one trit, then apply the crazy operation of each trit with itself. Rotate moves trit 0 to trit 9 and shifts the rest down by one position.

## Mathematical foundations

### The tryte

A tryte is an array of 10 trits. Its value is the base-3 number the trits spell, and it always lies below 59049:

$$\text{tryteToNat}(t) = \sum_{i=0}^{9} t_i \cdot 3^{9-i}$$

where $t_0$ is the first trit in the array. The inverse direction writes a natural number into a tryte by repeated division:

$$\text{natToTryte}(n)_i = (n / 3^i) \bmod 3$$

The two directions use opposite ends of the array: `tryteToNat` reads the first trit as the most significant digit, `natToTryte` writes the least significant digit first. No theorem in the formalization asserts the roundtrip; the definitions stand as written.

### The processor

The processor is the tuple $(A, C, D, M, E, s)$: the three registers, the 59049-word memory, the entropy, and the step count. A step decodes the instruction at $C$, executes it against $D$, and increments both pointers mod 59049. The invariants are memory size, tryte width, register validity, and the entropy bound. The step function is deterministic: the same processor state always steps to the same next state. The kernel gates stepping on entropy: a step runs only while the memory entropy stays below the 0.20 threshold.

### The GPU execution

Each tryte is a 20-bit packed `uint32_t`. The CUDA kernels implement the same operations the Lean file defines: `tritAdd`, `tritSub`, `crazyOp`, `tryteToNat`, `natToTryte`, `incrementTryte`, `crazyTryte`, `decryptTryte`, `permuteTryte`, and `decodeInstruction`. The arithmetic kernel applies one operation elementwise across an array of packed trytes. The run kernel gives each thread its own 59049-tryte virtual machine and steps it deterministically. The PTX kernel implements the same operations in assembly for sm_70, with the crazy operation as a shift into the `0x00281A01` lookup table.

A second kernel set, v2, sits beside v1 and does not replace it. It fixes `tryteToNat` so that slot i is the 3^i digit and the roundtrip `tryteToNat (natToTryte n) = n` holds for all 59049 values, and it evaluates the elementwise operations as SWAR bitplane arithmetic: all ten trits of a packed tryte in parallel inside one `uint32_t`, from the `0x55555` / `0xAAAAA` planes, with no loop and no per-lane call. The v2 PTX also carries a scalar kernel with the operation bodies inlined, and a `crazy_op` that collapses the shift-and-mask into a single `bfe.u32`. The per-trit operations are identical between v1 and v2, so `crazyTryte`, `decryptTryte`, and `permuteTryte` agree bit for bit; only the addressing changes. The v2 Lean file, `MalbolgeTryteV2.lean`, states the fixed `tryteToNat` and proves the base-3 digit-reconstruction lemma behind the roundtrip.

## The board

A board is a plain-text file. One component or directive per line, whitespace-delimited, with `#` or `*` comments. A reference designator, its nets, and its value or model:

```
# RC Low-Pass Filter + Diode Clipper
V1   in   0     SIN(0 5 1k)
R1   in   out   1k
C1   out  0     100n
D1   out  0     DMOD

.model DMOD D(IS=1e-14 N=1)
.tran 10u 5m
```

A node or net is the shared bus: fan-out is just multiple lines referencing the same net token. Ground is `0`. The extended format adds subcircuits (`.subckt` / `.ends`) and inline Verilog-A behavioral blocks (`.va` / `.endva`).

The compiler is a single POSIX awk script, `eda.awk`, with no dependency beyond awk. It reads a board and emits one of four outputs, selected by `-v mode=`:

| Mode | Output |
| ---- | ------ |
| `spice` (default) | A SPICE deck, with `.hdl` Verilog-A links, ground normalized to `0`, and ERC checks |
| `veriloga` / `va` | A complete Verilog-A file: the `.va` behavioral modules plus a synthesized `board_top` module translating R, C, L, V, I, and X instances into KCL branch contributions, with SI-to-scientific unit conversion |
| `netlist` | A component table, net-to-pin connectivity with fanout degree, and an aggregated BOM |
| `kicad` | A KiCad S-expression netlist |

The ERC flags floating nets (degree 1, excluding ground) to stderr. The solver, `mna.awk`, is a pure-awk Modified Nodal Analysis solver: it reads a board directly, solves DC operating points and Backward-Euler transient simulations, including nonlinear diodes by Newton-Raphson, and streams time-series node voltages to stdout. Blocks wire together over UNIX pipes: a signal generator feeds the RC filter feeds a plotter, and a named pipe feeds a downstream stage back into a summing stage for feedback loops.

## The p4-dual-circuit

The dual-circuit is a controller with a four-state mode machine: Idle, Calibrate, Run, Fault. Mode is 2 bits. The controller locks when it runs, and a write to SRAM is only enabled while locked and running. The structural top, `dual_circuit`, wires three blocks together: the `p4_controller`, the `sram_bank`, and the `phase_calibrator`, with two oscillator clocks feeding the calibrator.

The layers agree on the same state machine:

| Layer | Files | What it states |
| ----- | ----- | -------------- |
| WhyML semantics | `board/p4-dual-circuit/semantics/state.mlw`, `board/p4-dual-circuit/semantics/sram.mlw`, `board/p4-dual-circuit/semantics/oscillator.mlw`, `board/p4-dual-circuit/semantics/refinement.mlw` | The mode type, the state invariants, the SRAM read/write, the oscillator, and the refinement from the abstract state to the circuit |
| Cryptol contracts | `board/p4-dual-circuit/cryptol/State.cry`, `board/p4-dual-circuit/cryptol/SRAM.cry`, `board/p4-dual-circuit/cryptol/CircuitContract.cry` | The executable state step, the SRAM model, and the circuit contract; run-implies-locked as a property |
| SAW proof gates | `board/p4-dual-circuit/saw/digital_equivalence.saw`, `board/p4-dual-circuit/saw/sram_refinement.saw`, `board/p4-dual-circuit/saw/proof_gate.saw` | Yosys imports the RTL and verifies it against the Cryptol contracts; the proof gate runs both and prints the pass line |
| VHDL RTL | `board/p4-dual-circuit/rtl/p4_controller.vhd`, `board/p4-dual-circuit/rtl/dual_circuit.vhd`, `board/p4-dual-circuit/rtl/sram_bank.vhd`, `board/p4-dual-circuit/rtl/phase_calibrator.vhd` | The synthesizable controller, the structural top, the SRAM bank, and the phase calibrator |
| Verilog-A analog | `board/p4-dual-circuit/analog/oscillator.va`, `board/p4-dual-circuit/analog/relaxation.va`, `board/p4-dual-circuit/analog/parasitic_model.sp` | The oscillator and relaxation analog blocks, and the parasitic model |
| Verification | `board/p4-dual-circuit/verification/psl/dual_circuit.psl`, `board/p4-dual-circuit/verification/pex/pex_rc_check.awk`, `board/p4-dual-circuit/verification/thermal/thermal_sweep.sp`, `board/p4-dual-circuit/verification/tb_p4_controller.vhd`, `board/p4-dual-circuit/verification/tb_sram_bank.vhd`, `board/p4-dual-circuit/verification/tb_dual_circuit.vhd` | PSL properties on the controller, an RC delay and coupling budget checker, a thermal sweep, and GHDL testbenches on the controller, the SRAM bank, and the structural top |

The SRAM write-cell, in `board/sram-write-cell/`, is the same pattern at one-cell scale: a WhyML semantics, a Cryptol contract, a SAW equivalence, and a VHDL RTL, all stating the same write: if enabled, the result is the new value, else the old value.

## Layout

| Path | Contents |
| ---- | -------- |
| `malbolge-circuit/` | The Malbolge circuit project: reference interpreter, VHDL ALU, WhyML, Cryptol, SAW, tests, docs, examples |
| `lean/` | `MalbolgeProcessor.lean`: the original Malbolge processor formalization, reproduced from photos; `MalbolgeProcessorRoot.lean`: the Malbolge processor formalization, verbatim; `MalbolgePTXKernel.lean`: the PTX kernel specification, verbatim; `MalbolgeTryteV2.lean`: the v2 tryte formalization with the fixed `tryteToNat` |
| `gpu/` | `malbolge_ternary.cu`: CUDA kernels for the ternary tryte operations and the deterministic Malbolge processor step; `malbolge_ternary.ptx`: the PTX assembly kernel for the same operations; `malbolge_ternary_v2.cu` and `malbolge_ternary_v2.ptx`: the v2 benchmark kernels, fixed `tryteToNat` and SWAR packed operations |
| `gpu/tests/` | `verify_cuda_host.c`: host-side C verification of the CUDA device functions against the Lean definitions, no GPU needed; `verify_v2_host.c`: host-side verification of the v2 kernels against v1 and the Lean v2 definitions; `bench_v1_v2.c`: host CPU proxy benchmark of v1 vs v2 |
| `board/` | The actual board: `eda.awk` is the full compiler; `eda-basic.awk` is the first version; `mna.awk` is the MNA solver; `examples/` holds board files |
| `board/p4-dual-circuit/` | The dual-circuit project: `semantics/` (WhyML), `cryptol/` (Cryptol), `saw/` (SAW proof gates), `rtl/` (VHDL), `analog/` (Verilog-A and SPICE), `verification/` (PSL, PEX checker, thermal sweep, GHDL testbenches), `Makefile` (analyze, test, prove) |
| `board/sram-write-cell/` | The SRAM write-cell: WhyML semantics, Cryptol contract, SAW equivalence, VHDL RTL, `Makefile` (analyze, test, prove), `verification/tb_sram_write_cell.vhd` |
| `requirements/`, `architecture/`, `verification/`, `assurance/`, `configuration/`, `operations/`, `reports/` | The engineering evidence: requirements and traceability, design and decisions, the verification record, hazards, risks and defects, toolchain locks and baselines, deployment and recovery, the release-readiness report and the gate logs |
| `scripts/` | `release-gate.sh`: the release gate, which runs the checks that can run on the machine it runs on and fails the tree on any failure or block |
| `STATUS.md` | Verification record |

## Build and run

Build the reference interpreter and run the smoke test:

```sh
cc -std=c11 -O2 -Wall -Wextra malbolge-circuit/reference/malbolge.c -o malbolge
./malbolge malbolge-circuit/examples/nop_halt.mal
```

Run the mathematical test oracle:

```sh
cd malbolge-circuit && make test
```

Generate the ALU netlist and run the SAW equivalence proof:

```sh
cd malbolge-circuit && make analyze
cd malbolge-circuit && make prove
```

The netlist goes through GHDL synthesis to Verilog plus Yosys
`read_verilog`, since Ubuntu does not ship the Yosys GHDL plugin.
The proof uses bitwuzla and takes about six seconds. The WhyML
proof runs with `make whyml` in `malbolge-circuit/`.

Run the board testbenches:

```sh
cd board/p4-dual-circuit && make test
cd ../sram-write-cell && make test
```

Run the host CPU proxy benchmark of v1 against v2:

```sh
cc -std=c11 -O2 -Wall -Wextra gpu/tests/bench_v1_v2.c -o bench_v1_v2
./bench_v1_v2
```

Compile the CUDA source to PTX, or assemble the PTX directly:

```sh
nvcc -arch=sm_70 -ptx gpu/malbolge_ternary.cu -o compiled.ptx
nvcc -arch=sm_70 -cubin gpu/malbolge_ternary.ptx -o malbolge_ternary.cubin
```

Check the CUDA device functions on the host, without a GPU:

```sh
cc -std=c11 -O2 -Wall -Wextra gpu/tests/verify_cuda_host.c -o verify_cuda_host
./verify_cuda_host
```

Compile a board to a SPICE deck, or to Verilog-A, a netlist, or KiCad:

```sh
awk -v mode=spice -f board/eda.awk board/examples/board.txt
awk -v mode=veriloga -f board/eda.awk board/examples/board-hybrid.txt > board.va
awk -v mode=netlist -f board/eda.awk board/examples/board.txt
awk -v mode=kicad -f board/eda.awk board/examples/board.txt > board.net
```

Solve a board directly, DC and transient, with no SPICE installed:

```sh
awk -f board/mna.awk board/examples/board.txt | column -t
```

Pipe a board into ngspice:

```sh
awk -v mode=spice -f board/eda.awk board/examples/board.txt | ngspice -b -
```

## Benchmarks

Measured 2026-11-21 on the host CPU, no GPU on that machine. The
v1-vs-v2 numbers are a host CPU proxy, not GPU timing. The
benchmark runs 20M pre-generated random valid-tryte calls per
operation, nanoseconds per call:

| Operation | v1 loop | v2 SWAR | Ratio |
| --------- | ------- | ------- | ----- |
| tryteAdd | 22.22 ns | 5.14 ns | 4.32x |
| tryteSub | 24.62 ns | 4.74 ns | 5.19x |
| crazyTryte | 16.96 ns | 4.22 ns | 4.02x |
| tryteToNat | 9.31 ns | 9.38 ns | 0.99x |

v2 `tryteToNat` is a loop, not SWAR, so it is not faster than v1;
the gain is in the SWAR operations. The roundtrip
`tryteToNat (natToTryte n) = n` holds for all 59049 values in v2
(0 failures) and fails for 58806 of 59049 in v1, which is preserved
as-is. The v1 host harness passes all its elementwise checks, and
the v2 host harness passes all checks.

Proof times on the same machine: the Malbolge SAW equivalence
proof with bitwuzla takes about six seconds; the WhyML proof
passes; the p4 proof gate passes with z3. The release gate passes
25 checks and is blocked only on CUDA compile and PTX assembly,
which need nvcc and ptxas.

## Engineering evidence

The requirements live in `requirements/`, the design in `architecture/`,
the verification record in `verification/`, the assurance record in
`assurance/`, the toolchain and baselines in `configuration/`, and the
release gate in `scripts/release-gate.sh`. The gate runs the tests that
can run on the machine it runs on and records the log in
`reports/test-results/`. If the gate fails, the tree is not pushed.

## License

SNAPKITTY OPAQUE SOURCE LICENSE v1.0. See `LICENSE`.
