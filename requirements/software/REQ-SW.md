# Software Requirements

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Owner: Ahmad Ali Parr. Trace: requirements/traceability.csv.

## Malbolge circuit

- SW-001: The reference interpreter is Ben Olmstead's 1998 public-domain
  C. It compiles with a C11 compiler and runs the NOP/HALT example with
  empty output and exit code 0. Acceptance: tests/test_reference.sh.
- SW-002: The Python test oracle checks the crazy operation on all 9
  trit pairs, rotation over all 59049 values, and 10000 random
  crazy-word samples. Acceptance: tests/test_core.py prints PASS.
- SW-003: The VHDL ALU is a 16-bit encoded combinational 10-trit ALU
  computing crazy, rotate, and valid. Acceptance: GHDL analyzes
  rtl/malbolge_alu.vhd with exit code 0.
- SW-004: The WhyML semantics states crazy, rotate, decode, increment,
  and crazy10, with verification conditions discharged by Z3.
  Acceptance: `why3 prove` reports all five conditions Valid. Status:
  BLOCKED on this VM, Why3 is not installed. See defect D-002.
- SW-005: The SAW script verifies the synthesized ALU against the
  Cryptol contract. Acceptance: `make prove` completes. Status:
  BLOCKED on this VM, Yosys is not installed, so no netlist is
  produced for SAW to check. See defect D-003.
- SW-006: The Lean v2 tryte layer states the fixed tryteToNat and the
  roundtrip is verified by execution over all 59049 values.
  Acceptance: lean/MalbolgeTryteV2.lean checks clean and
  gpu/tests/verify_v2_host.c reports 0 roundtrip failures.
- SW-007: The v1 kernels are not modified to fix v1 behavior. V2 is a
  separate benchmark variant. Acceptance: v1 files are unchanged by
  the v2 work, and the v1 harness still passes.

## GPU kernels

- SW-101: The CUDA device functions implement tritAdd, tritSub,
  crazyOp, tryteToNat, natToTryte, incrementTryte, crazyTryte,
  decryptTryte, permuteTryte, and decodeInstruction. Acceptance: the
  host harness checks them against the Lean definitions with no GPU.
- SW-102: The PTX kernel implements the same operations in assembly
  for sm_70. Acceptance: assembly by ptxas. Status: NOT VERIFIED on
  this VM, no ptxas is installed. See defect D-005.
- SW-103: CUDA compilation by nvcc is not claimed. Status: NOT
  VERIFIED on this VM, no CUDA toolchain is installed. See defect
  D-004.

## Board

- SW-201: The board compiler is a single POSIX awk script with no
  dependency beyond awk. Acceptance: board/eda.awk runs all four
  modes on the example boards.
- SW-202: The MNA solver is pure awk. Acceptance: board/mna.awk runs
  the RC example to completion.
- SW-203: The board VHDL files analyze in dependency order: controller,
  calibrator, SRAM bank, structural top, write-cell. Acceptance:
  GHDL analyzes all five files with exit code 0 in that order.
- SW-204: The p4_controller and the SRAM write-cell have GHDL
  simulation testbenches that pass. The controller testbench drives
  reset, start, and phase error and checks mode, lock, write-enable,
  and the calibration-word step against the Cryptol state machine.
  The write-cell testbench checks enabled and disabled writes.
  Acceptance: `make test` in board/p4-dual-circuit/ and in
  board/sram-write-cell/ both report TESTBENCH PASS with exit code 0.
- SW-205: The SRAM bank and the structural dual_circuit top have no
  simulation testbench in this tree. Behavioral verification of those
  two blocks is NOT claimed. See defect D-006.

## Traceability and configuration

- SW-301: Every requirement in this file has a row in
  requirements/traceability.csv naming its design, implementation,
  test, and result.
- SW-302: Every file in the tree is listed in WATERMARK.md with its
  SHA-256 digest, and the watermark HEAD matches a recomputation.
  Acceptance: scripts/release-gate.sh recomputes the chain.
- SW-303: Toolchain versions used for a release are recorded in
  configuration/toolchain-locks/toolchain.md, from measured output,
  not from memory.
