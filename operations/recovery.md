# Recovery

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Toolchain loss (VM replacement)

VM replacements have wiped apt-installed toolchains before. Recovery:
reinstall from configuration/toolchain-locks/toolchain.md, then run
scripts/release-gate.sh. A proof that passed before a wipe is not
passed after it until it runs again.

## Bad push

If a push happens from a failing gate, the recovery is: revert the
push, fix the gate failure, re-run the gate, and record the incident
in assurance/defects/defect-log.md. The gate is not enforced by the
hosting service, so this depends on owner discipline.

## Lost local work

Local commits are the only copy until pushed. The two unpushed commits
(v2 kernels, headers) and this NASA evidence commit exist only on
this VM until a push is approved. Do not delete the local tree
before a push is confirmed by remote HEAD.
