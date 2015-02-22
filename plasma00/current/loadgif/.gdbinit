# $Id: .gdbinit 62 2005-12-11 16:40:29Z yaegashi $

# The device file is like /dev/com4 in cygwin.
set remotebaud 57600
target remote /dev/ttyUSB0
load

# Macro definition for the presentation.
define slide
load slides/slide$arg0.elf
jump *0x10000
end
