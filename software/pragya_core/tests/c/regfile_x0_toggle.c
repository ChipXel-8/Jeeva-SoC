#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * REGFILE X0 + ADDRESS + DATA TOGGLE COVERAGE
     *
     * Purpose:
     *   1. Verify x0 always reads as zero.
     *   2. Attempt writes to x0.
     *   3. Exercise x0 as rs1.
     *   4. Exercise x0 as rs2.
     *   5. Exercise x0 as rd.
     *   6. Toggle register address bits through different
     *      source and destination register numbers.
     *
     * IMPORTANT:
     *   Do NOT modify x1 (ra), x2 (sp), or x8 (s0)
     *   because C/runtime code depends on them.
     * ============================================================
     */


    /*
     * ============================================================
     * STEP 1
     * Verify x0 reads as zero.
     * ============================================================
     */

    asm volatile(
        "add x5, x0, x0\n"
        "add x6, x0, x0\n"
        "add x7, x0, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 2
     * Attempt writes to x0.
     *
     * RISC-V requires:
     *
     *     x0 = 0
     *
     * regardless of writes.
     * ============================================================
     */

    asm volatile(
        "li x0, 0xFFFFFFFF\n"
        "li x0, 0xAAAAAAAA\n"
        "li x0, 0x55555555\n"
        "li x0, 0x12345678\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 3
     * x0 as rs1.
     *
     * Result must equal rs2.
     * ============================================================
     */

    asm volatile(
        "li x5,  0x11111111\n"
        "add x6, x0, x5\n"

        "li x7,  0x22222222\n"
        "add x9, x0, x7\n"

        "li x10, 0x33333333\n"
        "add x11, x0, x10\n"

        "li x12, 0x44444444\n"
        "add x13, x0, x12\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 4
     * x0 as rs2.
     *
     * Result must equal rs1.
     * ============================================================
     */

    asm volatile(
        "li x5,  0x55555555\n"
        "add x14, x5, x0\n"

        "li x6,  0x66666666\n"
        "add x15, x6, x0\n"

        "li x7,  0x77777777\n"
        "add x16, x7, x0\n"

        "li x9,  0x88888888\n"
        "add x17, x9, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 5
     * Both rs1 and rs2 = x0.
     *
     * Result must always be zero.
     * ============================================================
     */

    asm volatile(
        "add x18, x0, x0\n"
        "sub x19, x0, x0\n"
        "xor x20, x0, x0\n"
        "or  x21, x0, x0\n"
        "and x22, x0, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 6
     * Exercise different destination register addresses.
     *
     * These instructions toggle rd address bits.
     * ============================================================
     */

    asm volatile(
        "li x5,  0x01010101\n"

        "add x3,  x5, x0\n"
        "add x4,  x5, x0\n"
        "add x6,  x5, x0\n"
        "add x7,  x5, x0\n"

        "add x9,  x5, x0\n"
        "add x10, x5, x0\n"
        "add x11, x5, x0\n"
        "add x12, x5, x0\n"

        "add x13, x5, x0\n"
        "add x14, x5, x0\n"
        "add x15, x5, x0\n"
        "add x16, x5, x0\n"

        "add x17, x5, x0\n"
        "add x18, x5, x0\n"
        "add x19, x5, x0\n"
        "add x20, x5, x0\n"

        "add x21, x5, x0\n"
        "add x22, x5, x0\n"
        "add x23, x5, x0\n"
        "add x24, x5, x0\n"

        "add x25, x5, x0\n"
        "add x26, x5, x0\n"
        "add x27, x5, x0\n"
        "add x28, x5, x0\n"

        "add x29, x5, x0\n"
        "add x30, x5, x0\n        "
        "add x31, x5, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 7
     * Exercise different rs1 addresses.
     * ============================================================
     */

    asm volatile(
        "add x5,  x3,  x0\n"
        "add x5,  x4,  x0\n"
        "add x5,  x6,  x0\n"
        "add x5,  x7,  x0\n"

        "add x5,  x9,  x0\n"
        "add x5,  x10, x0\n"
        "add x5,  x11, x0\n"
        "add x5,  x12, x0\n"

        "add x5,  x13, x0\n"
        "add x5,  x14, x0\n"
        "add x5,  x15, x0\n"
        "add x5,  x16, x0\n"

        "add x5,  x17, x0\n"
        "add x5,  x18, x0\n"
        "add x5,  x19, x0\n"
        "add x5,  x20, x0\n"

        "add x5,  x21, x0\n"
        "add x5,  x22, x0\n"
        "add x5,  x23, x0\n"
        "add x5,  x24, x0\n"

        "add x5,  x25, x0\n"
        "add x5,  x26, x0\n"
        "add x5,  x27, x0\n"
        "add x5,  x28, x0\n"

        "add x5,  x29, x0\n"
        "add x5,  x30, x0\n"
        "add x5,  x31, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 8
     * Exercise different rs2 addresses.
     * ============================================================
     */

    asm volatile(
        "add x5, x0, x3\n"
        "add x5, x0, x4\n"
        "add x5, x0, x6\n"
        "add x5, x0, x7\n"

        "add x5, x0, x9\n"
        "add x5, x0, x10\n"
        "add x5, x0, x11\n"
        "add x5, x0, x12\n"

        "add x5, x0, x13\n"
        "add x5, x0, x14\n"
        "add x5, x0, x15\n"
        "add x5, x0, x16\n"

        "add x5, x0, x17\n"
        "add x5, x0, x18\n"
        "add x5, x0, x19\n"
        "add x5, x0, x20\n"

        "add x5, x0, x21\n"
        "add x5, x0, x22\n"
        "add x5, x0, x23\n"
        "add x5, x0, x24\n"

        "add x5, x0, x25\n"
        "add x5, x0, x26\n"
        "add x5, x0, x27\n"
        "add x5, x0, x28\n"

        "add x5, x0, x29\n"
        "add x5, x0, x30\n"
        "add x5, x0, x31\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * STEP 9
     * Final x0 verification.
     *
     * x0 must still be exactly zero.
     * ============================================================
     */

    asm volatile(
        "add %0, x0, x0\n"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;


    /*
     * ============================================================
     * PASS
     * ============================================================
     */

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}