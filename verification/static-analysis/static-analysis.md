# Static Analysis

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

No dedicated static-analysis tool (for example, a linter, a MISRA
checker, or a security scanner) is run in this tree. The checks below
are the static checks that actually run here, and their results are
recorded as such.

## Checks run

- C compiler diagnostics: `cc -std=c11 -O2 -Wall -Wextra` on the
  reference interpreter and on the GPU host harnesses. Result
  2026-11-21: the interpreter compiles with one warning, unused
  variable `j` in `main` (malbolge.c line 43). The harnesses compile
  with no warning shown.
- GHDL analysis: `ghdl -a --std=08` on the Malbolge ALU and on the
  board VHDL in dependency order. Result 2026-11-21: all files
  analyze with exit code 0. The structural top dual_circuit.vhd
  fails when analyzed alone, because its sub-entities have not been
  analyzed yet in that library; it passes in dependency order.
- Cryptol load: typechecks the Cryptol contracts. Result 2026-11-21:
  MalbolgeCore and the SRAM cell load with no error.
- Lean check: the Lean kernel typechecks MalbolgeTryteV2.lean.
  Result 2026-11-21: exit code 0 under Lean 4.12.0.
- ERC: the board compiler flags floating nets (degree 1, excluding
  ground) to stderr. The SIN source value in board.txt has spaces,
  so ERC flags `sin(0` and `5` as floating nets. That is the board
  as written.

## Not run

- No Yosys synthesis check (Yosys not installed), no Why3 proof
  (Why3 not installed), no nvcc/ptxas check, no PSL run, no board
  RTL simulation. Each is recorded as BLOCKED or NOT RUN in
  assurance/defects/defect-log.md, never as passed.
