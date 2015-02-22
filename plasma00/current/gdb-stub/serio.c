/* $Id: serio.c 56 2005-11-30 21:18:16Z yaegashi $ */

#include "gdb-stub.h"

static volatile unsigned long * const serio = (unsigned long *)0x40000000;

int putDebugChar(char c)
{
	while (!(serio[1] & 1));
	serio[0] = c;
	return 1;
}

char getDebugChar(void)
{
	while (!(serio[1] & 2));
	return serio[0];
}
