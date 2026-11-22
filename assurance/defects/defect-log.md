# Defect Log

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Open defects are facts, not judgments. Each has an ID used by the
traceability file, the FMEA, and the release-readiness report.

| ID | Defect | Found | Status |
| --- | --- | --- | --- |
| D-001 | V1 tryteToNat is not the inverse of natToTryte. Measured 58806 failures of 59049 in the v2 harness run 2026-11-21. | 2026-11-21 | Open by design. V1 is preserved as-is per ADR-002. V2 is the fixed variant. |
| D-002 | WhyML proof cannot run on this VM. Why3 is not installed. Last recorded pass was 2026-11-21 with Why3 1.6.0 and Z3 4.8.12, all five conditions Valid, but that result is not re-verified in this run. | 2026-11-21 | Closed 2026-11-21. Why3 1.6.0 is installed at /usr/bin/why3 and `why3 prove semantics/MalbolgeCore.mlw` passes. |
| D-003 | SAW proof cannot run on this VM. Yosys is not installed, so no netlist is produced for SAW to check. Last recorded attempt started the proof but did not finish in 10 minutes. | 2026-11-21 | Closed 2026-11-21. Yosys 0.33 reinstalled from the Ubuntu pool; the netlist path is GHDL synthesis plus Yosys read_verilog (no GHDL plugin in Ubuntu). The Malbolge ALU proof passes with bitwuzla in ~6 s; the SRAM write-cell proof passes end-to-end. |
| D-004 | CUDA never compiled here. No CUDA toolchain is installed. Host harnesses cover the device functions only. | 2026-11-21 | Open. Blocks SW-103. |
| D-005 | PTX never assembled here. No ptxas is installed. | 2026-11-21 | Open. Blocks SW-102. |
| D-006 | Board RTL simulation: the SRAM bank and the structural dual_circuit top have no testbench. | 2026-11-21 | Closed 2026-11-21. Testbenches now exist and pass for p4_controller, sram_bank, dual_circuit, and sram_write_cell; all four were verified non-vacuous with deliberately wrong checks. |
| D-007 | Lean ProcessorRoot does not elaborate under core-only Lean 4.12.0 on this VM (unknown constant, type mismatch, termination failure). It needs Batteries and Mathlib, which are not built here. | 2026-11-21 | Open. The file is verbatim owner code; it is not edited from this VM's errors. |
| D-008 | Thermal sweep (thermal_sweep.sp) has no retained run result in this tree. | 2026-11-21 | Open. |
| D-009 | PEX RC check (pex_rc_check.awk) has no retained run result in this tree. | 2026-11-21 | Open. |
| D-010 | Reference interpreter compiles with one warning: unused variable j in main (malbolge.c line 43). | 2026-11-21 | Open, minor. The file is Ben Olmstead's public-domain code and is not edited. |
| D-011 | Board ERC flags sin(0 and 5 as floating nets in board.txt, because the V1 SIN source value has spaces. That is the board as written. | 2026-11-21 | Open, minor. Recorded in STATUS.md. |
| D-012 | SAW proof is slow on this VM (did not finish in 10 minutes when last attempted). Even with Yosys restored, it needs a bigger machine or a longer run. | 2026-11-21 | Closed 2026-11-21. The w4 and abc attempts failed (grind, then OOM kill), but bitwuzla proves the ALU equivalence in ~6 s on this VM. |
| D-013 | Fault model difference: the WhyML step enters Fault on out-of-range integer error; the Cryptol step_state and the VHDL controller have no Fault entry. The VHDL phase_err port is signed 8 bits, so it cannot present an out-of-range error, and the RTL never assigns MODE_FAULT. run_implies_locked holds in all three layers. Which model is authoritative is the owner's call. | 2026-11-21 | Open. Not fixed by this work; the RTL and the specs are the owner's code and are not rewritten on this finding alone. |
| D-014 | p4 Cryptol files did not load: where-clause indentation errors in State.cry and SRAM.cry, an `&&` precedence error in State.cry, a bare `Word` ambiguity in CircuitContract.cry, lowercase filenames that do not match the module names (Cryptol resolves `import SRAM` to SRAM.cry), and Module::name references in the SAW scripts that SAW does not resolve. | 2026-11-21 | Closed 2026-11-21. Fixed by whitespace, one parenthesis, spelling the data type as [32], renaming the files to State.cry / SRAM.cry / CircuitContract.cry, and using plain property names in the SAW scripts. The proof gate now passes. |
| D-015 | SAW yosys_import rejects sequential ($dff) netlists: a minimal $dff probe fails at import as an undetected cycle, and the manual models modules as combinational input-to-output functions. The clocked p4_controller cannot be yosys_verified against step_state with this toolchain. The RTL check is the GHDL testbench. | 2026-11-21 | Open by toolchain limitation. |
| D-016 | Malbolge netlist held 20 $pmux cells, which the SAW manual says SAW does not support. `pmuxtree` was added to the Makefile analyze target. | 2026-11-21 | Closed 2026-11-21. Yosys 0.33 regenerated the netlist with `pmuxtree` in the pass list: 0 $pmux cells, 63 $mux. |
