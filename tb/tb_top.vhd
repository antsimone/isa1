library ieee;
use ieee.std_logic_1164.all;

entity tb_top is
end entity;
architecture test of tb_top is
    constant FILENAME_I : string   := "../octave/samples";
    constant FILENAME_O : string   := "results";
    constant WLD        : positive := 8;     -- data size
    constant TS         : time     := 1 NS;  -- sample period (clk)

    -- clk, rst gen
    signal clk   : std_logic;
    signal rst_n : std_logic;

    -- src
    signal en_i    : std_logic;
    signal end_sim : std_logic;

    -- dut pins
    signal valid_i, valid_o : std_logic;
    signal data_i, data_o   : std_logic_vector(WLD-1 downto 0);
begin
    -- Clk and reset gen
    process
    begin
        clk <= '0';
        wait for TS/2;
        clk <= not(clk);
        wait for TS/2;
    end process;
    process
    begin
        rst_n <= '0';
        wait for 3*TS/2;
        rst_n <= '1';
        wait;
    end process;

    -- Valid input pause
    process
    begin
        en_i <= '1';
        wait for 16*TS;         -- wait 16 cycles before toggle
        for i in 0 to 1 loop
            report "Toggle input data stream enable";
            en_i <= not en_i;
            wait for 8*TS; -- wait 8 cycles 
        end loop;
        wait;
    end process;

    -- Stop simulation after end of input stream
    process
    begin
        wait until rising_edge(end_sim);
        wait for 3*TS;                  -- Drain filter results
        report "Close sim";
        assert FALSE severity FAILURE;
    end process;

    -- DUT 
    sos_df2_1 : entity work.sos_df2
        port map (
            clk     => clk,
            rst_n   => rst_n,
            valid_i => valid_i,
            data_i  => data_i,
            valid_o => valid_o,
            data_o  => data_o);

    -- file I/O
    data_src_1 : entity work.data_src
        generic map (
            WLD      => WLD,
            FILENAME => FILENAME_I)
        port map (
            clk       => clk,
            rst_n     => rst_n,
            en_i      => en_i,
            data_o    => data_i,
            valid_o   => valid_i,
            end_sim_o => end_sim);
    data_sink_1 : entity work.data_sink
        generic map (
            WLD      => WLD,
            FILENAME => FILENAME_O)
        port map (
            clk    => clk,
            rst_n  => rst_n,
            en_i   => valid_o,
            data_i => data_o);

end architecture;
