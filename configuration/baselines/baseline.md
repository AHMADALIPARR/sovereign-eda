# Baselines

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Rule

A baseline is a commit whose release gate passed and whose release
approval is recorded. No commit in this tree has met that rule yet.

## Current state, 2026-11-21

- Remote HEAD (AHMADALIPARR/sovereign-eda): 28c37e0, the owner's own
  deletion of board/BOARD.md. Local HEAD is two commits ahead of that
  (v2 kernels 2abc6eb, headers 08ba3d4), unpushed.
- This commit (NASA evidence layer, local only) does not declare a
  baseline. Its gate FAILS: WhyML and SAW are blocked, CUDA and PTX
  are not run, the board RTL has no simulation, and no release
  approval exists. See reports/release-readiness/release-readiness.md.
- No baseline is declared until the gate passes and the owner approves
  the release in writing. The approval, when it happens, is recorded
  in reports/release-readiness/release-readiness.md with the commit
  hash, the gate log, and the approver.

## What a baseline records

When a baseline is declared, it records: the commit hash, the gate
log, the toolchain versions, the watermark HEAD, the known defects
still open, and the approver. Anything not in that record is not part
of the baseline.
