# $Id: top.cmd 48 2005-11-29 13:26:03Z yaegashi $
# This script generates an SVF file for the openwince jtag utility.

setMode -bs
setCable -port parport0 -server aragorn
Identify
setAttribute -position 2 -attr devicePartName -value "xcf02s"
setAttribute -position 2 -attr configFileName -value "xflow/top.mcs"
Program -p 2 -e 
quit
