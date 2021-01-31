library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity data_sink is
    generic (
                WLD      : positive := 8;
                FILENAME : string   := "");
    port(
            clk    : in std_logic;
            rst_n  : in std_logic;
            en_i   : in std_logic;
            data_i : in std_logic_vector(WLD-1 downto 0));
end entity;

architecture beh of data_sink is
begin
    -- Write line to file at each clock cycle is unit is enabled
    process(clk, rst_n)
        file fp         : text open WRITE_MODE is FILENAME;
        variable line_v : line;
        variable data_v : integer;
    begin
        if rst_n = '0' then
            null;
        elsif rising_edge(clk) then
            if en_i = '1' then
                data_v := to_integer(signed(data_i));
                write(line_v, data_v);
                writeline(fp, line_v);
            end if;
        end if;
    end process;

end architecture;

