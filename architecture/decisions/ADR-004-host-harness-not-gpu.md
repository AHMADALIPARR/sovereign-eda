# ADR-004: Host harness verifies device functions, not GPU execution

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Status: accepted.

Context: this VM has no CUDA toolchain and no GPU. The CUDA and PTX
files cannot be compiled or run here.

Decision: gpu/tests/verify_cuda_host.c and gpu/tests/verify_v2_host.c
check the CUDA device functions on the host, against independent C
implementations of the Lean definitions. They verify the arithmetic.
They do not verify GPU execution, GPU timing, nvcc compilation, or
PTX assembly. Those checks are recorded as NOT RUN (defects D-004
and D-005) and are Jetson measurements, not this VM's numbers.

Consequence: a passing host harness never becomes a claim that the
kernel ran on a GPU.
