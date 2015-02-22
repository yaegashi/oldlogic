# $Id: top.cmd 62 2005-12-11 16:40:29Z yaegashi $

setMode -bs

# Connect to a local JTAG cable.
# setCable -port parport0

# Connect to a cable on a remote computer (Run CableServer).
setCable -port parport0 -server aragorn

Identify
setAttribute -position 2 -attr devicePartName -value "xcf02s"
setAttribute -position 2 -attr configFileName -value "xflow/top.mcs"
Program -p 2 -e 
quit
