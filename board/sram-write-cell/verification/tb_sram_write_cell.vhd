-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKitty West
--
-- Testbench for sram_write_cell. Checks the RTL against the Cryptol
-- contract in board/sram-write-cell/sram.cry (writeCell): the result
-- is the new value when enabled, the old value when not enabled.
-- The SAW equivalence proof checks the same function against the
-- synthesized netlist; this testbench checks the RTL by simulation.
library ieee;
use ieee.std_logic_1164.all;

entity tb_sram_write_cell is
end entity;

architecture sim of tb_sram_write_cell is
  signal old_value : std_logic_vector(7 downto 0) := (others => '0');
  signal new_value : std_logic_vector(7 downto 0) := (others => '0');
  signal enable    : std_logic := '0';
  signal result    : std_logic_vector(7 downto 0);
begin
  uut : entity work.sram_write_cell
    port map (
      old_value => old_value,
      new_value => new_value,
      enable    => enable,
      result    => result
    );

  stim : process
    variable failures : integer := 0;

    procedure check(cond : boolean; msg : string) is
    begin
      if not cond then
        report "FAIL: " & msg severity error;
        failures := failures + 1;
      end if;
    end procedure;
  begin
    old_value <= x"AA";
    new_value <= x"55";
    enable <= '0';
    wait for 1 ns;
    check(result = x"AA", "disabled write returns the old value");

    enable <= '1';
    wait for 1 ns;
    check(result = x"55", "enabled write returns the new value");

    old_value <= x"00";
    new_value <= x"FF";
    enable <= '0';
    wait for 1 ns;
    check(result = x"00", "disabled write returns old value 00");

    enable <= '1';
    wait for 1 ns;
    check(result = x"FF", "enabled write returns new value FF");

    old_value <= x"12";
    new_value <= x"34";
    enable <= '1';
    wait for 1 ns;
    check(result = x"34", "enabled write returns new value 34");

    assert failures = 0 report "TESTBENCH FAILED" severity failure;
    report "TESTBENCH PASS: sram_write_cell";
    wait;
  end process;
end architecture;
