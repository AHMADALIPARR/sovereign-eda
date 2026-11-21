/* SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001 */
/* Copyright (C) 2026 SnapKitty West */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Combinational 10-trit Malbolge datapath.
-- Inputs are 16-bit unsigned words constrained to 0 .. 59048.
-- Invalid inputs yield valid='0'; results have no semantic meaning in that case.
entity malbolge_alu is
  port (
    a       : in  std_logic_vector(15 downto 0);
    d       : in  std_logic_vector(15 downto 0);
    crazy   : out std_logic_vector(15 downto 0);
    rotate  : out std_logic_vector(15 downto 0);
    valid   : out std_logic
  );
end entity;

architecture rtl of malbolge_alu is
  function trit_op(acc_trit : natural; mem_trit : natural) return natural is
  begin
    case mem_trit is
      when 0 =>
        case acc_trit is
          when 0 => return 1;
          when 1 => return 0;
          when others => return 0;
        end case;
      when 1 =>
        case acc_trit is
          when 0 => return 1;
          when 1 => return 0;
          when others => return 2;
        end case;
      when others =>
        case acc_trit is
          when 0 => return 2;
          when 1 => return 2;
          when others => return 1;
        end case;
    end case;
  end function;

  function crazy_word(x : natural; y : natural) return natural is
    variable xx, yy, factor, result : natural := 0;
  begin
    xx := x;
    yy := y;
    factor := 1;
    for k in 0 to 9 loop
      result := result + factor * trit_op(xx mod 3, yy mod 3);
      xx := xx / 3;
      yy := yy / 3;
      factor := factor * 3;
    end loop;
    return result;
  end function;

  function rotate_word(x : natural) return natural is
  begin
    return (x / 3) + (x mod 3) * 19683;
  end function;
begin
  process(all)
    variable av, dv : natural;
  begin
    av := to_integer(unsigned(a));
    dv := to_integer(unsigned(d));
    if av <= 59048 and dv <= 59048 then
      crazy  <= std_logic_vector(to_unsigned(crazy_word(av, dv), 16));
      rotate <= std_logic_vector(to_unsigned(rotate_word(dv), 16));
      valid  <= '1';
    else
      crazy  <= (others => '0');
      rotate <= (others => '0');
      valid  <= '0';
    end if;
  end process;
end architecture;
