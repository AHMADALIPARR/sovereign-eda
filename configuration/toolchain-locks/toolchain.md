# Toolchain — measured 2026-11-21 on this VM

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

Every version below is from measured output on this VM on 2026-11-21,
not from memory. A toolchain that is not installed is recorded as not
installed.

| Tool | Version / status |
| --- | --- |
| cc / gcc | Ubuntu 13.3.0-6ubuntu2~24.04.1 |
| python3 | 3.12.3 |
| GHDL | 4.1.0 (Ubuntu 4.1.0+dfsg-0ubuntu2.1), mcode JIT |
| awk | mawk 1.3.4 20240123 |
| Lean | 4.12.0 via elan (~/.elan/bin/lean), not on the default PATH |
| SAW | 1.5 (957290e, release tag v1.5) at ~/workspace/.tools/saw-1.5-ubuntu-24.04-X64-with-solvers/bin/saw |
| Cryptol | 3.5.0, same bundle as SAW |
| Why3 | 1.6.0 at /usr/bin/why3 (installed on this VM after the first gate run on 2026-11-21; the earlier "Not installed" entry was measured before the install) |
| Yosys | 0.33 (git sha1 2584903a060) at /usr/bin/yosys (installed on this VM after the first gate run on 2026-11-21; the earlier "Not installed" entry was measured before the install). No GHDL plugin: Ubuntu does not ship ghdl.so, so netlists go through GHDL synthesis to Verilog plus Yosys read_verilog. |
| Z3 | /usr/bin/z3 (invoked by SAW and Why3; version not separately recorded) |

## VM swap 2026-11-21 ~17:23

A VM replacement wiped /usr/bin/why3, /usr/bin/yosys, /usr/bin/ghdl,
and /usr/bin/z3, and killed the running abc proof. All three were
reinstalled from the Ubuntu pool as .debs, kept in
~/workspace/.tools/debs/ so the next swap needs only `dpkg -i`:
yosys_0.33-5build2, ghdl_4.1.0+dfsg-0ubuntu2.1 (+ ghdl-mcode and
ghdl-common, same version), why3_1.6.0-1build7. yosys and why3 are
left unconfigured by dpkg (missing python3-click and yosys-abc for
yosys; GUI/OCaml libs for why3) but all three binaries run;
`apt-get -f install` once the package lists update will configure
them. Ubuntu does NOT ship the Yosys GHDL plugin (no ghdl.so in any
noble package), so the Makefiles no longer use `yosys -m ghdl`:
the netlist path is now GHDL synthesis to Verilog plus Yosys
read_verilog. SAW needs z3 on PATH; the Makefiles put the SAW
bundle bin dir first, since the bundle ships its own z3.
| nvcc | Not installed |
| ptxas | Not installed |
| ngspice | Not installed (not checked in this run) |

## Restoration note

VM replacements have wiped apt-installed toolchains before. Why3 and
Yosys were absent at the first gate run on 2026-11-21 and present
later the same day (Why3 1.6.0, Yosys 0.33, both in /usr/bin), so a
"not installed" entry is a measurement at a time, not a permanent
fact. After a replacement, restore from this file and re-run
scripts/release-gate.sh. A proof that passed before a wipe is not
passed after it until it runs again.
