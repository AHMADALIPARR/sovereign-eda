-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKitty West
--
-- Testbench for sram_bank. Checks the synchronous 256x32 RAM in
-- board/p4-dual-circuit/rtl/sram_bank.vhd: write-through on we,
-- read-back, address boundaries 0 and 255, unwritten locations read
-- as zero, and a read cycle never writes.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sram_bank is
end entity;

architecture sim of tb_sram_bank is
  signal clk  : std_logic := '0';
  signal we   : std_logic := '0';
  signal addr : unsigned(7 downto 0) := (others => '0');
  signal din  : std_logic_vector(31 downto 0) := (others => '0');
  signal dout : std_logic_vector(31 downto 0);
begin
  uut : entity work.sram_bank
    port map (
      clk  => clk,
      we   => we,
      addr => addr,
      din  => din,
      dout => dout
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

    procedure write_at(a : integer; d : std_logic_vector(31 downto 0)) is
    begin
      addr <= to_unsigned(a, 8);
      din <= d;
      we <= '1';
      step;
      check(dout = d, "write-through returns the written word");
      we <= '0';
    end procedure;

    procedure read_at(a : integer; expect : std_logic_vector(31 downto 0); msg : string) is
    begin
      addr <= to_unsigned(a, 8);
      we <= '0';
      step;
      check(dout = expect, msg);
    end procedure;
  begin
    -- Unwritten locations read as zero.
    read_at(5, x"00000000", "unwritten location reads as zero");

    -- Write and read back, middle of the bank.
    write_at(5, x"DEADBEEF");
    read_at(5, x"DEADBEEF", "read back returns the written word");

    -- Address boundaries.
    write_at(0, x"00000001");
    write_at(255, x"FFFFFFFF");
    read_at(0, x"00000001", "address 0 holds its word");
    read_at(255, x"FFFFFFFF", "address 255 holds its word");

    -- A read cycle never writes: present new data with we low.
    addr <= to_unsigned(5, 8);
    din <= x"12345678";
    we <= '0';
    step;
    check(dout = x"DEADBEEF", "read cycle leaves the stored word alone");

    -- Overwriting one address leaves its neighbours alone.
    write_at(5, x"CAFEBABE");
    read_at(5, x"CAFEBABE", "overwrite replaces the word");
    read_at(0, x"00000001", "neighbour address 0 is untouched");
    read_at(255, x"FFFFFFFF", "neighbour address 255 is untouched");

    assert failures = 0 report "TESTBENCH FAILED" severity failure;
    report "TESTBENCH PASS: sram_bank";
    wait;
  end process;
end architecture;
