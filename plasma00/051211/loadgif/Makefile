# $Id: Makefile 63 2005-12-11 17:51:14Z yaegashi $

CROSS_COMPILE	= mipsel-elf-
CC		= $(CROSS_COMPILE)gcc
GDB		= $(CROSS_COMPILE)gdb
OBJCOPY		= $(CROSS_COMPILE)objcopy

CPPFLAGS	= 
CFLAGS		= -G 0 -g -O2 -Wall
ASFLAGS		= -G 0 -g -O2 -Wall
LDFLAGS		= -G 0 -T loadgif.lds -nostdlib -nostartfiles


TARGETS = loadgif.elf

all: $(TARGETS)

clean:
	rm -f *.o
	rm -f $(TARGETS)

b2con: loadgif.elf b2con.elf
	$(GDB) -q -n -x b2con.gdb

loadgif.elf: entry.o main.o giftofb.o fileio.o string.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.elf: %.gif
	$(OBJCOPY) -I binary -O elf32-little --adjust-vma=0x80000 $< $@

entry.o: entry.S
string.o: string.c string.h
fileio.o: fileio.c fileio.h
