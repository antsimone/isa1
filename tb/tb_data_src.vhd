library ieee, std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
--use ieee.std_logic_textio.all; -- synopsys

entity data_src is
    generic (
                WLD      : positive := 8;       -- data size
                FILENAME : string   := "");
    port(
            clk       : in  std_logic;
            rst_n     : in  std_logic;
            en_i      : in  std_logic;
            data_o    : out std_logic_vector(WLD-1 downto 0);
            valid_o   : out std_logic;
            end_sim_o : out std_logic);
end entity;

architecture beh of data_src is
    constant TCKQ : time := 100 PS;
begin
    -- Read one sample at each clock cycle if unit is enabled
    process(clk, rst_n)
        file fp         : text open READ_MODE is FILENAME;  -- file ptr
        variable line_v : line;         -- line from file
        variable data_v : integer;      -- sample placeholder
    begin
        if rst_n = '0' then
            data_o    <= (others => '0');
            valid_o   <= '0' after TCKQ;
            end_sim_o <= '0';
        elsif rising_edge(clk) then
            if en_i = '1' then
                if not endfile(fp) then
                    readline(fp, line_v);
                    read(line_v, data_v);
                    data_o  <= std_logic_vector(to_signed(data_v, WLD)) after TCKQ;
                    valid_o <= '1'                                      after TCKQ;
                else                    -- EOF
                    valid_o   <= '0' after TCKQ;
                    end_sim_o <= '1';
                end if;
            else                        -- ! EN
                valid_o <= '0' after TCKQ;
            end if;
        end if;
    end process;

end architecture;
