# Tests

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Tests live with the code they cover. This file is the index, not a
second copy. The release gate runs every test below that can run on
this VM and records the log in reports/test-results/.

## Malbolge circuit

| Test | Command | Result 2026-11-21 |
| --- | --- | --- |
| Python oracle | python3 malbolge-circuit/tests/test_core.py | PASS |
| Reference smoke | sh malbolge-circuit/tests/test_reference.sh | PASS, one unused-variable warning for j |
| GHDL ALU | ghdl -a --std=08 malbolge-circuit/rtl/malbolge_alu.vhd | PASS, exit 0 |
| WhyML proof | why3 prove malbolge-circuit/semantics/MalbolgeCore.mlw | BLOCKED, Why3 not installed |
| SAW proof | make prove in malbolge-circuit/ | BLOCKED, Yosys not installed |

## GPU kernels

| Test | Command | Result 2026-11-21 |
| --- | --- | --- |
| V1 host harness | cc gpu/tests/verify_cuda_host.c, run it | PASS |
| V2 host harness | cc gpu/tests/verify_v2_host.c, run it | PASS, v2 roundtrip 0/59049, v1 58806/59049 |
| CPU proxy benchmark | cc gpu/tests/bench_v1_v2.c, run it | PASS, ratios 3.30x / 4.14x / 4.01x / 1.55x |
| nvcc compile | nvcc -arch=sm_70 | NOT RUN, no CUDA toolchain |
| ptxas assembly | ptxas gpu/malbolge_ternary.ptx | NOT RUN, no ptxas |

## Board

| Test | Command | Result 2026-11-21 |
| --- | --- | --- |
| Compiler modes | awk -v mode=spice/netlist/veriloga/kicad -f board/eda.awk board/examples/board.txt | PASS |
| MNA solver | awk -f board/mna.awk board/examples/board.txt | PASS |
| GHDL board VHDL | ghdl -a --std=08 in dependency order | PASS |
| GHDL p4_controller testbench | make test in board/p4-dual-circuit/ | PASS, TESTBENCH PASS, exit 0 |
| GHDL sram_bank testbench | make test in board/p4-dual-circuit/ | PASS, TESTBENCH PASS, exit 0 |
| GHDL dual_circuit testbench | make test in board/p4-dual-circuit/ | PASS, TESTBENCH PASS, exit 0 |
| GHDL sram_write_cell testbench | make test in board/sram-write-cell/ | PASS, TESTBENCH PASS, exit 0 |
| p4 SAW proof gate | saw saw/proof_gate.saw in board/p4-dual-circuit/saw/ | PASS, ALL PROOF GATES PASSED |
| SRAM SAW proof | make prove in board/sram-write-cell/ | PASS, end to end (GHDL synth → Yosys → SAW) |
| Malbolge SAW proof | make prove in malbolge-circuit/ | PASS with bitwuzla, ~6 s |
| PSL run | none | NOT RUN, no runner |

## Lean

| Test | Command | Result 2026-11-21 |
| --- | --- | --- |
| V2 tryte layer | lean lean/MalbolgeTryteV2.lean (Lean 4.12.0) | PASS, exit 0 |
| ProcessorRoot | lean lean/MalbolgeProcessorRoot.lean | Does not elaborate under core-only Lean 4.12.0, needs Batteries/Mathlib |
| Processor (photo reproduction) | lean lean/MalbolgeProcessor.lean | Not re-checked here, needs Batteries/Mathlib |

## Gate

scripts/release-gate.sh runs the runnable rows above, checks
traceability coverage, recomputes the watermark, and exits non-zero
if any required check fails or is blocked. The gate log is the test
report. See reports/release-readiness/release-readiness.md.
