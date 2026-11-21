/* SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001 */
/* Copyright (C) 2026 SnapKitty West */

library ieee;
use ieee.std_logic_1164.all;

entity sram_write_cell is
  port (
    old_value : in  std_logic_vector(7 downto 0);
    new_value : in  std_logic_vector(7 downto 0);
    enable    : in  std_logic;
    result    : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of sram_write_cell is
begin
  result <= new_value when enable = '1'
            else old_value;
end architecture;
