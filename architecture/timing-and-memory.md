# Timing and Memory

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Memory

- Malbolge memory: 59049 words, each a 10-trit tryte, values 0 to
  59048. Code and data share one space.
- GPU tryte packing: 20 bits per tryte in a uint32_t. A 59049-tryte VM
  image is 59049 words per thread in the run kernel.
- SRAM bank in the dual circuit: see
  board/p4-dual-circuit/rtl/sram_bank.vhd. The write-cell is one
  8-bit cell: old value, new value, enable, result.

## Timing

- No timing analysis is claimed in this tree. There is no clock
  constraint, no setup/hold analysis, and no measured GPU timing.
- The benchmark in gpu/tests/bench_v1_v2.c is a host CPU proxy only:
  20M pre-generated random valid-tryte calls per op, nanoseconds per
  call, on this VM. It is not GPU timing. Measured 2026-11-21:
  tryteAdd v1 65.62 ns, v2 19.86 ns, ratio 3.30x; tryteSub v1 60.50 ns,
  v2 14.60 ns, ratio 4.14x; crazyTryte v1 60.32 ns, v2 15.04 ns, ratio
  4.01x; tryteToNat v1 34.08 ns, v2 21.95 ns, ratio 1.55x. These
  numbers vary by machine and are not a performance requirement.
- The SAW equivalence proof did not finish within a 10-minute run on
  this VM (1.5 CPUs) when it was last attempted, per STATUS.md. It
  was stopped by the timeout, not by an error. No timing claim is
  made for it.
- The board thermal sweep (board/p4-dual-circuit/verification/thermal/
  thermal_sweep.sp) and the PEX RC checker
  (board/p4-dual-circuit/verification/pex/pex_rc_check.awk) are
  present as files. Neither has a retained run result in this tree,
  so neither is claimed as verified. See defects D-008 and D-009.
