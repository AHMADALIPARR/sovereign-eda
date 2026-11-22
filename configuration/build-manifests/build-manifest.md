# Build Manifest

SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
Copyright (C) 2026 SnapKitty West

## Builds that run on this VM

| Artifact | Command | Result 2026-11-21 |
| --- | --- | --- |
| Reference interpreter | cc -std=c11 -O2 -Wall -Wextra malbolge-circuit/reference/malbolge.c -o malbolge | Compiles, one unused-variable warning for j |
| Python oracle | python3 malbolge-circuit/tests/test_core.py | PASS |
| GHDL ALU analysis | ghdl -a --std=08 malbolge-circuit/rtl/malbolge_alu.vhd | Exit 0 |
| GHDL board analysis | ghdl -a --std=08 in dependency order (controller, calibrator, SRAM bank, structural top, write-cell) | Exit 0 |
| Board SPICE | awk -v mode=spice -f board/eda.awk board/examples/board.txt | Exit 0 |
| Board netlist | awk -v mode=netlist -f board/eda.awk board/examples/board.txt | Exit 0 |
| Board Verilog-A | awk -v mode=veriloga -f board/eda.awk board/examples/board.txt | Exit 0 |
| Board KiCad | awk -v mode=kicad -f board/eda.awk board/examples/board.txt | Exit 0 |
| MNA solver | awk -f board/mna.awk board/examples/board.txt | Exit 0 |
| V1 host harness | cc -std=c11 -O2 -Wall -Wextra gpu/tests/verify_cuda_host.c | Compiles, harness PASS |
| V2 host harness | cc -std=c11 -O2 -Wall -Wextra gpu/tests/verify_v2_host.c | Compiles, harness PASS |
| CPU proxy benchmark | cc -std=c11 -O2 -Wall -Wextra gpu/tests/bench_v1_v2.c | Compiles, runs |
| Lean v2 | lean lean/MalbolgeTryteV2.lean (Lean 4.12.0) | Exit 0 |

## Builds that do not run on this VM

| Artifact | Reason |
| --- | --- |
| Yosys netlist build/malbolge_alu.json | Yosys not installed |
| WhyML proof | Why3 not installed |
| SAW proof | Needs the Yosys netlist |
| CUDA compile | nvcc not installed |
| PTX assembly | ptxas not installed |

Build outputs are gitignored and are not committed. See .gitignore.
The watermark in WATERMARK.md covers source files, not build outputs.
