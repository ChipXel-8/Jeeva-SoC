#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * PMPADDR16 CSR TOGGLE COVERAGE TEST
     *
     * CSR address:
     *     PMPADDR16 = 0x3C0
     *
     * Goal:
     *     pmpaddr16[31:0] : 0 -> 1 -> 0
     *
     * This covers:
     *
     *     0L->1H
     *     1H->0L
     *
     * for every bit pmpaddr16[0] through pmpaddr16[31].
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Step 1: Write all 1s
     *
     * pmpaddr16 = 0xFFFFFFFF
     *
     * Every bit:
     *
     *     0 -> 1
     * ------------------------------------------------------------
     */

    value = 0xFFFFFFFF;

    asm volatile(
        "csrw 0x3C0, %0\n"
        :
        : "r"(value)
        : "memory"
    );


    /*
     * Read back PMPADDR16.
     */

    asm volatile(
        "csrr %0, 0x3C0\n"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;


    /*
     * ------------------------------------------------------------
     * Step 2: Write all 0s
     *
     * pmpaddr16 = 0x00000000
     *
     * Every bit:
     *
     *     1 -> 0
     * ------------------------------------------------------------
     */

    value = 0x00000000;

    asm volatile(
        "csrw 0x3C0, %0\n"
        :
        : "r"(value)
        : "memory"
    );


    /*
     * Read back PMPADDR16.
     */

    asm volatile(
        "csrr %0, 0x3C0\n"
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
