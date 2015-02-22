OUTPUT_ARCH(mips)
ENTRY(_entry)
SECTIONS
{
  . = 0;
  .text : { entry.o(.text) *(.text) *(.rodata) }
  .data : { *(.data) }
  . = ALIGN(4);
  __bss_start = .;
  .bss : { *(.bss) *(.sbss) *(COMMON) }
  . = ALIGN(4);
  __bss_stop = .;
  __stack_start = 0x10000;
}
