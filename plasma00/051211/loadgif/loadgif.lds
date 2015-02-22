OUTPUT_ARCH(mips)
ENTRY(_entry)
SECTIONS
{
  . = 0x10000;
  .text : { entry.o(.text) *(.text) *(.rodata) }
  .data : { *(.data) }
  . = ALIGN(4);
  __bss_start = .;
  .sbss : { *(.sbss) *(.scommon) }
  .bss : { *(.bss) *(COMMON) }
  . = ALIGN(4);
  __bss_stop = .;
  __stack_start = 0xc0000;
}
