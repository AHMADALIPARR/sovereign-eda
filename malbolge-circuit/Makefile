# SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
# Copyright (C) 2026 SnapKitty West
#
# SAW lives in the bundle under ~/workspace/.tools on this VM, not on
# the default PATH. SAW defaults to that bundle when it exists, else
# to `saw` on PATH. Override with `make prove SAW=/path/to/saw`.
SAW ?= $(if $(wildcard $(HOME)/workspace/.tools/saw-1.5-ubuntu-24.04-X64-with-solvers/bin/saw),$(HOME)/workspace/.tools/saw-1.5-ubuntu-24.04-X64-with-solvers/bin/saw,saw)
# SAW needs z3 on PATH; the bundle ships one, so its bin dir goes first.
SAW_BIN := $(dir $(SAW))
.PHONY: test whyml analyze prove clean

test:
	python3 tests/test_core.py

whyml:
	PATH="$(SAW_BIN):$$PATH" why3 prove semantics/MalbolgeCore.mlw

analyze:
	mkdir -p build
	ghdl -a --std=08 rtl/malbolge_alu.vhd
	ghdl --synth --std=08 --out=verilog rtl/malbolge_alu.vhd -e malbolge_alu > build/malbolge_alu.v
	yosys -p 'read_verilog build/malbolge_alu.v; hierarchy -top malbolge_alu; proc; opt; techmap -map yosys/modfloor_map.v; pmuxtree; opt; write_json build/malbolge_alu.json'

prove: analyze
	PATH="$(SAW_BIN):$$PATH" $(SAW) saw/alu_equivalence.saw

clean:
	rm -rf build work-obj08.cf
