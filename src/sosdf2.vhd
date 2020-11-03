library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- work
use work.sosdf2_pkg.all;
use work.numeric_pkg.all;

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
    -- * Clustered Look-ahead transform L=1 
    -- * structural arch 

    -- Enable reg pipeline
    signal valid_q : std_logic_vector(4 downto 0);

    -- Input/Ouput samples
    signal x_q       : std_logic_vector(WLD-1 downto 0);  -- valid input sample
    signal x_q_align : std_logic_vector(WLI-1 downto 0);  -- aligned qf 
    signal y_d       : std_logic_vector(WLI-1 downto 0);  -- output sample  
    signal y_d_tru   : std_logic_vector(WLD-1 downto 0);

    -- Delay line
    signal dreg_d   : std_logic_vector(WLI-1 downto 0);
    signal dreg_d_q : std_logic_vector(WLI-1 downto 0);  -- pipelined version
    signal dreg_q   : reg_t;
    signal dreg_q2  : reg_t;                             -- pipelined version

    -- Mul results, rounded and pipelined
    signal fb_prod        : fb_prod_t;
    signal ff_prod        : ff_prod_t;
    signal fb_prod_r      : fb_prod_r_t;
    signal ff_prod_r      : ff_prod_r_t;
    signal fb_prod_r_q    : fb_prod_r_t;
    signal ff_prod_r_q    : ff_prod_r_t;
    signal ff_prod_r_q2_0 : std_logic_vector(WLI-1 downto 0);
    signal ff_prod_r_q2_1 : std_logic_vector(WLI-1 downto 0);

    -- Sum op
    signal fb_sum     : std_logic_vector(WLI-1 downto 0);
    signal ff_sum_1   : std_logic_vector(WLI-1 downto 0);
    signal ff_sum_2   : std_logic_vector(WLI-1 downto 0);
    signal ff_sum_2_q : std_logic_vector(WLI-1 downto 0);

begin

    -- Valid input sample
    reg_0 : entity work.reg
        generic map (
            N => WLD)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_i,
            d_i   => data_i,
            q_o   => x_q);

    -- Valid signal pipeline
    shiftreg_1 : entity work.shiftreg
        generic map (
            N => valid_q'LENGTH)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => '1',
            d_i   => valid_i,
            q_o   => valid_q);

    valid_o <= valid_q(4);

    -- Delay line
    reg_1_0 : entity work.reg
        generic map (
            N => WLI)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_q(0),
            d_i   => dreg_d,
            q_o   => dreg_q(0));
    dreg_gen : for i in 1 to dreg_q'HIGH generate
        reg_1_i : entity work.reg
            generic map (
                N => WLI)
            port map (
                clk   => clk,
                rst_n => rst_n,
                en_i  => valid_q(0),
                d_i   => dreg_q(i-1),
                q_o   => dreg_q(i));
    end generate;

    -- ---------------
    -- Feedback part
    -- ---------------

    -- Feedback mul
    fb_prod_gen : for i in fb_prod'RANGE generate
        fb_mult_inst_i : entity work.mult generic map (
            N => WLI)
            port map (
                a_i => dreg_q(i),
                b_i => fb_coef(i),
                r_o => fb_prod(i));
    end generate;

    -- Round products (truncate)
    fb_r_gen : for i in fb_prod'RANGE generate
        fb_prod_r(i) <= trunc(fb_prod(i), WLI, QFI);
    end generate;

    -- Insert retiming register in feedback loop
    -- u: mult
    -- r_u = +1 shift 1 reg from input arcs to output arc
    fb_ret_gen : for i in fb_prod'RANGE generate
        reg_1_1_i : entity work.reg
            generic map (
                N => WLI)
            port map (
                clk   => clk,
                rst_n => rst_n,
                en_i  => valid_q(0),
                d_i   => fb_prod_r(i),
                q_o   => fb_prod_r_q(i));
    end generate;

    -- Sum feedback products
    fb_add_inst_0 : entity work.add
        generic map (
            N => WLI)
        port map (
            a_i => fb_prod_r_q(0),
            b_i => fb_prod_r_q(1),
            r_o => fb_sum);

    -- Scale sample to internal format (align)
    -- x << (QFI - QF)
    x_q_align <= align(x_q, QFD, WLI, QFI);

    -- Sum feedback samples to input
    fb_sub_inst_0 : entity work.subt
        generic map (
            N => WLI)
        port map (
            a_i => x_q_align,
            b_i => fb_sum,
            r_o => dreg_d);

    -- ----------------
    -- Fir part 
    -- ----------------

    -- Pipe stage 1, split feedback/feedforward
    reg_2_0 : entity work.reg
        generic map (
            N => WLI)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_q(0),
            d_i   => dreg_d,
            q_o   => dreg_d_q);
    pipe_stage_1_gen : for i in dreg_q'RANGE generate
        reg_2_i : entity work.reg
            generic map (
                N => WLI)
            port map (
                clk   => clk,
                rst_n => rst_n,
                en_i  => valid_q(0),
                d_i   => dreg_q(i),
                q_o   => dreg_q2(i));
    end generate;

    -- Pipe stage 2, fir products
    pipe_stage_2_gen : for i in ff_prod_r'RANGE generate
        reg_3_i : entity work.reg
            generic map (
                N => WLI)
            port map (
                clk   => clk,
                rst_n => rst_n,
                en_i  => valid_q(1),
                d_i   => ff_prod_r(i),
                q_o   => ff_prod_r_q(i));
    end generate;

    -- Pipe stage 3, sum 
    reg_4_0 : entity work.reg
        generic map (
            N => WLI)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_q(2),
            d_i   => ff_prod_r_q(0),
            q_o   => ff_prod_r_q2_0);
    reg_4_1 : entity work.reg
        generic map (
            N => WLI)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_q(2),
            d_i   => ff_prod_r_q(1),
            q_o   => ff_prod_r_q2_1);
    reg_4_2 : entity work.reg
        generic map (
            N => WLI)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_q(2),
            d_i   => ff_sum_2,
            q_o   => ff_sum_2_q);

    -- Fir mul op
    ff_mul_inst_0 : entity work.mult generic map (
        N => WLI)
        port map (
            a_i => dreg_d_q,
            b_i => ff_coef(0),
            r_o => ff_prod(0));
    ff_prod_gen : for i in dreg_q2'RANGE generate
        ff_mul_inst_i : entity work.mult generic map (
            N => WLI)
            port map (
                a_i => dreg_q2(i),
                b_i => ff_coef(i+1),
                r_o => ff_prod(i+1));
    end generate;

    -- Round mul res
    ff_prod_r_gen : for i in ff_prod'RANGE generate
        ff_prod_r(i) <= trunc(ff_prod(i), WLI, QFI);
    end generate;

    -- Sum fir
    ff_add_inst_2 : entity work.add
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_r_q(2),
            b_i => ff_prod_r_q(3),
            r_o => ff_sum_2);

    ff_add_inst_1 : entity work.add
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_r_q2_1,
            b_i => ff_sum_2_q,
            r_o => ff_sum_1);

    ff_add_inst_0 : entity work.add
        generic map (
            N => WLI)
        port map (
            a_i => ff_prod_r_q2_0,
            b_i => ff_sum_1,
            r_o => y_d);

    -- Saturate and scale res
    y_d_tru <= y_d(y_d'HIGH downto WLI-WLD);

    -- Registered output
    reg_5 : entity work.reg
        generic map (
            N => WLD)
        port map (
            clk   => clk,
            rst_n => rst_n,
            en_i  => valid_q(3),
            d_i   => y_d_tru,
            q_o   => data_o);

end architecture;
