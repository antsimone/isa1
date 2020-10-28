RTLSRC_DIR		= ../src
RTLSRC_UNITS	= $(wildcard $(RTLSRC_DIR)/*.vhd) $(wildcard $(RTLSRC_DIR)/*/*.vhd)
TBSRC_DIR		= ../tb
TBSRC_UNITS		= $(wildcard $(TBSRC_DIR)/*.vhd) 
TB				= tb_top
WORK_DIR		= work

GHDLWORK 		= --workdir=$(WORK_DIR)
GHDLRUNFLAGS	= --vcd=sim.vcd -gFILENAME_I="../scripts/samples" -gFILENAME_O="results"

# TODO WARNS

info: lib
	@ghdl --elab-order $(GHDLWORK) $(GHDLFLAGS) $(TB)

run: obj
	@ghdl -r $(GHDLWORK) $(TB) $(GHDLRUNFLAGS)  

obj: lib
	@ghdl -m $(GHDLWORK) $(TB) 

lib: | $(WORK_DIR)
	@ghdl -i $(GHDLWORK) $(RTLSRC_UNITS) $(TBSRC_UNITS)

$(WORK_DIR):
	@mkdir $@

clean: 
	@ghdl --clean $(GHDLWORK) 
	@ghdl --remove $(GHDLWORK) 

cleanall: clean
	@rm -f *.vcd *.txt results -r $(WORK_DIR)

.PHONY: run obj lib clean cleanall

