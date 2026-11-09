#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL - CAUSE[2] TOGGLE TEST
     *
     * Sequence:
     *
     *   MCAUSE = 4  -> cause[2] = 1
     *   MCAUSE = 3  -> cause[2] = 0
     *
     * This should produce:
     *
     *   cause_out[2] : 0 -> 1 -> 0
     * ============================================================
     */

    /* Normal operation */
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
     * Misaligned LOAD
     *
     * MCAUSE = 4 = 0100
     * cause[2] = 1
     * ------------------------------------------------------------
     */
    asm volatile(
        "li x5, 0x80008001\n"
        "lw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    /*
     * Handler must MRET and skip the faulting instruction.
     */

    /* Normal instruction */
    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /*
     * ------------------------------------------------------------
     * EBREAK
     *
     * MCAUSE = 3 = 0011
     * cause[2] = 0
     * ------------------------------------------------------------
     */
    asm volatile(
        "ebreak\n"
        :
        :
        : "memory"
    );

    /*
     * cause[2] should now have:
     *
     *       1 -> 0
     */

    asm volatile(
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "mv %0, x7"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}