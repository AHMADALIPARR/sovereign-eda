# Property Tests

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Tests that run here

- tests/test_core.py: crazy on all 9 trit pairs, rotation over all
  59049 values (10 rotations return to the start), 10000 random
  crazy-word samples. PASS 2026-11-21.
- tests/test_reference.sh: reference interpreter compiles and the
  NOP/HALT example produces empty output with exit code 0. PASS
  2026-11-21.
- gpu/tests/verify_cuda_host.c: v1 device functions against the Lean
  definitions, all 9 pairs per op, natToTryte over all 59049 values,
  decodeInstruction over all seven branches. PASS 2026-11-21.
- gpu/tests/verify_v2_host.c: v2 roundtrip over all 59049 values
  (0 failures), SWAR add/sub/crazy against the v1 loop ops bit for
  bit, v2 crazy/decrypt/permute against v1. PASS 2026-11-21. The
  same run measures v1 roundtrip failures at 58806 of 59049.
- Board compiler modes: spice, netlist, veriloga, kicad on the
  example boards, plus the MNA solver on the RC example. PASS
  2026-11-21. The MNA output lags the input as a low-pass filter
  requires.
- GHDL analyze in dependency order: Malbolge ALU, p4_controller,
  phase_calibrator, sram_bank, dual_circuit, sram_write_cell. PASS
  2026-11-21.
- GHDL testbench tb_p4_controller.vhd: reset, start, error steps,
  mode, lock, write-enable, and cal_word checks. PASS 2026-11-21.
  A deliberately wrong check was verified to fail with exit 1, so
  the testbench is not vacuous.
- GHDL testbench tb_sram_bank.vhd: write-through, read-back,
  address boundaries 0 and 255, unwritten locations read as zero,
  and a read cycle never writes. PASS 2026-11-21. A deliberately
  wrong expected value was verified to fail, so the testbench is
  not vacuous.
- GHDL testbench tb_dual_circuit.vhd: reset values, start to Run
  with aligned oscillators, the lock, the SRAM write allowed while
  locked and blocked while unlocked, and the calibration word
  stepping down once the oscillators are skewed. PASS 2026-11-21.
  A deliberately wrong check was verified to fail, so the
  testbench is not vacuous.
- SAW proof gate proof_gate.saw: run_implies_locked,
  sram_write_protected, write_read_match, all with z3. PASS
  2026-11-21.
- SRAM SAW proof write_cell_equivalence.saw: yosys_verify with w4
  against the Yosys netlist built by GHDL synthesis plus
  read_verilog. PASS 2026-11-21.
- Malbolge SAW proof alu_equivalence.saw: yosys_verify with
  bitwuzla against the Yosys netlist built by GHDL synthesis plus
  read_verilog. PASS 2026-11-21, about six seconds. A mutated spec
  (crazy + 1) fails with an unsolved subgoal, so the proof is not
  vacuous.

## Properties stated but not run here

- WhyML lemmas (init_inv, step_preserves_inv) in
  board/p4-dual-circuit/semantics/state.mlw: stated, not discharged
  here, because Why3 is not installed.
- Cryptol properties (run-implies-locked, write_read_match): stated
  in the .cry files, loaded but not executed as property checks here.
- PSL properties in board/p4-dual-circuit/verification/psl/
  dual_circuit.psl: stated, not run here, because no PSL runner is
  installed and no simulation testbench exists.
- Thermal sweep and PEX RC check: files present, no retained run
  result in this tree.

## Coverage

No line-coverage number is claimed. There are no safety-critical
components in this tree, so the 100% coverage rule for identified
safety-critical components in NASA-STD-8739.8B does not apply. The
exhaustive checks that do exist (all 59049 rotations, all 59049
roundtrip values, all 9 trit pairs) are stated with their counts in
the test files themselves.
