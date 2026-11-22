# Release Readiness — 2026-11-21

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Gate log: reports/test-results/gate-2026-11-21.log

## Verdict

GATE FAIL. This tree must NOT be pushed and no baseline is declared.

Checks passed: 25. Checks failed or blocked: 3.

## Release-readiness checklist (from the NASA-grade list)

0. Requirements: 1 of 1 — requirements exist, owned, traced. DONE.
1. Build: 0 of 1 — builds that run here pass, but CUDA and PTX builds do not run here. NOT DONE.
2. Static analysis: 0 of 1 — compiler, GHDL, Cryptol, and Lean checks run; no dedicated static-analysis tool runs. NOT DONE.
3. Testing: 0 of 1 — unit, oracle, host-harness, and testbench tests pass, including the controller, the SRAM bank, the structural top, and the write-cell; GPU hardware runs do not exist here. NOT DONE.
4. Formal checks: 1 of 1 — WhyML, SAW ALU, SRAM SAW, Lean v2, Cryptol loads, and the p4 proof gate pass. DONE.
5. Traceability: 1 of 1 — every requirement ID has a row, verified by the gate. DONE.
6. Safety: 1 of 1 — hazards, FMEA, and safety requirements exist for this non-safety-critical class. DONE.
7. Configuration: 1 of 1 — toolchain, build manifest, and watermark are recorded. DONE.
8. Review: 0 of 1 — owner review recorded; no independent review done. NOT DONE.
9. Release approval: 0 of 1 — no release approval exists. NOT DONE.

Score: 5 of 10.

## Blockers (gate FAIL items)

- BLOCKED: CUDA compile (SW-103) -- nvcc not installed on this VM
- BLOCKED: PTX assembly (SW-102) -- ptxas not installed on this VM
- FAIL: .gitignore hash mismatch in WATERMARK.md
- FAIL: README.md hash mismatch in WATERMARK.md
- FAIL: STATUS.md hash mismatch in WATERMARK.md
- FAIL: architecture/failure-modes/FMEA.md hash mismatch in WATERMARK.md
- FAIL: assurance/defects/defect-log.md hash mismatch in WATERMARK.md
- FAIL: board/p4-dual-circuit/cryptol/CircuitContract.cry is tracked but not listed in WATERMARK.md
- FAIL: board/p4-dual-circuit/cryptol/SRAM.cry is tracked but not listed in WATERMARK.md
- FAIL: board/p4-dual-circuit/cryptol/State.cry is tracked but not listed in WATERMARK.md
- FAIL: board/p4-dual-circuit/saw/digital_equivalence.saw hash mismatch in WATERMARK.md
- FAIL: board/p4-dual-circuit/saw/sram_refinement.saw hash mismatch in WATERMARK.md
- FAIL: board/sram-write-cell/sram.cry hash mismatch in WATERMARK.md
- FAIL: board/sram-write-cell/write_cell_equivalence.saw hash mismatch in WATERMARK.md
- FAIL: configuration/toolchain-locks/toolchain.md hash mismatch in WATERMARK.md
- FAIL: malbolge-circuit/Makefile hash mismatch in WATERMARK.md
- FAIL: malbolge-circuit/saw/alu_equivalence.saw hash mismatch in WATERMARK.md
- FAIL: reports/release-readiness/release-readiness.md hash mismatch in WATERMARK.md
- FAIL: requirements/software/REQ-SW.md hash mismatch in WATERMARK.md
- FAIL: requirements/traceability.csv hash mismatch in WATERMARK.md
- FAIL: scripts/release-gate.sh hash mismatch in WATERMARK.md
- FAIL: tests/README.md hash mismatch in WATERMARK.md
- FAIL: verification/formal/formal-evidence.md hash mismatch in WATERMARK.md
- FAIL: verification/property-tests/property-tests.md hash mismatch in WATERMARK.md
- Watermark mismatch: run python3 ~/workspace/.tools/rechain.py <repo> 'Sovereign EDA' and commit before pushing.

## Known defects still open

See assurance/defects/defect-log.md (D-001 through D-016).
D-001 (v1 tryteToNat) is open by design, per ADR-002.

## What closes the gate

- Run the WhyML proof and the SAW proofs until they pass, on this machine or a bigger one (see gate log).
- Compile with nvcc and assemble with ptxas on a machine that has them; run the kernels on the Jetson for timing.
- Record a release approval with the commit hash, the gate log, and the approver.
