library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.iir_df2_sos_pkg.all;

entity iir_df2_sos is
    port (
             clk     : in  std_logic;
             rst_n   : in  std_logic;
             valid_i : in  std_logic;
             data_i  : in  std_logic_vector(N-1 downto 0);
             valid_o : out std_logic;
             data_o  : out std_logic_vector(N-1 downto 0)
         );

end entity;


architecture beh of iir_df2_sos is

    -- direct form ii
    signal x_q, y_q : signed(N-1 downto 0);
    signal x, y, w0, w1, w2, w3 : signed(NI-1 downto 0);
    signal fb0, fb1, ff0, ff1, ff2, ff3 : signed(NI*2-1 downto 0);

    -- feedback retiming
    signal fb0_q, fb1_q : signed(NI-1 downto 0);

    -- fir pipeline
    signal w0_q, w1_q, w2_q, w3_q : signed(NI-1 downto 0);
    signal ff0_q, ff1_q, ff2_q, ff3_q : signed(NI-1 downto 0);
    signal ff0_q2, ff1_q2, ff2_sum_q, ff2_sum : signed(NI-1 downto 0);

    -- valid, enable reg
    signal v0, v1, v2, v3 : std_logic;


begin


    data_o  <= std_logic_vector(y_q);
    valid_o <= v3;


    -- comb


    x(NI-1 downto NI-N) <= x_q;  -- align input sample
    x(NI-N-1 downto 0)  <= (others => '0');

    y  <= ff0_q2 + ff1_q2 + ff2_sum_q;
    w0 <= x + fb0_q + fb1_q;

    ff2_sum <= ff2_q + ff3_q;

    fb0 <= a1*w1;
    fb1 <= a2*w2;
    ff0 <= b0*w0_q;
    ff1 <= b1*w1_q;
    ff2 <= b2*w2_q;
    ff3 <= b3*w3_q;


    -- reg


    -- valid signal pipeline

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            v0 <= '0';
            v1 <= '0';
            v2 <= '0';
            v3 <= '0';
        elsif rising_edge(clk) then
            v0 <= valid_i;
            v1 <= v0;
            v2 <= v1;
            v3 <= v2;
        end if;
    end process;


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            x_q <= (others => '0');
        elsif rising_edge(clk) then
            if valid_i = '1' then
                x_q <= signed(data_i);
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            y_q <= (others => '0');
        elsif rising_edge(clk) then
            if v2 = '1' then
                y_q <= y(NI-1 downto NI-N);
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            w1 <= (others => '0');
            w2 <= (others => '0');
            w3 <= (others => '0');
        elsif rising_edge(clk) then
            if v0 = '1' then
                w1 <= w0;
                w2 <= w1;
                w3 <= w2;
            end if;
        end if;
    end process;


    -- feedback retiming

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            fb0_q <= (others => '0');
            fb1_q <= (others => '0');
        elsif rising_edge(clk) then
            if v0 = '1' then
                fb0_q <= fb0(2*NI-2 downto NI-1);
                fb1_q <= fb1(2*NI-2 downto NI-1);
            end if;
        end if;
    end process;


    -- fir pipeline


    process(clk, rst_n)
    begin
        if rst_n = '0' then
            w0_q <= (others => '0');
            w1_q <= (others => '0');
            w2_q <= (others => '0');
            w3_q <= (others => '0');
        elsif rising_edge(clk) then
            if v0 = '1' then
                w0_q <= w0;
                w1_q <= w1;
                w2_q <= w2;
                w3_q <= w3;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff0_q <= (others => '0');
            ff1_q <= (others => '0');
            ff2_q <= (others => '0');
            ff3_q <= (others => '0');
        elsif rising_edge(clk) then
            if v1 = '1' then
                ff0_q <= ff0(2*NI-2 downto NI-1);
                ff1_q <= ff1(2*NI-2 downto NI-1);
                ff2_q <= ff2(2*NI-2 downto NI-1);
                ff3_q <= ff3(2*NI-2 downto NI-1);
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff0_q2    <= (others => '0');
            ff1_q2    <= (others => '0');
            ff2_sum_q <= (others => '0');
        elsif rising_edge(clk) then
            if v2 = '1' then
                ff0_q2    <= ff0_q;
                ff1_q2    <= ff1_q;
                ff2_sum_q <= ff2_sum;
            end if;
        end if;
    end process;


end architecture;
