library ieee;
use ieee.std_logic_1164.all;

package components_pkg is
    component add is
        generic (
            N : positive);
        port (
            a_i : in  std_logic_vector(N-1 downto 0);
            b_i : in  std_logic_vector(N-1 downto 0);
            r_o : out std_logic_vector(N-1 downto 0));
    end component;
    component subt is
        generic (
            N : positive);
        port (
            a_i : in  std_logic_vector(N-1 downto 0);
            b_i : in  std_logic_vector(N-1 downto 0);
            r_o : out std_logic_vector(N-1 downto 0));
    end component;
    component mult is
        generic (
            N : positive);
        port (
            a_i : in  std_logic_vector(N-1 downto 0);
            b_i : in  std_logic_vector(N-1 downto 0);
            r_o : out std_logic_vector(N*2-1 downto 0));
    end component;

end package;
