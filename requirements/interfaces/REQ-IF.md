# Interface Requirements

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Owner: Ahmad Ali Parr. Trace: requirements/traceability.csv.
Full interface control: architecture/interface-control/ICD.md.

- IF-001: The reference interpreter takes a Malbolge program file on
  the command line, reads input on stdin, and writes output on stdout.
  Acceptance: tests/test_reference.sh.
- IF-002: The board compiler takes a board file and a mode
  (spice, veriloga, netlist, kicad) and writes the selected output on
  stdout. Acceptance: all four modes run on board/examples/board.txt.
- IF-003: The MNA solver takes a board file on stdin and writes
  time-series node voltages on stdout. Acceptance: board/mna.awk runs
  the RC example.
- IF-004: The p4_controller VHDL entity exposes clk, rst_n, start,
  phase_err (signed 8), cal_word (unsigned 8), mode_out (2 bits),
  locked, and sram_we_en. Acceptance: GHDL analyzes the entity.
- IF-005: The Malbolge ALU VHDL entity exposes a 16-bit encoded input
  and the crazy, rotate, and valid outputs defined in
  malbolge-circuit/rtl/malbolge_alu.vhd. Acceptance: GHDL analyzes
  the entity.
- IF-006: The GPU kernels take packed 20-bit trytes (uint32_t, 2 bits
  per trit) and return packed trytes in the same encoding.
  Acceptance: the host harnesses use that encoding on both sides.
- IF-007: The Lean v2 layer and the v2 GPU kernels use the same
  tryteToNat: slot i is the 3^i digit. The v1 layers use the v1
  folding, which is not the inverse of natToTryte. The two are not
  interchangeable across versions. Acceptance: verify_v2_host.c
  measures both.
