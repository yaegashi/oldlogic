# $Id: Makefile 16 2005-11-24 21:16:19Z yaegashi $

WORKDIR = work
EXPORTDIR = export

TOP = top
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

all: $(BITFILE)
synth: $(NGCFILE)

clean:
	rm -rf $(WORKDIR) xflow.his _impact.*

$(NGCFILE): $(PRJFILE)
	$(XFLOW) -synth xst_mixed.opt $<

$(BITFILE): $(NGCFILE) $(UCFFILE)
	cp $(UCFFILE) $(WORKDIR)
	$(XFLOW) -implement balanced.opt -config bitgen.opt $<
