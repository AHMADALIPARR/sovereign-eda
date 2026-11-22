# SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
# Copyright (C) 2026 SnapKitty West
.PHONY: test whyml analyze prove clean

test:
	python3 tests/test_core.py

whyml:
	why3 prove semantics/MalbolgeCore.mlw

analyze:
	mkdir -p build
	ghdl -a --std=08 rtl/malbolge_alu.vhd
	yosys -m ghdl -p 'ghdl --std=08 malbolge_alu; prep -top malbolge_alu; techmap -map yosys/modfloor_map.v; opt; write_json build/malbolge_alu.json'

prove: analyze
	saw saw/alu_equivalence.saw

clean:
	rm -rf build work-obj08.cf
