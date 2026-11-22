# Security

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Scope

This repository holds source code, hardware descriptions, formal
specifications, and documentation. It runs no network service, stores
no credentials, and holds no secrets. No token, key, or password is
committed in this tree. A token used to push is used once and stripped.

## Reporting

Report a security issue to the owner, Ahmad Ali Parr, through the
repository. Do not file a public issue with credentials, private URLs,
or exploit details in it.

## Dependency review

The tree has no package dependencies beyond the toolchains listed in
configuration/toolchain-locks/toolchain.md. The reference interpreter
is Ben Olmstead's 1998 public-domain C. No third-party package is
vendored here. If a dependency is added, it is recorded in the
toolchain file and the build manifest with its version and source.
