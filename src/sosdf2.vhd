library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sosdf2_pkg.all;
use work.numeric_pkg.all;
use work.components_pkg.all;

entity sosdf2 is
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        valid_i : in  std_logic;
        data_i  : in  std_logic_vector(WLD-1 downto 0);
        valid_o : out std_logic;
        data_o  : out std_logic_vector(WLD-1 downto 0));
end entity;

architecture rtl of sosdf2 is
    -- * structural arch * --
    -- Enable reg pipeline
    signal valid_q : std_logic;

    -- Input/Ouput samples
    signal x_q       : std_logic_vector(WLD-1 downto 0);  -- valid input sample
    signal x_q_align : std_logic_vector(WLI-1 downto 0);  -- aligned qf 
    signal y_d       : std_logic_vector(WLI-1 downto 0);  -- output sample  
    signal y_d_sat   : std_logic_vector(WLD-1 downto 0);

    -- Internal node and delay line
    signal d_d : std_logic_vector(WLI-1 downto 0);
    signal d_q : reg_t;

    -- Generate mul
    signal fb_prod : fb_prod_t;
    signal ff_prod : ff_prod_t;

    -- Round mul results
    signal ff_prod_r : ff_prod_r_t;
    signal fb_prod_r : fb_prod_r_t;

    -- Sum op
    signal fb_sum   : std_logic_vector(WLI-1 downto 0);
    signal ff_sum   : std_logic_vector(WLI-1 downto 0);
    signal ff_sum_1 : std_logic_vector(WLI-1 downto 0);
    signal ff_sum_2 : std_logic_vector(WLI-1 downto 0);

    -- FIR pipeline stages
    -- 1 stage
    signal ff_q1          : reg_t;        -- internal node stage, split fb/ff
    -- 2 stage
    signal ff_prod_r_q    : ff_prod_r_t;  -- multiply & round stage
    -- 3 stage
    signal ff_prod_r_q2_0 : std_logic_vector(WLI-1 downto 0);
    signal ff_prod_r_q2_1 : std_logic_vector(WLI-1 downto 0);
    signal ff_sum_2_q     : std_logic_vector(WLI-1 downto 0);

begin

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


    -- ----------
    -- Delay line
    -- ----------

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

    -- ---------------
    -- Feedback part
    -- ---------------

    -- Scale sample to internal format (align)
    -- x << (QFI - QF)
    x_q_align <= align(x_q, QFD, WLI, QFI);

    -- Retiming feedback loop
    -- u: mult
    -- r_u = +1 shift 1 reg from input arcs to output arc
    fb_prod_gen : for i in fb_prod'RANGE generate
        mult_inst : mult generic map (
            N => WLI)
            port map (
                a_i => d_q(i),
                b_i => fb_coef(i),
                r_o => fb_prod(i));
    end generate;

    -- Round products (truncate)
    fb_r_gen : for i in fb_prod'RANGE generate
        fb_prod_r(i) <= trunc(fb_prod(i), WLI, QFI);
    end generate;

    -- Insert retiming register in feedback loop
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            fb_prod_r_q <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if valid_q = '1' then
                for i in fb_prod'RANGE loop
                    fb_prod_r_q(i) <= fb_prod_r(i);
                end loop;
            end if;
        end if;
    end process;

    -- Sum feedback products
    fb_sum_inst : add
        generic map (
            N => WLI)
        port map (
            a_i => fb_prod_r(0),
            b_i => fb_prod_r(1),
            r_o => fb_sum);

    -- Sum feedback samples to input
    fb_sub_inst : subt
        generic map (
            N => WLI)
        port map (
            a_i => x_q_align,
            b_i => fb_sum,
            r_o => d_d);

    -- ----------------------
    -- Feedforward part (FIR)
    -- ----------------------

    -- Pipe stage internal node, split fb/ff
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff_q <= (others => (others => '0'));
        elsif rising_edge(clk) then
            ff_q(0)                  <= d_d;
            ff_q(ff_q'HIGH downto 1) <= d_q;
        end if;
    end process;

    -- Pipe stage multiply & round
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff_prod_r_q <= (others => (others => '0'));
        elsif rising_edge(clk) then
            ff_prod_r_q <= ff_prod_r;
        end if;
    end process;

    -- Pipe stage sum 
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff_prod_r_q2_0 <= (others => '0');
            ff_prod_r_q2_1 <= (others => '0');
            ff_sum_2_q     <= (others => '0');
        elsif rising_edge(clk) then
            ff_prod_r_q2_0 <= ff_prod_r(0);
            ff_prod_r_q2_1 <= ff_prod_r(1);
            ff_sum_2_q     <= ff_sum_2;
        end if;
    end process;

    -- FIR mul op
    ff_prod_gen : for i in d_q'RANGE generate
        mul_inst : mult generic map (
            N => WLI)
            port map (
                a_i => d_q(i-1),
                b_i => ff_coef(i),
                r_o => ff_prod(i));
    end generate ff_prod_gen;
    mult_inst_0 : mult generic map (
        N => WLI)
        port map (
            a_i => d_d,
            b_i => ff_coef(0),
            r_o => ff_prod(0));

    -- Round mul res
    ff_prod_r_gen : for i in ff_prod'RANGE generate
        ff_prod_r(i) <= trunc(ff_prod(i), WLI, QFI);
    end generate;

    -- Sum 
    ff_sum_inst_2 : add
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_r_q(2),
            b_i => ff_prod_r_q(3),
            r_o => ff_sum_2);
    ff_sum_inst_1 : add
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_r_q2_1,
            b_i => ff_sum_2_q,
            r_o => ff_sum_1);
    -- Compute output sample
    ff_sum_inst_0 : add
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_r_q2_0,
            b_i => ff_sum_1,
            r_o => y_d);

    -- Saturate results (merge in reg : syn?)
    y_d_sat <= clip(y_d, WLD);

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

end architecture;
