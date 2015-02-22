# $Id: .gdbinit 62 2005-12-11 16:40:29Z yaegashi $

set remotebaud 57600
# The device file is like /dev/com4 in cygwin.
target remote /dev/ttyUSB0
load b2con.elf
load loadgif.elf
continue
