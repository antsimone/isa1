library ieee;
use ieee.std_logic_1164.all;

entity reg is
    generic (N : positive := 8);
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        en_i  : in  std_logic;
        d_i   : in  std_logic_vector(N-1 downto 0);
        q_o   : out std_logic_vector(N-1 downto 0));
end entity;

architecture beh of reg is
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            q_o <= (others => '0');
        elsif rising_edge(clk) then
            if en_i = '1' then
                q_o <= d_i;
            end if;
        end if;
    end process;

end architecture;
