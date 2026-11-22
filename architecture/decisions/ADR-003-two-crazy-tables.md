# ADR-003: Two crazy tables, kept distinct

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Status: accepted.

Context: the reference interpreter and the circuit use the standard
Malbolge crazy table. The Lean formalization and the GPU kernels use
the owner's variant table, which differs in 5 of 9 entries.

Decision: the two tables are not reconciled into one. Each layer states
which table it uses, and each harness checks its layer against its own
table. Comparing a layer against the other table is a category error,
not a contradiction.

Consequence: traceability rows for SYS-004 and SW-101 record the table
per layer. Any future unification is a separate owner decision, not a
gate fix.
