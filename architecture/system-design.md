# System Design

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Scope

Sovereign EDA holds two projects in one tree. The first is Malbolge, a
ternary virtual machine. The second is a plain-text board EDA compiler
with a dual-circuit controller and an SRAM write-cell. Classification:
non-flight research / engineering tool, non-safety-critical. See
requirements/classification.md.

## Layout decision

The existing layout is preserved. The Malbolge circuit stays in
malbolge-circuit/, the board stays in board/, the Lean formalization
stays in lean/, and the GPU kernels stay in gpu/. The NASA evidence
layer in this commit (requirements/, architecture/, verification/,
tests/, assurance/, configuration/, operations/, reports/) references
those paths. It does not move them. See
architecture/decisions/ADR-001-layout-preserved.md.

## Malbolge components

| Component | Path | Role |
| --- | --- | --- |
| Reference interpreter | malbolge-circuit/reference/malbolge.c | Ben Olmstead 1998 public-domain C, full machine executable |
| ALU | malbolge-circuit/rtl/malbolge_alu.vhd | 16-bit encoded combinational 10-trit ALU: crazy, rotate, valid |
| Semantics | malbolge-circuit/semantics/MalbolgeCore.mlw | WhyML definitions and proof obligations |
| Contract | malbolge-circuit/cryptol/MalbolgeCore.cry | Cryptol port contract |
| Equivalence | malbolge-circuit/saw/alu_equivalence.saw | SAW check of synthesized ALU against the Cryptol contract |
| Formalization | lean/MalbolgeProcessorRoot.lean, lean/MalbolgeProcessor.lean, lean/MalbolgePTXKernel.lean, lean/MalbolgeTryteV2.lean | Lean 4 processor, PTX kernel specification, v2 tryte layer |
| GPU | gpu/malbolge_ternary.cu, gpu/malbolge_ternary.ptx, gpu/malbolge_ternary_v2.cu, gpu/malbolge_ternary_v2.ptx | CUDA and PTX kernels, sm_70, one 59049-tryte VM per thread |
| Tests | malbolge-circuit/tests/, gpu/tests/ | Python oracle, reference smoke test, host-side C harnesses, CPU proxy benchmark |

Machine facts: 59049 ten-trit words, unified instruction/data memory,
registers A, C, D. Decode is `(C + mem[C]) mod 94`. After a non-halting
step the word at C is encrypted through the 94-character permutation
and C and D increment mod 59049. The full semantics are in
malbolge-circuit/docs/SEMANTICS.md.

## Board components

| Component | Path | Role |
| --- | --- | --- |
| Compiler | board/eda.awk | POSIX awk, SPICE / Verilog-A / netlist / KiCad modes |
| First version | board/eda-basic.awk | First compiler version, SPICE / netlist |
| Solver | board/mna.awk | Pure-awk MNA solver, DC and transient, nonlinear diodes by Newton-Raphson |
| Examples | board/examples/board.txt, board/examples/board-hybrid.txt | RC low-pass + diode clipper; RC filter + behavioral memristive load |
| Dual circuit | board/p4-dual-circuit/ | WhyML semantics, Cryptol contracts, SAW proof gates, VHDL RTL, Verilog-A analog, PSL / PEX / thermal verification |
| SRAM write-cell | board/sram-write-cell/ | WhyML semantics, Cryptol contract, SAW equivalence, VHDL RTL |

## Dependencies

- Build and test on this VM need: cc, python3, GHDL, awk. Measured
  versions are in configuration/toolchain-locks/toolchain.md.
- WhyML proof needs Why3 and Z3. SAW proof needs Yosys with the GHDL
  plugin. Neither Why3 nor Yosys is installed on this VM on
  2026-11-21, so those two proofs are BLOCKED here. See defects D-002
  and D-003.
- CUDA compile needs nvcc. PTX assembly needs ptxas. Neither is
  installed on this VM, so those two checks are NOT RUN here. See
  defects D-004 and D-005.
- Lean v2 checks with the elan Lean 4.12.0 on this VM. The Lean
  ProcessorRoot file needs Batteries and Mathlib, which are not built
  here, and does not elaborate under core-only Lean 4.12.0 on this VM.
  See defect D-007.

## Assumptions

- The reference interpreter's I/O decoding (5 outputs, 23 inputs) is
  adopted over the reversed prose specification. See
  malbolge-circuit/docs/SEMANTICS.md.
- The two crazy tables (standard in the interpreter and circuit,
  owner's variant in Lean and GPU) are intentional and distinct. See
  architecture/decisions/ADR-003-two-crazy-tables.md.
- V1 behavior is preserved as-is. V2 is a separate benchmark variant.
  See architecture/decisions/ADR-002-v1-untouched.md.
- Host-side C harnesses verify the GPU device functions. They do not
  verify GPU execution, timing, or PTX assembly. See
  architecture/decisions/ADR-004-host-harness-not-gpu.md.
