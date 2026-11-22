# SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
# Copyright (C) 2026 SnapKitty West
#
# Dual-circuit project: netlists, simulation, and the SAW proof gate.
# `make test` runs the GHDL testbenches for the controller, the SRAM
# bank, and the structural top; those are the RTL checks. SAW's
# yosys_import is combinational-only and rejects the clocked
# controller's $dff netlist, so there is no SAW equivalence check
# for the RTL (see saw/digital_equivalence.saw). The `analyze`
# target still generates the netlists for future tooling. Requires
# GHDL and Yosys. The netlists go through GHDL synthesis to Verilog
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
	ghdl -a --std=08 rtl/p4_controller.vhd rtl/phase_calibrator.vhd rtl/sram_bank.vhd rtl/dual_circuit.vhd
	ghdl --synth --std=08 --out=verilog rtl/p4_controller.vhd rtl/phase_calibrator.vhd rtl/sram_bank.vhd rtl/dual_circuit.vhd -e p4_controller > build/p4_controller.v
	ghdl --synth --std=08 --out=verilog rtl/p4_controller.vhd rtl/phase_calibrator.vhd rtl/sram_bank.vhd rtl/dual_circuit.vhd -e dual_circuit > build/dual_circuit.v
	yosys -p 'read_verilog build/p4_controller.v; hierarchy -top p4_controller; proc; opt; techmap -map ../../malbolge-circuit/yosys/modfloor_map.v; pmuxtree; opt; write_json build/p4_controller.json'
	yosys -p 'read_verilog build/dual_circuit.v; hierarchy -top dual_circuit; proc; opt; techmap -map ../../malbolge-circuit/yosys/modfloor_map.v; pmuxtree; opt; write_json build/dual_circuit.json'

test:
	ghdl -a --std=08 rtl/p4_controller.vhd verification/tb_p4_controller.vhd
	ghdl -e --std=08 tb_p4_controller
	ghdl -r --std=08 tb_p4_controller --stop-time=500ns
	ghdl -a --std=08 rtl/sram_bank.vhd verification/tb_sram_bank.vhd
	ghdl -e --std=08 tb_sram_bank
	ghdl -r --std=08 tb_sram_bank --stop-time=500ns
	ghdl -a --std=08 rtl/p4_controller.vhd rtl/phase_calibrator.vhd rtl/sram_bank.vhd rtl/dual_circuit.vhd verification/tb_dual_circuit.vhd
	ghdl -e --std=08 tb_dual_circuit
	ghdl -r --std=08 tb_dual_circuit --stop-time=1000ns

prove:
	PATH="$(SAW_BIN):$$PATH" $(SAW) saw/proof_gate.saw

clean:
	rm -rf build work-obj08.cf
