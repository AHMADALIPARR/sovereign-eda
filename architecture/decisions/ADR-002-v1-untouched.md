# ADR-002: V1 is untouched, V2 is a separate benchmark variant

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Status: accepted. Owner order: "We don't touch ours because it's what's
works. We can try the other way on new ones."

Decision: v1 (gpu/malbolge_ternary.cu, gpu/malbolge_ternary.ptx,
lean/MalbolgeProcessorRoot.lean) is unchanged. V2 is three new files
(lean/MalbolgeTryteV2.lean, gpu/malbolge_ternary_v2.cu,
gpu/malbolge_ternary_v2.ptx) that try the fixed tryteToNat and SWAR
packed operations, to benchmark against v1.

Consequence: the v1 roundtrip failure count (58806 of 59049) is a
measured property of v1, recorded in defect D-001, not a bug fixed by
editing v1. The v2 harness measures both versions side by side.
