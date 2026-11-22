# Interface Control

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Reference interpreter

- Input: a Malbolge program file path on the command line. Stdin is
  the machine input. Output: machine output on stdout.
- File: malbolge-circuit/reference/malbolge.c.
- Instruction encoding: decode `(C + mem[C]) mod 94`. Values 4, 5, 23,
  39, 40, 62, 68, 81 are the defined instructions; other values are
  NOP. See malbolge-circuit/docs/SEMANTICS.md.

## Board compiler

- Input: a board file, one component or directive per line,
  whitespace-delimited, `#` or `*` comments. Ground is net `0`.
- Mode select: `-v mode=spice` (default), `veriloga`, `netlist`,
  `kicad`.
- Output: the selected form on stdout. ERC warnings go to stderr.
- File: board/eda.awk. Examples: board/examples/board.txt,
  board/examples/board-hybrid.txt.

## MNA solver

- Input: a board file. Output: time-series node voltages on stdout,
  columns time, v(in), v(out), and further nodes as present.
- File: board/mna.awk.

## p4_controller VHDL entity

- Ports: clk in, rst_n in, start in, phase_err in signed(7 downto 0),
  cal_word out unsigned(7 downto 0), mode_out out std_logic_vector
  (1 downto 0), locked out, sram_we_en out.
- Mode encoding: 00 Idle, 01 Calibrate, 10 Run, 11 Fault.
- File: board/p4-dual-circuit/rtl/p4_controller.vhd.

## Malbolge ALU VHDL entity

- 16-bit encoded combinational 10-trit ALU: crazy, rotate, valid.
- File: malbolge-circuit/rtl/malbolge_alu.vhd.

## GPU kernels

- Tryte encoding: packed uint32_t, 20 bits, 10 trits at 2 bits per
  trit, 00 = Zero, 01 = One, 10 = Two. Value 3 in a trit slot is
  out of domain.
- V1 and v2 use different tryteToNat folding. V1 is not the inverse of
  natToTryte. V2 is. The two versions are not interchangeable.
- Files: gpu/malbolge_ternary.cu, gpu/malbolge_ternary.ptx,
  gpu/malbolge_ternary_v2.cu, gpu/malbolge_ternary_v2.ptx.

## Lean v2 layer

- tryteToNat reads slot i as the 3^i digit. natToTryte writes digit i
  as `(n / 3^i) mod 3`. Roundtrip holds for all 59049 values.
- File: lean/MalbolgeTryteV2.lean.
