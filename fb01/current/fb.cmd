# $Id: fb.cmd 18 2005-11-26 21:13:23Z yaegashi $
# This script generates an SVF file for the openwince jtag utility.

setmode -bsfile
adddevice -p 1 -sprom xcf02s -file work/export/fb.mcs
setcable -p svf -file work/export/fb.svf
program -e -p 1
quit
