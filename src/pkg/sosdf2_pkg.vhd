library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sosdf2_pkg is
    -- Assume filter coefficient wordlength >= samples wordlength
    -- Fractional samples and coefficients Q1.WL_x-1
    constant WLD : natural := 8;
    constant QFD : natural := WLD-1;
    constant WLC : natural := 11;
    constant QFC : natural := WLC-1;
    -- Internal wordlength
    constant WLI : natural := WLC;      -- Sat if WLI > QFC+1
    constant QFI : natural := QFC;

    -- Typedefs

    -- Delay line 
    type reg_t is array (0 to 2) of std_logic_vector(WLI-1 downto 0);

    -- Feedback
    type fb_coef_t is array (0 to 1) of std_logic_vector(WLI-1 downto 0);
    type fb_prod_t is array (0 to 1) of std_logic_vector(WLI*2-1 downto 0);
    type fb_prod_r_t is array (0 to 1) of std_logic_vector(WLI-1 downto 0);

    -- Fir 
    type ff_coef_t is array (0 to 3) of std_logic_vector(WLI-1 downto 0);
    type ff_prod_t is array (0 to 3) of std_logic_vector(WLI*2-1 downto 0);
    type ff_prod_r_t is array (0 to 3) of std_logic_vector(WLI-1 downto 0);

    -- Coefficients

    constant FB_COEF : fb_coef_t := (
        std_logic_vector(to_signed(-56, WLI)),
        std_logic_vector(to_signed(75, WLI)));

    constant FF_COEF : ff_coef_t := (
        std_logic_vector(to_signed(208, WLI)),
        std_logic_vector(to_signed(494, WLI)),
        std_logic_vector(to_signed(364, WLI)),
        std_logic_vector(to_signed(78, WLI)));

end package;

