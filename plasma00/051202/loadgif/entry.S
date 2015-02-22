	.text
	.global	__bss_start
	.global __bss_stop
	.global __stack_start
	.global _entry
	.global breakpoint
	.global main
	.ent	_entry
	.set	noreorder
_entry:
	nop
	nop
0:
	la	$8, __bss_start
	la	$9, __bss_stop
	beq	$8, $9, 2f
	 nop
1:
	sw	$0, ($8)
	addi	$8, $8, 4
	bne	$8, $9, 1b
	 nop
2:
	la	$8, main
	la	$29, __stack_start
	jal	$8
	 nop
	li	$26, 0x180
	jr	$26
	 nop
	.end	_entry

	.ent	breakpoint
breakpoint:
	j	0x180
	.end	breakpoint
