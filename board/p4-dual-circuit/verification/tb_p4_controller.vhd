-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKitty West
--
-- Testbench for p4_controller. Checks the RTL against the state machine
-- in board/p4-dual-circuit/cryptol/State.cry (step_state) and
-- board/p4-dual-circuit/semantics/state.mlw: Idle, Calibrate, Run,
-- run-implies-locked, write-enable only while locked and running, and
-- the calibration-word step.
--
-- This is the RTL check for the dual circuit. SAW cannot check this
-- entity: yosys_import models each module as a combinational function
-- from input ports to output ports (SAW manual ch. 6), and the
-- clocked controller's $dff netlist is rejected at import
-- ("undetected cycle in the netgraph", measured 2026-11-21). The
-- Fault transition in the WhyML model takes an out-of-range integer
-- error, which the 8-bit signed phase_err port cannot present, so the
-- RTL never enters Fault; that model difference is recorded in
-- assurance/defects/defect-log.md, not hidden by this testbench.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_p4_controller is
end entity;

architecture sim of tb_p4_controller is
  signal clk       : std_logic := '0';
  signal rst_n     : std_logic := '0';
  signal start     : std_logic := '0';
  signal phase_err : signed(7 downto 0) := to_signed(0, 8);
  signal cal_word  : unsigned(7 downto 0);
  signal mode_out  : std_logic_vector(1 downto 0);
  signal locked    : std_logic;
  signal sram_we_en : std_logic;
begin
  uut : entity work.p4_controller
    port map (
      clk        => clk,
      rst_n      => rst_n,
      start      => start,
      phase_err  => phase_err,
      cal_word   => cal_word,
      mode_out   => mode_out,
      locked     => locked,
      sram_we_en => sram_we_en
    );

  clk <= not clk after 5 ns;

  stim : process
    variable failures : integer := 0;

    procedure check(cond : boolean; msg : string) is
    begin
      if not cond then
        report "FAIL: " & msg severity error;
        failures := failures + 1;
      end if;
    end procedure;

    procedure step is
    begin
      wait until rising_edge(clk);
      wait for 1 ns;
    end procedure;
  begin
    -- Reset: Idle, unlocked, write disabled, cal_word 128.
    rst_n <= '0';
    wait for 12 ns;
    rst_n <= '1';
    wait for 1 ns;
    check(mode_out = "00", "reset state is Idle");
    check(locked = '0', "reset state is unlocked");
    check(sram_we_en = '0', "reset state disables the SRAM write");
    check(cal_word = to_unsigned(128, 8), "reset cal_word is 128");

    -- Start moves Idle to Calibrate.
    start <= '1';
    phase_err <= to_signed(0, 8);
    step;
    check(mode_out = "01", "start moves Idle to Calibrate");
    check(locked = '0', "Calibrate is unlocked");
    check(sram_we_en = '0', "Calibrate disables the SRAM write");

    -- |err| <= 2 moves Calibrate to Run, locked, write enabled.
    step;
    check(mode_out = "10", "small error moves Calibrate to Run");
    check(locked = '1', "Run is locked");
    check(sram_we_en = '1', "Run enables the SRAM write");

    -- |err| > 4 in Run returns to Calibrate, unlocked.
    phase_err <= to_signed(10, 8);
    step;
    check(mode_out = "01", "large error moves Run back to Calibrate");
    check(locked = '0', "leaving Run clears the lock");
    check(sram_we_en = '0', "leaving Run disables the SRAM write");

    -- Positive error in Calibrate steps cal_word down by one.
    phase_err <= to_signed(5, 8);
    step;
    check(mode_out = "01", "large error holds Calibrate");
    check(cal_word = to_unsigned(127, 8), "positive error steps cal_word 128 to 127");

    -- Small error returns to Run.
    phase_err <= to_signed(0, 8);
    step;
    check(mode_out = "10", "small error moves Calibrate to Run again");
    check(locked = '1', "Run is locked again");
    check(sram_we_en = '1', "Run enables the SRAM write again");

    -- |err| = 3 holds Run (|err| <= 4).
    phase_err <= to_signed(-3, 8);
    step;
    check(mode_out = "10", "error of 3 holds Run");
    check(locked = '1', "Run stays locked");

    -- Reset returns to Idle.
    rst_n <= '0';
    wait for 12 ns;
    rst_n <= '1';
    wait for 1 ns;
    check(mode_out = "00", "reset returns to Idle");
    check(locked = '0', "reset clears the lock");
    check(cal_word = to_unsigned(128, 8), "reset restores cal_word 128");

    assert failures = 0 report "TESTBENCH FAILED" severity failure;
    report "TESTBENCH PASS: p4_controller";
    wait;
  end process;
end architecture;
