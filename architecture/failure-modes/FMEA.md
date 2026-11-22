# Failure Modes

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Scope: design failure modes and their controls in this tree. No flight
failure mode applies, because no output here reaches flight hardware.

| ID | Failure | Effect | Control | Status |
| --- | --- | --- | --- | --- |
| F-001 | V1 tryteToNat folds the array big-endian, so it is not the inverse of natToTryte | V1 addressing is wrong for 58806 of 59049 values | V2 is a separate variant with the fixed folding; v1 is preserved as-is and measured, not silently fixed | Known, see defect D-001 |
| F-002 | Out-of-range phase error | Controller must go to Fault and unlock | WhyML step and Cryptol contract drive Fault and clear locked; PSL asserts Fault implies unlocked and write disabled | Stated in semantics and contract; WhyML proof BLOCKED here (D-002); the RTL never enters Fault and the port cannot present an out-of-range error (D-013) |
| F-003 | SRAM write while not locked and running | Uncontrolled write | Write enable requires mode Run and locked, in the invariant, the PSL properties, and the RTL | Stated in all three layers; the GHDL testbench checks the RTL behavior and passes |
| F-004 | Fault mode entered, then step continues | Stuck or unsafe state | Fault is sticky in the WhyML and Cryptol step functions | Stated in the models; WhyML proof BLOCKED here (D-002) |
| F-005 | Board file has a floating net | Unconnected node in the emitted deck | ERC flags degree-1 nets (excluding ground) to stderr | Present in eda.awk; the SIN source value in board.txt has spaces, so ERC flags sin(0 and 5 as floating nets — that is the board as written |
| F-006 | Out-of-domain trit value 3 in a packed tryte | Host harness feeds an invalid tryte | The harnesses generate only valid trytes; the first v1 harness run failed on exactly this fault in the harness, not in the CUDA code, and the harness was fixed | Fixed in the harness; recorded in STATUS.md |
| F-007 | Yosys netlist missing or stale | SAW checks the wrong circuit or nothing | make prove depends on make analyze; the gate fails when Yosys is absent instead of claiming a proof | BLOCKED here (D-003) |
| F-008 | Lean file needs libraries not present | File does not elaborate here | The gate records it as BLOCKED, not as failed in the owner's environment | See defect D-007 |
| F-009 | Release pushed from a failing gate | Unverified baseline published | The gate exits non-zero on any required failure, and no push happens from a failing gate | Enforced by scripts/release-gate.sh |
