# Test-bench 

TB                                 = iir_tb
TB_DIR                             = ../tb
TB_TOP                             = $(TB_DIR)/$(TB).sv
TB_PKG                             =
TB_UNITS                           = $(wildcard $(TB_DIR)/*.vhd)

# DUT 

DUT                                = sos_df2
RTLSRC_DIR                         = ../src
RTLSRC_TOP                         = $(RTLSRC_DIR)/sos_df2.vhd
RTLSRC_PKG                         = $(wildcard $(RTLSRC_DIR)/pkg/*)
RTLSRC_UNITS                       = \
	$(RTLSRC_DIR)/add.vhd \
	$(RTLSRC_DIR)/sub.vhd \
	$(RTLSRC_DIR)/mul.vhd 

SYNSRC_DIR                         = ../syn/netlist
PNRSRC_DIR                         = ../pnr

SIM-out                            = out

# Compiler

VLOG                               = vlog
VCOM                               = vcom -93
OPTIONS                            = -work work
LIBRARY-work                       = mylib

# Run options

VSIM                               = vsim
VSIM_FLAGS                         =
VSIM_GUI_FLAGS                     = -gui

VSIM_W_FLAGS                       = +nowarnTRAN +nowarnTFMPC +nowarnTSCALE
VSIM_G_FLAGS                       = \
	-G/$(TB)/data_src_i/FILE_NAME=refmod/inputs.txt \
	-G/$(TB)/data_sink_i/FILE_NAME=$(SIM-out)/sim.txt
VSIM_L_FLAGS 					   = -L /software/dk/nangate45/verilog/msim6.2g 	

VSIM_SCRIPT                        = vsim.tcl
ALL_VSIM_FLAGS                     = $(VSIM_W_FLAGS) $(VSIM_G_FLAGS)

ALL_UNITS                          = .library .rtl .syn .pnr .tb-units .tb-top

# Compile 

.PHONY : all
all :  
	@echo "Do nothing."

# Clean entire design

.PHONY : clean
clean : 
	@rm -rf $(LIBRARY-work) $(SIM-out) $(ALL_UNITS)
	@rm -f *.ini *.wlf *.vcd transcript
	
# Library directory

.PHONY : library
library : .library

.library :
	vlib $(LIBRARY-work); vmap work $(LIBRARY-work)
	touch .library

# Simulation output directory

$(SIM-out) :
	@mkdir -p $@

# Compile VHDL test-bench units

.tb-units : .library $(TB_UNITS) 
	@$(VCOM) $(OPTIONS) $(TB_UNITS)
	touch .tb-units

# Compile SV test-bench top

.tb-top : .library .tb-units $(TB_PKG) $(TB_TOP) 
	@$(VLOG) $(OPTIONS) $(TB_PKG) $(TB_TOP) 
	touch .tb-top

# Compile all rtl N.B: only pkg deps
# Targets are exclusive : rm alternative units
	
.rtl : .library $(RTLSRC_UNITS) $(RTLSRC_PKG) $(RTLSRC_TOP) 
	@$(VCOM) $(OPTIONS) $(RTLSRC_UNITS) $(RTLSRC_PKG) $(RTLSRC_TOP) 
	@rm -f .syn .pnr
	touch .rtl

# Compile Synopsys dc netlist

.syn : .library $(SYNSRC_DIR)/$(DUT).v 
	@$(VLOG) $(OPTIONS) $(SYNSRC_DIR)/$(DUT).v 
	@rm -f .rtl .pnr
	touch .syn

# Compile Innovus netlist

.pnr : .library $(PNRSRC_DIR)/$(DUT).v 
	@$(VLOG) $(OPTIONS) $(PNRSRC_DIR)/$(DUT).v 
	@rm -f .rtl .syn
	touch .pnr

# RTL
# Run tb and exit

.PHONY: rtl
rtl : ALL_VSIM_FLAGS += -c
rtl : .rtl .tb-top | $(SIM-out)
	$(VSIM) $(ALL_VSIM_FLAGS) \
	work.$(TB) -do 'source $(VSIM_SCRIPT);exit -f'

		
# Run tb with simulator gui

.PHONY: rtl-gui
rtl-gui : ALL_VSIM_FLAGS += $(VSIM_GUI_FLAGS)
rtl-gui : .rtl .tb-top | $(SIM-out)
	$(VSIM) $(ALL_VSIM_FLAGS) \
	work.$(TB) -do $(VSIM_SCRIPT)
		
# Synopsys dc netlist
# Run tb and exit

.PHONY: syn
syn : ALL_VSIM_FLAGS += \
-c \
$ $(VSIM_L_FLAGS) \
-sdftyp /$(TB)/DUT=$(SYNSRC_DIR)/$(DUT).sdf

syn : .syn .tb-top | $(SIM-out)
	$(VSIM) $(ALL_VSIM_FLAGS) \
	work.$(TB) \
	-do ' \
		vcd file syn.vcd; \
		vcd add /$(TB)/DUT/*; \
		source $(VSIM_SCRIPT); \
		exit -f \
		'

# Run tb with simulator gui

.PHONY: syn-gui
syn-gui : ALL_VSIM_FLAGS += \
$(VSIM_GUI_FLAGS) \
$(VSIM_L_FLAGS) \
-sdftyp /$(TB)/DUT=$(SYNSRC_DIR)/$(DUT).sdf

syn-gui : .syn .tb-top | $(SIM-out)
	$(VSIM) $(ALL_VSIM_FLAGS) \
	work.$(TB) -do ' \
		vcd file syn.vcd; \
		vcd add /$(TB)/DUT/*; \
		source $(VSIM_SCRIPT); \
		'		
# Layout netlist
# Run tb and exit

.PHONY: pnr
pnr : ALL_VSIM_FLAGS += \
-c \
$(VSIM_L_FLAGS) \
-sdftyp /$(TB)/DUT=$(PNRSRC_DIR)/$(DUT).sdf 

pnr : .pnr .tb-top | $(SIM-out)
	$(VSIM) $(ALL_VSIM_FLAGS) \
	work.$(TB) \
	-do ' \
		vcd file pnr.vcd; \
		vcd add /$(TB)/DUT/*; \
		source $(VSIM_SCRIPT); \
		exit -f \
		'

# Run tb with simulator gui

.PHONY: pnr-gui
pnr-gui : ALL_VSIM_FLAGS += \
$(VSIM_GUI_FLAGS) \
$(VSIM_L_FLAGS) \
-sdftyp /$(TB)/DUT=$(PNRSRC_DIR)/$(DUT).sdf

pnr-gui : .pnr .tb-top | $(SIM-out)
	$(VSIM) $(ALL_VSIM_FLAGS) \
	work.$(TB) \
	-do ' \
		vcd file pnr.vcd; \
		vcd add /$(TB)/DUT/*; \
		source $(VSIM_SCRIPT); \
		'
		
	
        
