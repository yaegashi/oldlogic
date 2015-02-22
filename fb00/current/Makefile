# $Id: Makefile 11 2005-11-21 17:30:51Z yaegashi $

WORKDIR = work
EXPORTDIR = export

TOP = fb
FPGAPART = xc3s200-ft256-4
PROMPART = xcf02s
XFLOW = xflow -p $(FPGAPART) -wd $(WORKDIR) -ed $(EXPORTDIR)
PROMGEN = promgen -x $(PROMPART) -w -p bin
PRJFILE = $(TOP).prj
UCFFILE = $(TOP).ucf
DATFILE = $(TOP).dat
TMPFILE = $(WORKDIR)/tmp.bin
NGCFILE = $(WORKDIR)/$(EXPORTDIR)/$(TOP).ngc
BITFILE = $(WORKDIR)/$(EXPORTDIR)/$(TOP).bit
BINFILE = $(WORKDIR)/$(EXPORTDIR)/$(TOP).bin
MCSFILE = $(WORKDIR)/$(EXPORTDIR)/$(TOP).mcs

all: $(MCSFILE)

clean:
	rm -rf $(WORKDIR) xflow.his _impact.*

$(NGCFILE): $(PRJFILE)
	$(XFLOW) -synth xst_mixed.opt $<

$(BITFILE): $(NGCFILE) $(UCFFILE)
	cp $(UCFFILE) $(WORKDIR)
	$(XFLOW) -implement balanced.opt -config bitgen.opt $<

$(BINFILE): $(BITFILE)
	$(PROMGEN) -u 0 $(BITFILE) -o $(MCSFILE)

$(MCSFILE): $(BINFILE) $(DATFILE)
	cat $(BINFILE) > $(TMPFILE)
	printf '\xde\xad\xbe\xef' >> $(TMPFILE)
	cat $(DATFILE) >> $(TMPFILE)
	objcopy -I binary -O ihex $(TMPFILE) $@
