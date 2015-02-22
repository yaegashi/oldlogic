# $Id: Makefile 56 2005-11-30 21:18:16Z yaegashi $

WORKDIR = xflow
EXPORTDIR = export

TOP = top
FPGAPART = xc3s200-ft256-4
PROMPART = xcf02s
XFLOW = xflow -p $(FPGAPART) -wd $(WORKDIR) -ed $(EXPORTDIR)
PROMGEN = promgen -x $(PROMPART) -w -p bin
PRJFILE = $(TOP).prj
UCFFILE = $(TOP).ucf
DATFILE = $(TOP).dat
CMDFILE = $(TOP).cmd
TMPFILE = $(WORKDIR)/tmp.bin
NGCFILE = $(WORKDIR)/$(TOP).ngc
NCDFILE = $(WORKDIR)/$(TOP).ncd
BITFILE = $(WORKDIR)/$(TOP).bit
BINFILE = $(WORKDIR)/$(TOP).bin
MCSFILE = $(WORKDIR)/$(TOP).mcs
SVFFILE = $(WORKDIR)/$(TOP).svf
FSIMFILE = $(WORKDIR)/func_sim.vhd
TSIMFILE = $(WORKDIR)/time_sim.vhd
STUBFILE = gdb-stub/gdb-stub.dat

all: $(MCSFILE)
synth: $(NGCFILE)
svf: $(SVFFILE)
fsim: $(FSIMFILE)
tsim: $(TSIMFILE)

clean:
	rm -rf $(WORKDIR) xflow.his _impact*

$(NGCFILE): $(PRJFILE)
	mkdir -p $(WORKDIR)
	cp xst_mixed.opt $(UCFFILE) $(WORKDIR)
	$(XFLOW) -synth xst_mixed.opt $<

$(NCDFILE): $(NGCFILE)
	$(XFLOW) -implement high_effort.opt $<

$(FSIMFILE): $(NGCFILE)
	$(XFLOW) -fsim modelsim_vhdl.opt $<

$(BITFILE): $(NCDFILE)
	$(XFLOW) -config bitgen.opt $<

$(TSIMFILE): $(NCDFILE)
	$(XFLOW) -tsim modelsim_vhdl.opt $<

$(BINFILE): $(BITFILE)
	$(PROMGEN) -u 0 $(BITFILE) -o $(MCSFILE)

$(MCSFILE): $(BINFILE) $(STUBFILE)
	cat $(BINFILE) > $(TMPFILE)
	printf '\xde\xad\xbe\xef' >> $(TMPFILE)
	cat $(STUBFILE) >> $(TMPFILE)
	objcopy -I binary -O ihex $(TMPFILE) $@

$(SVFFILE): $(CMDFILE) $(BITFILE) $(MCSFILE)
	impact -batch $(CMDFILE)
	# XXX: Cut down too long wait for my computer.
	perl -pi -e 's,FREQUENCY.*HZ,FREQUENCY 0 HZ,;' \
	         -e 's,RUNTEST (\d+)0 TCK,RUNTEST $$1 TCK,;' $@

$(STUBFILE):
	$(MAKE) -C gdb-stub
