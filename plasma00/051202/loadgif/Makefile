# $Id: Makefile 59 2005-12-01 21:40:54Z yaegashi $

CROSS_COMPILE	= mipsel-elf-
CC		= $(CROSS_COMPILE)gcc
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

loadgif.elf: entry.o main.o giftofb.o fileio.o string.o
	$(CC) -o $@ $^ $(LDFLAGS)

entry.o: entry.S
loadgif.o: main.c
