OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x80000000, LENGTH = 32K
    DMEM (rwx) : ORIGIN = 0x80008000, LENGTH = 32K
}

SECTIONS
{
    /* =========================================================
     * INSTRUCTION MEMORY
     * ========================================================= */

    .text :
    {
        . = ALIGN(4);

        KEEP(*(.text.start))
        KEEP(*(.text.trap))

        *(.text)
        *(.text.*)

        . = ALIGN(4);
    } > IMEM


    .rodata :
    {
        . = ALIGN(4);

        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)

        . = ALIGN(4);
    } > IMEM


    /* =========================================================
     * DATA MEMORY
     * ========================================================= */

    .data :
    {
        . = ALIGN(4);

        _sdata = .;
        __data_start = .;

        *(.data)
        *(.data.*)

        . = ALIGN(4);

        /*
         * Global pointer used by startup.S.
         */
        __global_pointer$ = . + 0x800;

        *(.sdata)
        *(.sdata.*)

        . = ALIGN(4);

        _edata = .;
        __data_end = .;
    } > DMEM


    /* =========================================================
     * BSS
     * ========================================================= */

    .bss (NOLOAD) :
    {
        . = ALIGN(4);

        _sbss = .;
        __bss_start = .;

        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)

        . = ALIGN(4);

        _ebss = .;
        __bss_end = .;
    } > DMEM


    /* =========================================================
     * VERIFICATION SIGNATURE
     * ========================================================= */

    .signature (NOLOAD) :
    {
        . = ALIGN(16);

        _signature_start = .;
        __signature_start = .;

        /*
         * Reserve 256 bytes for test/trap results.
         */
        . = . + 0x100;

        _signature_end = .;
        __signature_end = .;
    } > DMEM


    /* =========================================================
     * STACK
     * ========================================================= */

    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
    __stack_top = _stack_top;


    /* =========================================================
     * MEMORY BOUNDARIES
     * ========================================================= */

    __imem_start = ORIGIN(IMEM);
    __imem_end   = ORIGIN(IMEM) + LENGTH(IMEM);

    __dmem_start = ORIGIN(DMEM);
    __dmem_end   = ORIGIN(DMEM) + LENGTH(DMEM);

    _end = __bss_end;
}
