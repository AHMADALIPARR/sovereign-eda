# Sovereign EDA

## Malbolge, Ternary Machines, and the Hardware That Runs Them

![License](https://img.shields.io/badge/license-SNAPKITTY%20Opaque%20Source%201.0-blue)
![C11](https://img.shields.io/badge/C-11-00599C)
![VHDL](https://img.shields.io/badge/VHDL-2008-1D3557)
![WhyML](https://img.shields.io/badge/WhyML-Why3-6A1B9A)
![Cryptol](https://img.shields.io/badge/Cryptol-3.0-0B6E8F)
![CUDA](https://img.shields.io/badge/CUDA-sm__70-76B900)
![Lean](https://img.shields.io/badge/Lean-4-4A90D9)

Sovereign EDA is an electronic design automation workspace built on ternary machines. Its first project is Malbolge, the ternary virtual machine, carried from the reference interpreter through a bit-precise hardware ALU, a formal semantics, and a GPU execution engine, in one tree. A machine word is ten trits wide. Memory holds 59049 words. Code and data share the same memory, and a program rewrites itself as it runs.

The repository is the machine and its evidence in one place. The reference interpreter runs the machine. The VHDL ALU computes the same operations in hardware. The WhyML and Cryptol layers state the same operations as contracts. The Lean formalization states the processor, its invariants, and its determinism. The CUDA and PTX kernels run the same operations on the GPU, one Malbolge virtual machine per thread. The chain is:

$$\text{Interpreter} \;\to\; \text{ALU} \;\to\; \text{Contracts} \;\to\; \text{Formalization} \;\to\; \text{GPU}$$

with each layer agreeing with the others on the same trit operations, the same tryte encoding, and the same step semantics.

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
| Implementation languages | C11, VHDL-2008, WhyML, Cryptol, Lean 4, CUDA C++, PTX |
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

## Layout

| Path | Contents |
| ---- | -------- |
| `malbolge-circuit/` | The Malbolge circuit project: reference interpreter, VHDL ALU, WhyML, Cryptol, SAW, tests, docs, examples |
| `lean/` | `MalbolgeProcessorRoot.lean`: the Malbolge processor formalization; `MalbolgePTXKernel.lean`: the PTX kernel specification |
| `gpu/` | `malbolge_ternary.cu`: CUDA kernels for the ternary tryte operations and the deterministic Malbolge processor step; `malbolge_ternary.ptx`: the PTX assembly kernel for the same operations |
| `gpu/tests/` | `verify_cuda_host.c`: host-side C verification of the CUDA device functions against the Lean definitions, no GPU needed |
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

Analyze the VHDL:

```sh
cd malbolge-circuit && ghdl -a --std=08 rtl/malbolge_alu.vhd
```

The WhyML proof and the SAW/Yosys equivalence proof need their toolchains; see `malbolge-circuit/Makefile` targets `whyml`, `analyze`, and `prove`.

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

## License

SNAPKITTY OPAQUE SOURCE LICENSE v1.0. See `LICENSE`.
