# Sovereign EDA

![License](https://img.shields.io/badge/license-SNAPKITTY%20Opaque%20Source%201.0-blue)
![C11](https://img.shields.io/badge/C-11-00599C)
![VHDL](https://img.shields.io/badge/VHDL-2008-1D3557)
![WhyML](https://img.shields.io/badge/WhyML-Why3-6A1B9A)
![Cryptol](https://img.shields.io/badge/Cryptol-3.0-0B6E8F)

Sovereign EDA is an electronic design automation workspace built on ternary
machines. Its first project is a real, bit-precise 10-trit ALU for the
original Malbolge machine, with the reference interpreter, the hardware
description, the mathematical semantics, and the verification scripts in
one tree.

## The machine

Malbolge is a ternary virtual machine. A machine word is ten trits wide,
0 to 59048. Memory holds 59049 words. Three registers: `a` the
accumulator, `c` the code pointer, `d` the data pointer. Code and data
share the same memory space.

The machine's arithmetic is the crazy operation, a tritwise lookup:

| [D] \ A | 0 | 1 | 2 |
| ------- | - | - | - |
| 0       | 1 | 0 | 0 |
| 1       | 1 | 0 | 2 |
| 2       | 2 | 2 | 1 |

The Lean formalization and the GPU kernels use the owner's own crazy
table, which differs from the standard table in rows 1 and 2:

| a \ b | 0 | 1 | 2 |
| ----- | - | - | - |
| 0     | 1 | 0 | 0 |
| 1     | 2 | 2 | 1 |
| 2     | 0 | 2 | 2 |

The two tables live in different layers: the circuit and the reference
interpreter run the original Malbolge table, the Lean and GPU layers
run the owner's variant. Each tryte is packed as a 20-bit `uint32_t`,
10 trits at 2 bits per trit, 00 = Zero, 01 = One, 10 = Two.

The other operations are tritwise rotate right by one trit, the
position-sensitive decode `(c + mem[c]) mod 94`, and the self-modifying
encipherment: after a non-halting instruction runs, the word at the code
pointer is replaced through a 94-character permutation. A program rewrites
itself as it runs.

## Layout

| Path | Contents |
| ---- | -------- |
| `malbolge-circuit/` | Phase 1: the Malbolge circuit project |
| `malbolge-circuit/reference/` | The full Ben Olmstead 1998 public-domain C interpreter, the reference executable |
| `malbolge-circuit/rtl/` | `malbolge_alu.vhd`: 16-bit encoded combinational 10-trit ALU |
| `malbolge-circuit/semantics/` | `MalbolgeCore.mlw`: WhyML definitions and proof obligations |
| `malbolge-circuit/cryptol/` | `MalbolgeCore.cry`: exact encoded port contract |
| `malbolge-circuit/saw/` | `alu_equivalence.saw`: Yosys hardware verification invocation |
| `malbolge-circuit/tests/` | `test_core.py`: deterministic independent mathematical tests; `test_reference.sh`: interpreter smoke test |
| `malbolge-circuit/docs/` | `SEMANTICS.md`: reference-interpreter machine-step semantics |
| `malbolge-circuit/examples/` | `nop_halt.mal`: NOP followed by HALT fixture |
| `lean/` | `MalbolgeProcessorRoot.lean`: the owner's Malbolge processor formalization; `MalbolgePTXKernel.lean`: the PTX kernel specification |
| `gpu/` | `malbolge_ternary.cu`: CUDA kernels for the ternary tryte operations and the deterministic Malbolge processor step; `malbolge_ternary.ptx`: the PTX assembly kernel for the same operations |
| `gpu/tests/` | `verify_cuda_host.c`: host-side C verification of the CUDA device functions against the Lean definitions, no GPU needed |
| `STATUS.md` | Verification record: what was run, what passed, what needs the hardware toolchain |

`malbolge-circuit/README.md` documents the circuit project itself,
including the Phase 1 scope and the reference-interpreter notes.

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

The WhyML proof and the SAW/Yosys equivalence proof need their
toolchains; see `malbolge-circuit/Makefile` targets `whyml`,
`analyze`, and `prove`.

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
