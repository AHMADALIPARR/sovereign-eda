library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity phase_calibrator is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        osc_clk_a : in  std_logic;
        osc_clk_b : in  std_logic;
        phase_err : out signed(7 downto 0)
    );
end entity phase_calibrator;

architecture rtl of phase_calibrator is
    signal sync_a, sync_b : std_logic_vector(1 downto 0) := "00";
    signal err_acc        : signed(7 downto 0) := (others => '0');
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            sync_a  <= "00";
            sync_b  <= "00";
            err_acc <= (others => '0');
        elsif rising_edge(clk) then
            sync_a <= sync_a(0) & osc_clk_a;
            sync_b <= sync_b(0) & osc_clk_b;

            if (sync_a(1) = '0' and sync_a(0) = '1') and not (sync_b(1) = '0' and sync_b(0) = '1') then
                if err_acc < 127 then
                    err_acc <= err_acc + 1;
                end if;
            elsif (sync_b(1) = '0' and sync_b(0) = '1') and not (sync_a(1) = '0' and sync_a(0) = '1') then
                if err_acc > -128 then
                    err_acc <= err_acc - 1;
                end if;
            end if;
        end if;
    end process;

    phase_err <= err_acc;
end architecture rtl;
