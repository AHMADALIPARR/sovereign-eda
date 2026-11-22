# Safety Requirements

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Owner: Ahmad Ali Parr. Hazards: assurance/hazards/hazard-log.md.

This repository is non-flight and non-safety-critical
(requirements/classification.md). No hazard in this tree can produce a
hazardous spacecraft state, because no output of this tree reaches
flight hardware. The safety requirements below are proportionate to
that class: they protect the integrity of the design evidence, not a
flight system.

- SAF-001: A write to SRAM is only enabled while the controller is
  locked and running. Acceptance: the state invariant (Run implies
  locked), the PSL properties, and the RTL agree.
- SAF-002: Out-of-range phase error drives the controller to Fault,
  clears the lock, and disables the SRAM write. Acceptance: the WhyML
  step function and the Cryptol contract state that transition.
- SAF-003: Fault mode is sticky in the WhyML and Cryptol models: once
  in Fault, the state step returns the same state. Acceptance: the
  step functions state that rule.
- SAF-004: No release is made from a failing gate. If
  scripts/release-gate.sh exits non-zero, the tree is not pushed and
  no baseline is declared. Acceptance: the gate script exits non-zero
  on any required failure, and the release-readiness report records
  the failure.
- SAF-005: No test result is claimed that was not produced by running
  the test. A check that did not run is recorded as NOT RUN or
  BLOCKED, never as passed. Acceptance: reports/test-results/ holds
  the logs the gate produced.
- SAF-006: No file is presented as the owner's verbatim code when it
  was reconstructed. Reconstructed files are labeled in-file.
  Acceptance: lean/MalbolgeProcessor.lean carries its reproduction
  label, and the board VHDL provenance is stated in STATUS.md.
