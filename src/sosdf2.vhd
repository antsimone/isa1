library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- custom lib 
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
    signal valid_q : std_logic_vector(2 downto 0);

    -- Input/Ouput samples
    signal x_q       : std_logic_vector(WLD-1 downto 0);  -- valid input sample
    signal x_q_align : std_logic_vector(WLI-1 downto 0);  -- aligned qf 
    signal y_d       : std_logic_vector(WLI-1 downto 0);  -- output sample  
    signal y_d_trunc : std_logic_vector(WLI-QFC+QFD-1 downto 0);
    signal y_d_sat   : std_logic_vector(WLD-1 downto 0);

    -- Delay line
    signal dreg_d   : std_logic_vector(WLI-1 downto 0);
    signal dreg_d_q : std_logic_vector(WLI-1 downto 0);  -- pipelined version
    signal dreg_q   : reg_t;
    signal dreg_q2  : reg_t;                             -- pipelined version

    -- Mul results, rounded and pipelined
    signal ff_prod_r : ff_prod_r_t;
    signal fb_prod_r : fb_prod_r_t;

    -- Sum op
    signal fb_sum : std_logic_vector(WLI-1 downto 0);
    signal ff_sum : std_logic_vector(WLI-1 downto 0);

begin

    -- Sample valid input
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

    -- Valid signal pipeline
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            valid_q <= (others => '0');
            valid_o <= '0';
        elsif rising_edge(clk) then
            valid_q(0) <= valid_i;
            valid_q(1) <= valid_q(0);
            valid_q(2) <= valid_q(1);
            valid_o    <= valid_q(2);
        end if;
    end process;

    -- Delay line
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            dreg_q <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if valid_q(0) = '1' then
                dreg_q(0) <= dreg_d;
                for i in 1 to dreg_q'HIGH loop
                    dreg_q(i) <= dreg_q(i-1);
                end loop;
            end if;
        end if;
    end process;

    -- -------------
    -- Feedback part
    -- -------------

    -- Retiming feedback loop
    -- u: mult
    -- r_u = +1 shift 1 reg from input arcs to output arc
    -- retiming register in feedback loop sample mul results
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            fb_prod_r <= (others => (others => '0'));
        elsif rising_edge(clk) then
            fb_prod_r(0) <=
                trunc(std_logic_vector(signed(fb_coef(0)*signed(dreg_q(0)))),
                      WLI,
                      QFI);
            fb_prod_r(1) <=
                trunc(std_logic_vector(signed(fb_coef(1)*signed(dreg_q(1)))),
                      WLI,
                      QFI);
        end if;
    end process;

    -- Scale sample to internal format (align)
    -- x << (QFI - QF)
    x_q_align <= align(x_q, QFD, WLI, QFI);

    -- Feedback sum 
    process(fb_prod_r, x_q_align)
    begin
        fb_sum <= std_logic_vector(signed(x_q_align)
                                   - (signed(fb_prod_r(0))
                                      + signed(fb_prod_r(1))));
    end process;

    -- --------
    -- Fir part
    -- --------

    -- Pipe stage 1, split feedback/feedforward
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            dreg_d_q <= (others => '0');
            dreg_q2  <= (others => (others => '0'));
        elsif rising_edge(clk) then
            dreg_d_q <= dreg_d;
            dreg_q2  <= dreg_q;
        end if;
    end process;

    -- Pipe stage 2, fir products 
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff_prod_r <= (others => (others => '0'));
        elsif rising_edge(clk) then
            ff_prod_r(0) <= std_logic_vector(signed(ff_coef(0))*signed(dreg_d_q));
            for i in dreg_q'RANGE loop
                ff_prod_r(i+1) <=
                    trunc(
                        std_logic_vector(signed(ff_coef(i+1))*signed(dreg_q2(i))),
                        WLI,
                        QFI);
            end loop;
        end if;
    end process;

    -- Pipe stage 3, pipe sum 
    process(clk, rst_n)
    begin
        if rst_n = '0' then
        elsif rising_edge(clk) then
        end if;
    end process;

-- Saturate truncated res 
-- only discard lsbs, no need for trunc()
    y_d_trunc <= y_d(y_d'HIGH downto QFI-QFD);
    y_d_sat   <= clip(y_d_trunc, WLD);

-- Registered output
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            data_o <= (others => '0');
        elsif rising_edge(clk) then
            if valid_q(2) = '1' then
                data_o <= y_d_sat;
            end if;
        end if;
    end process;

end architecture;
