/* $Id: entry.S 57 2005-12-01 18:48:53Z yaegashi $ */

	.text
	.set	noreorder
	.global	__bss_start
	.global __bss_stop
	.global __stack_start
	.global _entry
	.global _exception
	.global trap_low
	.global main

	.ent	_entry
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
	j	0b
	 nop
	.end	_entry

	.org	0x180
	.ent	_exception
_exception:
	la	$26, trap_low
	jr	$26
	 nop
	.end	_exception
