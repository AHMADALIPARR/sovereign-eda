# Changelog

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Unreleased (local only, not pushed)

- NASA evidence layer: requirements, architecture, traceability,
  verification, tests index, assurance, configuration, operations,
  release gate, and CI workflow. No existing file moved. Gate fails
  on 2026-11-21 (WhyML and SAW blocked, CUDA and PTX not run, board
  RTL has no simulation, no release approval), so no push happens
  from this commit.

## 2026-11-21 — v2 kernels and headers (local, unpushed)

- V2 kernels: benchmark variant with fixed tryteToNat, SWAR packed
  ops, bfe crazy_op. V1 untouched.
- License headers on all files that can carry one. README and STATUS
  paths corrected.
