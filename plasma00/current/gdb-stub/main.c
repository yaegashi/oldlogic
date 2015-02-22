/* $Id: main.c 57 2005-12-01 18:48:53Z yaegashi $ */

#include "gdb-stub.h"
#include "string.h"

int main(void)
{
	struct gdb_regs regs;
	memset(&regs, 0, sizeof(regs));
	set_debug_traps();
	breakpoint();
	return 0;
}
