library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult is
    generic (N : positive);
    port (
        a_i : in  std_logic_vector(N-1 downto 0);
        b_i : in  std_logic_vector(N-1 downto 0);
        r_o : out std_logic_vector(2*N-1 downto 0));
end entity;

architecture beh of mult is
begin
    r_o <= std_logic_vector(signed(a_i)*signed(b_i));
end architecture;