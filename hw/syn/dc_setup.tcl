# #####################################
# Setup project
# #####################################

# Set variables

set SRC_DIR ../src
set TGT sos_df2
set CLK 10

set RPT_DIR ./report
set OUT_DIR ./netlist

# Output dir

file delete -force -- work
file delete -force -- autoread-work
file mkdir $OUT_DIR
file mkdir $RPT_DIR
