# SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
# Copyright (C) 2026 SnapKitty West
#
# Generates the netlist the SAW equivalence script checks, then runs it.
# From a clean checkout, `make prove` generates build/sram_write_cell.json
# first; the netlist is a build output and is not committed. Requires
# GHDL and Yosys. The netlist goes through GHDL synthesis to Verilog
# and Yosys read_verilog, not the Yosys GHDL plugin, which Ubuntu
# does not ship.
# SAW lives in the bundle under ~/workspace/.tools on this VM, not on
# the default PATH. SAW defaults to that bundle when it exists, else
# to `saw` on PATH. Override with `make prove SAW=/path/to/saw`.
SAW ?= $(if $(wildcard $(HOME)/workspace/.tools/saw-1.5-ubuntu-24.04-X64-with-solvers/bin/saw),$(HOME)/workspace/.tools/saw-1.5-ubuntu-24.04-X64-with-solvers/bin/saw,saw)
# SAW needs z3 on PATH; the bundle ships one, so its bin dir goes first.
SAW_BIN := $(dir $(SAW))
.PHONY: analyze test prove clean

analyze:
	mkdir -p build
	ghdl -a --std=08 sram_write_cell.vhd
	ghdl --synth --std=08 --out=verilog sram_write_cell.vhd -e sram_write_cell > build/sram_write_cell.v
	yosys -p 'read_verilog build/sram_write_cell.v; hierarchy -top sram_write_cell; proc; opt; techmap -map ../../malbolge-circuit/yosys/modfloor_map.v; pmuxtree; opt; write_json build/sram_write_cell.json'

test:
	ghdl -a --std=08 sram_write_cell.vhd verification/tb_sram_write_cell.vhd
	ghdl -e --std=08 tb_sram_write_cell
	ghdl -r --std=08 tb_sram_write_cell

prove: analyze
	PATH="$(SAW_BIN):$$PATH" $(SAW) write_cell_equivalence.saw

clean:
	rm -rf build work-obj08.cf
