library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_circuit is
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        start      : in  std_logic;
        osc_clk_a  : in  std_logic;
        osc_clk_b  : in  std_logic;
        we_req     : in  std_logic;
        addr       : in  unsigned(7 downto 0);
        din        : in  std_logic_vector(31 downto 0);
        dout       : out std_logic_vector(31 downto 0);
        cal_word   : out unsigned(7 downto 0);
        locked     : out std_logic
    );
end entity dual_circuit;

architecture structural of dual_circuit is
    signal phase_err_s  : signed(7 downto 0);
    signal mode_s       : std_logic_vector(1 downto 0);
    signal locked_s     : std_logic;
    signal sram_we_en_s : std_logic;
    signal sram_we_g    : std_logic;
begin
    u_phase_cal : entity work.phase_calibrator
        port map (
            clk       => clk,
            rst_n     => rst_n,
            osc_clk_a => osc_clk_a,
            osc_clk_b => osc_clk_b,
            phase_err => phase_err_s
        );

    u_ctrl : entity work.p4_controller
        port map (
            clk        => clk,
            rst_n      => rst_n,
            start      => start,
            phase_err  => phase_err_s,
            cal_word   => cal_word,
            mode_out   => mode_s,
            locked     => locked_s,
            sram_we_en => sram_we_en_s
        );

    sram_we_g <= we_req and sram_we_en_s;

    u_sram : entity work.sram_bank
        port map (
            clk  => clk,
            we   => sram_we_g,
            addr => addr,
            din  => din,
            dout => dout
        );

    locked <= locked_s;
end architecture structural;
