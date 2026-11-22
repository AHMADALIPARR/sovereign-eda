# Formal Verification Evidence

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## What each tool proves, and what it does not

- WhyML (Why3 + Z3) proves the verification conditions in
  malbolge-circuit/semantics/MalbolgeCore.mlw: crazy_trit, rotate,
  decode, inc, crazy10. It proves the mathematics of those functions.
  It does not prove transistor behavior, timing, or the full machine.
- Cryptol typechecks the executable contracts. Loading a .cry file
  proves it parses and typechecks. It does not prove the contract
  matches the VHDL.
- SAW proves the synthesized ALU equivalent to the Cryptol contract,
  given a Yosys netlist. It does not prove the full machine, and it
  does not run without that netlist.
- Lean proves what its files state. MalbolgeTryteV2.lean proves the
  base-3 digit-reconstruction lemma behind the roundtrip. The general
  roundtrip theorem is deliberately not in the file, and the roundtrip
  is verified by execution over all 59049 values instead.
- A WhyML proof does not establish transistor behavior under
  manufacturing variation. An RTL equivalence result does not replace
  analog parasitic extraction or timing validation.

## Results on this VM, 2026-11-21

- WhyML: PASS. Why3 1.6.0 is installed at /usr/bin/why3 (it was
  absent at the first gate run on 2026-11-21 and present later the
  same day). `why3 prove semantics/MalbolgeCore.mlw` passes, all
  five verification conditions discharged Valid.
- SAW (Malbolge ALU): PASS with bitwuzla, in about six seconds.
  The w4 run (What4 + z3) was killed after 10+ minutes with no
  verdict, the second run to fail that way on this VM; z3 sat at 99%
  CPU on the 16-bit division-heavy equivalence (crazyWord does 10
  steps of div/mod by 3, rotateWord divides by 3). The abc run was
  killed (exit 137) about five minutes in, with swap in use. The
  script now uses bitwuzla, the maintained successor of Boolector
  (which also proves it in six seconds but is deprecated in SAW
  1.5). Verified non-vacuous: a copy of the tree in /tmp with the
  spec mutated (crazy + 1) fails with one unsolved subgoal and a
  counterexample, exit 2. The regenerated netlist has 0 $pmux
  cells, 63 $mux. A VM swap at ~17:23 wiped Yosys, Why3, GHDL, and
  /usr/bin/z3 and killed the first abc run; all three tools were
  reinstalled from the Ubuntu pool as .debs kept in
  ~/workspace/.tools/debs/, but Ubuntu does not ship the Yosys GHDL
  plugin, so the netlist path is GHDL synthesis to Verilog plus
  Yosys read_verilog, in the Makefiles. SAW needs z3 on PATH; the
  Makefiles put the SAW bundle bin dir first, since the bundle
  ships its own z3.
- SAW (SRAM write-cell): PASS, end to end. GHDL, Yosys 0.33, and SAW
  1.5 all ran on this VM: `make prove` generates
  build/sram_write_cell.json (one $mux) and yosys_verify with w4
  passes, exit 0. The script called writeCellCircuit, which the
  Cryptol file now defines as the record wrapper around writeCell
  (enable is [1], not Bit, matching the port type the way aluSpec
  uses valid : [1]).
- SAW (p4 proof gate): PASS. `saw saw/proof_gate.saw` proves all
  three Cryptol properties with z3 and prints ALL PROOF GATES PASSED:
  State.run_implies_locked, CircuitContract.sram_write_protected,
  SRAM.write_read_match. Getting there required fixing the Cryptol
  files: where-clause indentation in State.cry and SRAM.cry, an
  explicit parenthesis in the `&&` condition in State.cry, the bare
  `Word` ambiguity in CircuitContract.cry, and renaming the files to
  match their module names (State.cry, SRAM.cry,
  CircuitContract.cry), because Cryptol resolves `import SRAM` to a
  file named SRAM.cry. The SAW scripts now reference the properties
  by plain name, not Module::name, which SAW does not resolve.
- SAW (p4 RTL): NOT POSSIBLE with this toolchain. yosys_import models
  each module as a combinational function from input ports to output
  ports (SAW manual ch. 6). A minimal $dff probe netlist is rejected
  at import as an undetected cycle, so the clocked p4_controller
  cannot be yosys_verified against step_state. The RTL check is the
  GHDL testbench verification/tb_p4_controller.vhd, which passes.
  See defect D-015.
- Cryptol: PASS (load). Cryptol 3.5.0 loads
  malbolge-circuit/cryptol/MalbolgeCore.cry,
  board/p4-dual-circuit/cryptol/State.cry,
  board/p4-dual-circuit/cryptol/SRAM.cry,
  board/p4-dual-circuit/cryptol/CircuitContract.cry, and
  board/sram-write-cell/sram.cry with no error. The gate runs all
  five loads.
- Lean v2: PASS. Lean 4.12.0 (elan) checks
  lean/MalbolgeTryteV2.lean with exit code 0.
- Lean ProcessorRoot: does NOT elaborate under core-only Lean 4.12.0
  on this VM (unknown constant, type mismatch, termination failure).
  It needs Batteries and Mathlib, which are not built here. That
  proves nothing about the file in the owner's full environment.
  See defect D-007.
- Lean Processor (photo reproduction): not re-checked in this run.
  Per STATUS.md it needs Batteries and Mathlib and cannot be fully
  checked on this VM.

## Proof obligations

| Obligation | Tool | Status on this VM |
| --- | --- | --- |
| crazy_trit, rotate, decode, inc, crazy10 | Why3 + Z3 | PASS |
| ALU equivalence to Cryptol | SAW + Yosys netlist | PASS with bitwuzla, ~6 s; non-vacuous (mutated spec fails) |
| SRAM write-cell equivalence to Cryptol | SAW + Yosys netlist | PASS, end to end (GHDL → Yosys → SAW) |
| run_implies_locked, sram_write_protected, write_read_match | SAW proof gate + z3 | PASS |
| sum_digits_mod digit reconstruction | Lean 4.12.0 | PASS |
| Roundtrip tryteToNat (natToTryte n) = n, all 59049 | Host execution | PASS (v2), measured 58806 failures in v1 |
| run-implies-locked, write-enable condition | WhyML / Cryptol / PSL + GHDL testbench | Cryptol PASS; testbench PASS; WhyML proof BLOCKED here; PSL stated, not run |
