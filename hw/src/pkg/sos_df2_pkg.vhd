library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sos_df2_pkg is

    -- Parameters

    constant FILT_ORD : natural := 2;
    constant FILT_LEN : natural := 3;

    -- WordLength

    -- Assume filter coefficient wordlength >= samples wordlength
    -- Fractional samples and coefficients Q1.WL_x-1

    constant WLD : natural := 8;
    constant QF_DATA : natural := WLD-1;
    constant WLC : natural := 8;
    constant QF_COEF : natural := WLC-1;

    -- Guard bits in QI.WLC-1 to avoid overflow

    constant WLI : natural  := WLC+1;
    constant QF_INT : natural  := QF_COEF;

    -- Custom array type

    -- Delay Line

    type reg_t         is array (0 to FILT_LEN-2) of std_logic_vector(WLI-1   downto 0);

    -- Feedback

    type fb_coef_t     is array (0 to FILT_ORD-1) of std_logic_vector(WLI-1   downto 0);
    type fb_prod_t     is array (0 to FILT_ORD-1) of std_logic_vector(WLI*2-1 downto 0);
    type fb_prod_rnd_t is array (0 to FILT_ORD-1) of std_logic_vector(WLI-1   downto 0);

    -- Fir

    type ff_coef_t     is array (0 to FILT_LEN-1) of std_logic_vector(WLI-1   downto 0);
    type ff_prod_t     is array (0 to FILT_LEN-1) of std_logic_vector(WLI*2-1 downto 0);
    type ff_prod_rnd_t is array (0 to FILT_LEN-1) of std_logic_vector(WLI-1   downto 0);

    -- Coefficients
    -- Use deferred constants ?

    constant fb_coef : fb_coef_t := (
        std_logic_vector(to_signed(-48, WLI)),
        std_logic_vector(to_signed(25, WLI)));

    constant ff_coef : ff_coef_t := (
        std_logic_vector(to_signed(26, WLI)),
        std_logic_vector(to_signed(52, WLI)),
        std_logic_vector(to_signed(26, WLI)));

end package;

