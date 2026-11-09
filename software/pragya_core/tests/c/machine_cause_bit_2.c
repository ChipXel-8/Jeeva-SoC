#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL MISALIGNED STORE TEST
     *
     * Covers:
     *
     *   NORMAL OPERATION
     *   MISALIGNED STORE
     *   TRAP TAKEN
     *   MRET
     *
     * NOTE:
     *
     * The trap handler must advance MEPC past the faulting
     * instruction. Otherwise the same SW instruction will trap
     * forever.
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Normal operation
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Misaligned store
     *
     * 0x80008001 is not word aligned.
     *
     * Expected:
     *
     *   mcause = 6
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80008001\n"
        "li x6, 0x12345678\n"
        "sw x6, 0(x5)\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * This instruction executes only if the trap handler skips
     * the faulting SW instruction.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Save result
     * ------------------------------------------------------------
     */

    asm volatile(
        "mv %0, x7"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;


    /*
     * ------------------------------------------------------------
     * PASS
     * ------------------------------------------------------------
     */

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}