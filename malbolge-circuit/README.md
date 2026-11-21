# Malbolge Circuit Refinement — Phase 1

A real, small, bit-precise **10-trit ALU** for the original Malbolge machine.
WhyML supplies mathematical semantics; Cryptol describes the hardware port
contract; SAW+Yosys is configured to prove the VHDL module's equivalence.
No LLVM is involved.

## Delivered

- `semantics/MalbolgeCore.mlw`: WhyML definitions and proof obligations for
  tritwise crazy operation, rotation, word wrap, and position-sensitive decode.
- `rtl/malbolge_alu.vhd`: 16-bit encoded combinational 10-trit ALU.
- `cryptol/MalbolgeCore.cry`: exact encoded port contract.
- `saw/alu_equivalence.saw`: direct Yosys hardware verification invocation.
- `tests/test_core.py`: deterministic independent mathematical tests.
- `docs/SEMANTICS.md`: reference-interpreter machine-step semantics.

## Commands

```sh
make test       # Python used as a *test oracle*, never as circuit IR
make whyml      # needs Why3 with supported SMT provers
make analyze    # needs GHDL + Yosys GHDL plugin
make prove      # also needs SAW and w4 solver
```

## Important verification distinction

The test suite verifies mathematical invariants, but does not constitute a SAW
or Why3 discharge. The SAW script is a real target script which requires the
installed hardware toolchain. External hardware equivalence **has not been
claimed**. Phase 2 is the sequential machine with dual SRAM banks and
self-encrypting instruction fetch; Phase 3 adds Verilog-A/PEX timing contracts.

Scope of Phase 1: combinational ALU. The full Malbolge interpreter has a
reference-specific ambiguity for nonprintable instructions and initialization
with under two source instructions; these must be specified, not silently assumed.

## Original Malbolge interpreter (added)

`reference/malbolge.c` is the full Ben Olmstead 1998 public-domain C interpreter,
transcribed from the publicly hosted original source mirror
`https://github.com/TryItOnline/malbolge/blob/master/malbolge.c`.
It is **real executable interpreter source**, not a markdown reconstruction of behavior.
Its instruction decoding tables, self-modification, memory initialization,
C/D pointers, and nine-by-nine ternary table are included.

Build and smoke-test:

```sh
cc -std=c11 -O2 -Wall -Wextra reference/malbolge.c -o malbolge
./malbolge examples/nop_halt.mal
```

The 2-byte `DP` fixture is derived from the source decoder and performs
NOP followed by HALT. On this system the reference C source compiled with
one unused-variable warning and returned exit code 0 and empty stdout.

The original interpreter is the *reference executable*. The existing WhyML,
Cryptol, SAW and VHDL files are a **limited combinational ALU implementation**;
there is currently no claim that a complete CPU or dual-SRAM circuit exists.
The full-machine equivalence proof and Verilog-A extraction are still open.
