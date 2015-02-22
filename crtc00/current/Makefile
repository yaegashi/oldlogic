# $Id: Makefile 3 2005-11-16 17:29:26Z yaegashi $

WORKDIR = work
EXPORTDIR = export

TOP = crtc
PART = xc3s200-ft256-4
XFLOW = xflow -p $(PART) -wd $(WORKDIR) -ed $(EXPORTDIR)
PRJFILE = $(TOP).prj
UCFFILE = $(TOP).ucf
NGCFILE = $(WORKDIR)/$(EXPORTDIR)/$(TOP).ngc
BITFILE = $(WORKDIR)/$(EXPORTDIR)/$(TOP).bit

all: $(BITFILE)

clean:
	rm -rf $(WORKDIR) xflow.his _impact.*

$(NGCFILE): $(PRJFILE)
	$(XFLOW) -synth xst_mixed.opt $<

$(BITFILE): $(NGCFILE) $(UCFFILE)
	cp $(UCFFILE) $(WORKDIR)
	$(XFLOW) -implement balanced.opt -config bitgen.opt $<
