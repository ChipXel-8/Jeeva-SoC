#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MIP CSR TOGGLE COVERAGE TEST
     *
     * CSR address:
     *     MIP = 0x344
     *
     * Goal:
     *     mip[31:0] : 0 -> 1 -> 0
     *
     * This covers:
     *
     *     0L->1H
     *     1H->0L
     *
     * for every bit mip[0] through mip[31].
     * ============================================================
     */

    /*
     * ------------------------------------------------------------
     * Step 1: Write all 1s
     *
     * mip = 0xFFFFFFFF
     *
     * Every bit:
     *
     *     0 -> 1
     * ------------------------------------------------------------
     */

    value = 0xFFFFFFFF;

    asm volatile(
        "csrw 0x344, %0\n"
        :
        : "r"(value)
        : "memory"
    );


    /*
     * Read back MIP.
     * This also prevents the test from being optimized away.
     */

    asm volatile(
        "csrr %0, 0x344\n"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;


    /*
     * ------------------------------------------------------------
     * Step 2: Write all 0s
     *
     * mip = 0x00000000
     *
     * Every bit:
     *
     *     1 -> 0
     * ------------------------------------------------------------
     */

    value = 0x00000000;

    asm volatile(
        "csrw 0x344, %0\n"
        :
        : "r"(value)
        : "memory"
    );


    /*
     * Read back MIP.
     */

    asm volatile(
        "csrr %0, 0x344\n"
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
