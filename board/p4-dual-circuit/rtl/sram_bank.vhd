library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram_bank is
    port (
        clk  : in  std_logic;
        we   : in  std_logic;
        addr : in  unsigned(7 downto 0);
        din  : in  std_logic_vector(31 downto 0);
        dout : out std_logic_vector(31 downto 0)
    );
end entity sram_bank;

architecture rtl of sram_bank is
    type ram_t is array (0 to 255) of std_logic_vector(31 downto 0);
    signal ram : ram_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(addr)) <= din;
                dout <= din;
            else
                dout <= ram(to_integer(addr));
            end if;
        end if;
    end process;
end architecture rtl;
