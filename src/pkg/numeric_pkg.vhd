library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package numeric_pkg is
    -- * Design units that do not require different architectures * --

    -- fx_prod >> NB
    -- drop right-most part since we have fractional coefficients
    function trunc(
        arg       : std_logic_vector;
        RES_L, NB : natural)
        return std_logic_vector;

    -- Scale sample to internal format (align)
    -- x << (RES_QF - ARG_QF)
    -- This function ensure that vector slice is within range when Q_DIFF=0
    function align(
        arg                   : std_logic_vector;
        ARG_QF, RES_L, RES_QF : natural)
        return std_logic_vector;

    -- Check sign extension out of WLD range
    -- Clip value to max/min
    function clip(
        arg   : std_logic_vector;
        RES_L : natural)
        return std_logic_vector;

end package;

package body numeric_pkg is

    -- fx_prod >> NB
    -- drop right-most part since we have fractional coefficients

    function trunc(arg : std_logic_vector; RES_L, NB : natural)
        return std_logic_vector is
        constant RES_H : natural := NB + RES_L - 1;
    begin
        return arg(RES_H downto NB);
    end function;

    -- Scale sample to internal format (align)
    -- x << (RES_QF - ARG_QF)
    -- This function ensure that vector slice is within range when Q_DIFF=0

    function align(arg : std_logic_vector; ARG_QF, RES_L, RES_QF : natural)
        return std_logic_vector is
        constant NEW_L : natural := RES_QF - ARG_QF;
        variable res_v : signed(RES_L-1 downto 0);
    begin
        res_v                       := (others => '0');
        res_v(RES_L-1 downto NEW_L) := resize(signed(arg), RES_L - NEW_L);
        return std_logic_vector(res_v);
    end function;

    -- Check sign extension out of WLD range
    -- Clip value to max/min

    function clip(arg : std_logic_vector; RES_L : natural)
        return std_logic_vector is
        variable ret_v     : std_logic_vector(RES_L-1 downto 0);
        variable MAX_VALUE : signed(RES_L-1 downto 0);
        variable MIN_VALUE : signed(RES_L-1 downto 0);
    begin
        MAX_VALUE(RES_L-1)          := '0';  --(RES_L-1 => '0', others => '1');
        MAX_VALUE(RES_L-2 downto 0) := (others => '1');
        MIN_VALUE(RES_L-1)          := '1';  --(RES_L-1 => '1', others => '0');
        MIN_VALUE(RES_L-2 downto 0) := (others => '0');
        if signed(arg) > MIN_VALUE then
            if signed(arg) > MAX_VALUE then
                ret_v := std_logic_vector(MAX_VALUE);
            else
                ret_v := arg(ret_v'RANGE);
            end if;
        else
            ret_v := std_logic_vector(MIN_VALUE);
        end if;
        return ret_v;
    end function;

end package body;
