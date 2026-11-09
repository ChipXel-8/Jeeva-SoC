OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x80000000, LENGTH = 32K
    DMEM (rw)  : ORIGIN = 0x80008000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        *(.text*)
    } > IMEM

    .rodata :
    {
        *(.rodata*)
    } > DMEM

    .data :
    {
        *(.data*)
    } > DMEM

    .sdata :
    {
        *(.sdata*)
    } > DMEM

    .bss :
    {
        *(.bss*)
        *(COMMON)
    } > DMEM

    .user_stack :
    {
        *(.user_stack*)
    } > DMEM

    .kernel_stack :
    {
        *(.kernel_stack*)
    } > DMEM
}
