OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
    DMEM (rwx) : ORIGIN = 0x00008000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        *(.text*)
        . = ALIGN(4);
    } > IMEM

    .rodata :
    {
        . = ALIGN(4);
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(4);
    } > DMEM

    .data :
    {
        . = ALIGN(4);
        *(.data*)
        . = ALIGN(4);
    } > DMEM

    .sdata :
    {
        . = ALIGN(4);
        *(.sdata*)
        . = ALIGN(4);
    } > DMEM

    .bss :
    {
        . = ALIGN(4);
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
    } > DMEM

    .user_stack :
    {
        . = ALIGN(4);
        *(.user_stack*)
        . = ALIGN(4);
    } > DMEM

    .kernel_stack :
    {
        . = ALIGN(4);
        *(.kernel_stack*)
        . = ALIGN(4);
    } > DMEM
}
