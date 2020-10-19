# #####################################
# Design constraints
# #####################################

# Timing
create_clock -p $CLK -n MY_CLK clk

set_clock_uncertainty 0.07 [get_clocks MY_CLK] 
set_input_delay 0.5 -max -clock MY_CLK [remove_from_collection [all_inputs] clk]
set_output_delay 0.5 -max -clock MY_CLK [all_outputs]
set_load [load_of NangateOpenCellLibrary/BUF_X4/A] [all_outputs]
set_dont_touch_network MY_CLK

