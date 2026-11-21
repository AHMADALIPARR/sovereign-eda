library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity p4_controller is
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        start      : in  std_logic;
        phase_err  : in  signed(7 downto 0);
        cal_word   : out unsigned(7 downto 0);
        mode_out   : out std_logic_vector(1 downto 0);
        locked     : out std_logic;
        sram_we_en : out std_logic
    );
end entity p4_controller;

architecture rtl of p4_controller is
    type mode_t is (MODE_IDLE, MODE_CALIBRATE, MODE_RUN, MODE_FAULT);
    signal mode_reg : mode_t := MODE_IDLE;
    signal cal_reg  : unsigned(7 downto 0) := to_unsigned(128, 8);
    signal lock_reg : std_logic := '0';
begin
    process(clk, rst_n)
        variable err_abs : unsigned(7 downto 0);
    begin
        if rst_n = '0' then
            mode_reg <= MODE_IDLE;
            cal_reg  <= to_unsigned(128, 8);
            lock_reg <= '0';
        elsif rising_edge(clk) then
            if phase_err < 0 then
                err_abs := unsigned(-phase_err);
            else
                err_abs := unsigned(phase_err);
            end if;

            case mode_reg is
                when MODE_IDLE =>
                    lock_reg <= '0';
                    if start = '1' then
                        mode_reg <= MODE_CALIBRATE;
                    end if;

                when MODE_CALIBRATE =>
                    if err_abs <= 2 then
                        mode_reg <= MODE_RUN;
                        lock_reg <= '1';
                    else
                        lock_reg <= '0';
                        if phase_err > 0 then
                            if cal_reg > 0 then
                                cal_reg <= cal_reg - 1;
                            end if;
                        else
                            if cal_reg < 255 then
                                cal_reg <= cal_reg + 1;
                            end if;
                        end if;
                    end if;

                when MODE_RUN =>
                    if err_abs <= 4 then
                        lock_reg <= '1';
                    else
                        mode_reg <= MODE_CALIBRATE;
                        lock_reg <= '0';
                    end if;

                when MODE_FAULT =>
                    lock_reg <= '0';
            end case;
        end if;
    end process;

    cal_word   <= cal_reg;
    locked     <= lock_reg;
    sram_we_en <= '1' when (mode_reg = MODE_RUN and lock_reg = '1') else '0';

    with mode_reg select mode_out <=
        "00" when MODE_IDLE,
        "01" when MODE_CALIBRATE,
        "10" when MODE_RUN,
        "11" when MODE_FAULT;
end architecture rtl;
