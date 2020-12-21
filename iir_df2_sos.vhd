library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO truncate MUL

entity iir_df2_sos is
    generic (
        -- pkg
        N  : natural := 8;                           -- Q1.N
        NI : natural := 16);                         -- Q1.NI
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        v_i   : in  std_logic;                       -- valid
        d_i   : in  std_logic_vector(N-1 downto 0);  -- data
        v_o   : out std_logic;
        d_o   : out std_logic_vector(N-1 downto 0));
end entity;

architecture beh of iir_df2_sos is
    signal xreg                 : signed(N-1 downto 0);
    signal x, y, w0, w1, w2, w3 : signed(NI-1 downto 0);  -- df ii 

    signal v0, v1, v2 : std_logic;      -- valid (enable reg)

    signal fb0_q, fb1_q : signed(NI-1 downto 0);  -- feedback and retiming

    signal w0_q, w1_q, w2_q, w3_q     : signed(NI-1 downto 0);  -- fb/ff pipeline 
    signal ff0_q, ff1_q, ff2_q, ff3_q : signed(NI-1 downto 0);  -- pipelined fir
    signal ff0_q2, ff1_q2, ff2_sum_q  : signed(NI-1 downto 0);

begin

    -- COMB

    x(NI-1 downto NI-N) <= xreg;        -- align input sample
    x(NI-N-1 downto 0)  <= (others => '0');

    w <= x + fb0 + fb1;
    y <= ff0_q + ff1_q + ff2_sum_q;

    -- REG

    process(clk, rst_n)                 -- sample in
    begin
        if rst_n = '0' then
            x <= (others => '0');
        elsif rising_edge(clk) then
            if v_i = '1' then
                xreg <= signed(d_i);
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- sample out
    begin
        if rst_n = '0' then
            d_o <= (others => '0');
        elsif rising_edge(clk) then
            if v2 = '1' then
                d_o <= std_logic_vector(y(NI-1 downto N-NI));
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- shift reg
    begin
        if rst_n = '0' then
            w1 <= (others => '0');
            w2 <= (others => '0');
            w3 <= (others => '0');
        elsif rising_edge(clk) then
            if v0 = '1' then
                w1 <= w;
                w2 <= w1;
                w3 <= w2;
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- fb MUL (ret)
    begin
        if rst_n = '0' then
            fb0_q <= (others => '0');
            fb1_q <= (others => '0');
        elsif rising_edge(clk) then
            if v(0) = '1' then
                fb0_q <= a1*w1;
                fb1_q <= a2*w2;
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- fb/fir pipe
    begin
        if rst_n = '0' then
            w0_q <= (others => '0');
            w1_q <= (others => '0');
            w2_q <= (others => '0');
            w3_q <= (others => '0');
        elsif rising_edge(clk) then
            if v0 = '1' then
                w0_q <= w;
                w1_q <= w1;
                w2_q <= w2;
                w3_q <= w3;
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- fir pipe 1 / MUL
    begin
        if rst_n = '0' then
            ff0 <= (others => '0');
            ff1 <= (others => '0');
            ff2 <= (others => '0');
            ff3 <= (others => '0');
        elsif rising_edge(clk) then
            if v1 = '1' then
                ff0_q <= b0*w0_q;
                ff1_q <= b1*w1_q;
                ff2_q <= b2*w2_q;
                ff3_q <= b3*w3_q;
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- fir pipe 2
    begin
        if rst_n = '0' then
            ff0_q2    <= (others => '0');
            ff1_q2    <= (others => '0');
            ff2_sum_q <= (others => '0');
        elsif rising_edge(clk) then
            if v2 = '1' then
                ff0_q2    <= ff0_q;
                ff1_q2    <= ff1_q;
                ff2_sum_q <= ff3_q + ff2_q;
            end if;
        end if;
    end process;

    process(clk, rst_n)                 -- valid signal pipe
    begin
        if rst_n = '0' then
            v0 <= '0';
            v1 <= '0';
            v2 <= '0';
        elsif rising_edge(clk) then
            v0  <= v_i;
            v1  <= v0;
            v2  <= v1;
            v_o <= v2;
        end if;
    end process;

end architecture;
