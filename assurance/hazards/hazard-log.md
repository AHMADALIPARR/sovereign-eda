# Hazard Log

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Classification: non-flight, non-safety-critical. No hazard here can
produce a hazardous spacecraft state. The hazards below are design
hazards: wrong evidence, wrong netlist, uncontrolled write in the
model. Residual risk is about the integrity of the engineering record.

| ID | Hazard | Cause | Mitigation | Residual risk |
| --- | --- | --- | --- | --- |
| H-001 | SRAM write while not locked and running | Write-enable logic wrong | Run-implies-locked invariant, PSL properties, RTL gating | Low. Stated in three layers, but no simulation runs here, so the RTL behavior is not demonstrated. |
| H-002 | Out-of-range phase error not handled | Step function misses the Fault transition | WhyML and Cryptol state the transition; Fault clears the lock | Low. Stated in the models, WhyML proof blocked here. |
| H-003 | Stale or wrong netlist checked by SAW | analyze step skipped or Yosys missing | make prove depends on make analyze; the gate fails when Yosys is absent | Low. The gate records BLOCKED instead of claiming a proof. |
| H-004 | V1 addressing used where v2 addressing is required | Two tryteToNat foldings, one name | V1 and v2 are separate files with separate harnesses; the v2 harness measures both | Low. The difference is measured (58806 failures in v1) and recorded. |
| H-005 | Unverified baseline pushed | Gate ignored or bypassed | The gate exits non-zero on failure and no push happens from a failing gate; release approval is a separate recorded decision | Low while the gate is the only push path. The gate is not enforced by the hosting service, so it depends on the owner not pushing around it. |
| H-006 | Claimed test that never ran | Status written by hand | The gate writes its own log from the runs it performed; hand-written claims are not test evidence | Low. This log and the gate log are the record. |
