-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKitty West
--
-- Testbench for dual_circuit, the structural top in
-- board/p4-dual-circuit/rtl/dual_circuit.vhd. Checks the whole chain
-- end to end: reset values, start moves Calibrate to Run with the
-- oscillators aligned (phase error stays zero), the lock, the SRAM
-- write allowed while locked and blocked while unlocked, and the
-- calibration word stepping down once the oscillators are skewed.
--
-- The phase error is driven only through osc_clk_a and osc_clk_b:
-- aligned clocks hold the error at zero, holding osc_clk_b low while
-- osc_clk_a keeps toggling grows it positive. The controller-level
-- step rules themselves are covered by tb_p4_controller.vhd; this
-- bench checks that the top wires them together.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dual_circuit is
end entity;

architecture sim of tb_dual_circuit is
  signal clk       : std_logic := '0';
  signal rst_n     : std_logic := '0';
  signal start     : std_logic := '0';
  signal osc_clk_a : std_logic := '0';
  signal osc_clk_b : std_logic := '0';
  signal we_req    : std_logic := '0';
  signal addr      : unsigned(7 downto 0) := (others => '0');
  signal din       : std_logic_vector(31 downto 0) := (others => '0');
  signal dout      : std_logic_vector(31 downto 0);
  signal cal_word  : unsigned(7 downto 0);
  signal locked    : std_logic;
  signal osc_b_run : std_logic := '1';
begin
  uut : entity work.dual_circuit
    port map (
      clk       => clk,
      rst_n     => rst_n,
      start     => start,
      osc_clk_a => osc_clk_a,
      osc_clk_b => osc_clk_b,
      we_req    => we_req,
      addr      => addr,
      din       => din,
      dout      => dout,
      cal_word  => cal_word,
      locked    => locked
    );

  clk <= not clk after 5 ns;
  osc_clk_a <= not osc_clk_a after 10 ns;
  osc_clk_b <= not osc_clk_b after 10 ns when osc_b_run = '1' else '0';

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

    procedure write_at(a : integer; d : std_logic_vector(31 downto 0)) is
    begin
      addr <= to_unsigned(a, 8);
      din <= d;
      we_req <= '1';
      step;
      we_req <= '0';
    end procedure;

    procedure read_at(a : integer; expect : std_logic_vector(31 downto 0); msg : string) is
    begin
      addr <= to_unsigned(a, 8);
      we_req <= '0';
      step;
      check(dout = expect, msg);
    end procedure;
  begin
    -- Reset: unlocked, cal_word 128.
    rst_n <= '0';
    wait for 12 ns;
    rst_n <= '1';
    wait for 1 ns;
    check(locked = '0', "reset state is unlocked");
    check(cal_word = to_unsigned(128, 8), "reset cal_word is 128");

    -- Aligned oscillators hold the phase error at zero, so start
    -- moves Calibrate to Run and locks.
    start <= '1';
    step;
    step;
    check(locked = '1', "aligned oscillators lock after start");
    check(cal_word = to_unsigned(128, 8), "no error leaves cal_word at 128");

    -- SRAM write while locked lands and reads back.
    write_at(3, x"CAFEBABE");
    check(dout = x"CAFEBABE", "locked write lands in the SRAM");
    read_at(3, x"CAFEBABE", "locked write reads back");

    -- SRAM write while unlocked is blocked: reset, then write.
    rst_n <= '0';
    wait for 12 ns;
    rst_n <= '1';
    wait for 1 ns;
    check(locked = '0', "reset clears the lock again");
    write_at(3, x"FFFFFFFF");
    read_at(3, x"CAFEBABE", "unlocked write leaves the stored word alone");

    -- Lock again, then skew the oscillators: hold osc_clk_b low
    -- while osc_clk_a keeps toggling, so the phase error grows
    -- positive, the controller drops out of Run, and the
    -- calibration word steps down from 128.
    start <= '1';
    step;
    step;
    check(locked = '1', "second lock after start");
    osc_b_run <= '0';
    wait for 300 ns;
    check(locked = '0', "growing phase error drops the lock");
    check(cal_word < to_unsigned(128, 8), "positive phase error steps cal_word down");

    assert failures = 0 report "TESTBENCH FAILED" severity failure;
    report "TESTBENCH PASS: dual_circuit";
    wait;
  end process;
end architecture;
