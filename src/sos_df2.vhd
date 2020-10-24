library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sos_df2_pkg.all;
use work.numeric_pkg.all;
use work.components_pkg.all;

entity sos_df2 is
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        valid_i : in  std_logic;
        data_i  : in  std_logic_vector(WLD-1 downto 0);
        valid_o : out std_logic;
        data_o  : out std_logic_vector(WLD-1 downto 0));
end entity;

architecture rtl of sos_df2 is
    -- Delay line and output reg enable
    signal valid_q     : std_logic;
    signal x_q         : std_logic_vector(WLD-1 downto 0);  -- valid input sample
    signal x_q_align   : std_logic_vector(WLI-1 downto 0);  -- aligned qf 
    signal y_d         : std_logic_vector(WLI-1 downto 0);  -- 1b growth ff
    signal d_d         : std_logic_vector(WLI-1 downto 0);  -- 1b growth fb
    signal y_d_sat     : std_logic_vector(WLD-1 downto 0);
    signal d_q         : reg_t;
    -- Generate products
    signal fb_prod     : fb_prod_t;
    signal ff_prod     : ff_prod_t;
    -- Truncated results
    signal ff_prod_rnd : ff_prod_rnd_t;
    signal fb_prod_rnd : fb_prod_rnd_t;
    -- Sum node
    signal fb_sum      : std_logic_vector(WLI-1 downto 0);
    signal ff_sum      : std_logic_vector(WLI-1 downto 0);

begin

    --
    -- Registers
    -- 

    -- Valid signal pipeline
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            valid_q <= '0';
            valid_o <= '0';
        elsif rising_edge(clk) then
            valid_q <= valid_i;
            valid_o <= valid_q;
        end if;
    end process;

    -- Valid input sample
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            x_q <= (others => '0');
        elsif rising_edge(clk) then
            if valid_i = '1' then
                x_q <= data_i;
            end if;
        end if;
    end process;

    -- Delay line
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            d_q <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if valid_q = '1' then
                d_q(0) <= d_d;
                for i in 1 to d_q'HIGH loop
                    d_q(i) <= d_q(i-1);
                end loop;
            end if;
        end if;
    end process;

    -- Registered output
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            data_o <= (others => '0');
        elsif rising_edge(clk) then
            if valid_q = '1' then
                data_o <= y_d_sat;
            end if;
        end if;
    end process;

    --
    -- Wordlength fun
    -- 

    -- Scale sample to internal format (align)
    -- x << (QFI - QF)
    x_q_align <= align(x_q, QFD, WLI, QFI);

    -- Round products (truncate)
    fb_rnd_gen : for i in fb_prod'RANGE generate
        fb_prod_rnd(i) <= trunc(fb_prod(i), WLI, QFI);
    end generate;
    ff_rnd_gen : for i in ff_prod'RANGE generate
        ff_prod_rnd(i) <= trunc(ff_prod(i), WLI, QFI);
    end generate;

    -- Saturate results
    y_d_sat <= clip(y_d, WLD);

    --
    -- Components inst
    --

    -- Feedback products
    fb_prod_gen : for i in fb_prod'RANGE generate
        multiplier_inst : multiplier generic map (
            N => WLI)
            port map (
                a_i => d_q(i),
                b_i => fb_coef(i),
                r_o => fb_prod(i));
    end generate;

    -- Fir products
    ff_prod_gen : for i in ff_prod'RANGE generate
        ff_gen_0 : if i = 0 generate
            multiplier_inst : multiplier generic map (
                N => WLI)
                port map (
                    a_i => d_d,
                    b_i => ff_coef(i),
                    r_o => ff_prod(i));
        end generate ff_gen_0;
        ff_gen_x : if i > 0 generate
            multiplier_inst : multiplier generic map (
                N => WLI)
                port map (
                    a_i => d_q(i-1),
                    b_i => ff_coef(i),
                    r_o => ff_prod(i));
        end generate ff_gen_x;
    end generate ff_prod_gen;


    -- Sum feedback samples to input
    fb_sub_inst : subtractor
        generic map (
            N => WLI)
        port map (
            a_i => x_q_align,
            b_i => fb_sum,
            r_o => d_d);

    -- Sum feedback products
    fb_sum_inst : adder
        generic map (
            N => WLI)
        port map (
            a_i => fb_prod_rnd(0),
            b_i => fb_prod_rnd(1),
            r_o => fb_sum);

    -- Sum fir products
    ff_sum_inst_0 : adder
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_rnd(0),
            b_i => ff_sum,
            r_o => y_d);
    ff_sum_inst_1 : adder
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_rnd(1),
            b_i => ff_prod_rnd(2),
            r_o => ff_sum);

end architecture;
