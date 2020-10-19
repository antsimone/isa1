set RPT_DIR report
set DUT sos_df2
set TB iir_tb

read_verilog -netlist netlist/$DUT.v
read_saif -input ${DUT}.saif -instance $TB/DUT -unit ns -scale 1

create_clock -n MY_CLK clk  
report_power > $RPT_DIR/power_saif.rpt
quit

