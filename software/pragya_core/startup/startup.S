.section .text.start
.globl _start
.type _start, @function

_start:

    /* ---------------------------------------------------------
     * Initialize stack pointer
     * --------------------------------------------------------- */

    la sp, _stack_top


    /* ---------------------------------------------------------
     * Initialize global pointer
     *
     * Disable relaxation because gp must receive the exact
     * linker-generated address.
     * --------------------------------------------------------- */

    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop


    /* ---------------------------------------------------------
     * Clear BSS
     * --------------------------------------------------------- */

    la t0, _sbss
    la t1, _ebss

1:
    bgeu t0, t1, 2f

    sw zero, 0(t0)

    addi t0, t0, 4

    j 1b


2:

    /* ---------------------------------------------------------
     * Install machine-mode trap vector
     * --------------------------------------------------------- */

    la t0, trap_entry

    csrw mtvec, t0


    /* ---------------------------------------------------------
     * Call C main()
     * --------------------------------------------------------- */

    call main


    /* ---------------------------------------------------------
     * main() return value is in a0.
     *
     * Save it into the verification signature.
     * --------------------------------------------------------- */

    la t0, _signature_start

    sw a0, 0(t0)


    /* ---------------------------------------------------------
     * End of program
     *
     * Infinite loop. Testbench will later detect completion.
     * --------------------------------------------------------- */

test_done:

    j test_done


.size _start, .-_start

