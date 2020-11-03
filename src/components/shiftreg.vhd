library ieee;
use ieee.std_logic_1164.all;

entity shiftreg is
    -- SIPO
    generic (N : positive := 8);
    port(
        clk   : in  std_logic;
        rst_n : in  std_logic;
        en_i  : in  std_logic;
        d_i   : in  std_logic;
        q_o   : out std_logic_vector(N-1 downto 0));
end entity;

architecture beh of shiftreg is
    signal q : std_logic_vector(N-1 downto 0);
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            q(0) <= d_i;
            for i in q'HIGH downto 1 loop
                q(i) <= q(i-1);
            end loop;
        end if;
    end process;

    q_o <= q;

end architecture;
