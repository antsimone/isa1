# #####################################
# Setup project
# #####################################

source "dc_setup.tcl"

# #####################################
# Elaborate
# #####################################

analyze -f vhdl -l work -autoread -recursive $SRC_DIR -top $TGT
elaborate $TGT
uniquify
link

# #####################################
# Design constraints
# #####################################

source "dc_constraints.tcl"

# #####################################
# Compile
# #####################################

#remove_unconnected_ports [get_cells -hierarchical *]
compile -gate_clock

# #####################################
# Synthesis reports
# #####################################

report_area > $RPT_DIR/area.rpt
report_power > $RPT_DIR/power.rpt
report_timing > $RPT_DIR/timing.rpt
report_resources > $RPT_DIR/resources.rpt

# #####################################
# Write 
# #####################################

# Clock-gating cell 

set power_preserve_rtl_hier_names true
set power_cg_flatten true

# Export netlist 

ungroup -all -flatten
change_names -hierarchy -rules verilog

write_sdc $OUT_DIR/$TGT.sdc
write_sdf $OUT_DIR/$TGT.sdf
write -f verilog -hierarchy -output $OUT_DIR/$TGT.v

quit
