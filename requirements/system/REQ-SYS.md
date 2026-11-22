# System Requirements

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Owner: Ahmad Ali Parr. Each requirement has an ID, an acceptance
criterion, and a trace entry in requirements/traceability.csv. A
requirement with no trace entry fails the release gate.

## Malbolge machine

- SYS-001: The machine has 59049 ten-trit words of unified instruction
  and data memory. Acceptance: the reference interpreter and the test
  oracle both use 59049 as the memory size.
- SYS-002: Registers are A (accumulator), C (code pointer), and D (data
  pointer), each a value below 59049. Acceptance: the interpreter and
  the semantics state all three registers with that bound.
- SYS-003: A step decodes `(C + mem[C]) mod 94`, executes the decoded
  instruction, encrypts the word at C through the 94-character
  permutation, and increments C and D mod 59049. Acceptance: the
  reference interpreter implements this order, and the semantics
  document states it.
- SYS-004: The crazy operation is the tritwise lookup over the
  accumulator trit and the data trit. The reference interpreter and the
  circuit use the standard Malbolge table. The Lean and GPU layers use
  the owner's variant table. The two tables are different and are not
  interchangeable. Acceptance: each layer states which table it uses,
  and the host harnesses check the layer they cover against its own
  table.
- SYS-005: A tryte is 10 trits. In the GPU layers a tryte is a 20-bit
  packed uint32_t, 2 bits per trit, 00 = Zero, 01 = One, 10 = Two.
  Acceptance: the CUDA and PTX files and the host harnesses use that
  packing.

## Board compiler

- SYS-101: A board is a plain-text file, one component or directive per
  line, whitespace-delimited, with `#` or `*` comments. Acceptance:
  the compiler reads board/examples/board.txt and
  board/examples/board-hybrid.txt.
- SYS-102: The compiler emits SPICE, Verilog-A, netlist, and KiCad
  output from the same board file, with no dependency beyond awk.
  Acceptance: all four modes run on the example boards.
- SYS-103: The MNA solver reads a board directly and solves DC and
  transient, including nonlinear diodes by Newton-Raphson.
  Acceptance: the solver runs the RC example and the output voltage
  lags the input as a low-pass filter requires.

## Dual circuit and SRAM write-cell

- SYS-201: The dual-circuit controller has four modes: Idle, Calibrate,
  Run, Fault. Mode is 2 bits. Acceptance: the WhyML semantics, the
  Cryptol contract, and the VHDL RTL state the same four modes.
- SYS-202: The controller locks when it runs. A write to SRAM is only
  enabled while locked and running. Acceptance: the state invariant,
  the PSL properties, and the RTL agree on run-implies-locked and on
  the write-enable condition.
- SYS-203: Out-of-range phase error drives the controller to Fault and
  clears the lock. Acceptance: the WhyML step function and the
  Cryptol contract state that transition.
- SYS-301: The SRAM write-cell returns the new value when enabled and
  the old value when not enabled. Acceptance: the WhyML semantics,
  the Cryptol contract, and the VHDL RTL state the same write rule.

## Out of scope

- SYS-901: No complete CPU, no dual-SRAM sequential machine, and no
  Verilog-A / PEX timing contracts are in this tree. Phase 2 and
  Phase 3 of malbolge-circuit/README.md are not built here.
- SYS-902: No flight, safety-critical, or human-rated behavior is
  required or claimed.
