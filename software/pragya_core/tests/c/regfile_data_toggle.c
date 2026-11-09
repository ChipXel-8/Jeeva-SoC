#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * REGFILE DATA TOGGLE COVERAGE
     *
     * Purpose:
     *   Exercise different data patterns through the register file.
     *
     * IMPORTANT:
     *
     *   DO NOT MODIFY:
     *
     *       x1 = ra
     *       x2 = sp
     *       x3 = gp
     *       x4 = tp
     *       x8 = s0/fp
     *
     *   These registers are used by the C runtime / function calls.
     *
     *   We use temporary registers only.
     * ============================================================
     */


    /*
     * ============================================================
     * Pattern 1
     *
     * 1010... / 0101...
     * ============================================================
     */

    asm volatile(
        "li x5,  0xAAAAAAAA\n"
        "li x6,  0x55555555\n"
        "add x7,  x5, x6\n"

        "li x9,  0xAAAAAAAA\n"
        "li x10, 0x55555555\n"
        "xor x11, x9, x10\n"

        "li x12, 0xAAAAAAAA\n"
        "li x13, 0x55555555\n"
        "or  x14, x12, x13\n"

        "li x15, 0xAAAAAAAA\n"
        "li x16, 0x55555555\n"
        "and x17, x15, x16\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * Pattern 2
     *
     * All 1s / all 0s
     * ============================================================
     */

    asm volatile(
        "li x5,  0xFFFFFFFF\n"
        "li x6,  0x00000000\n"
        "xor x7,  x5, x6\n"

        "li x9,  0xFFFFFFFF\n"
        "li x10, 0x00000000\n"
        "and x11, x9, x10\n"

        "li x12, 0xFFFFFFFF\n"
        "li x13, 0x00000000\n"
        "or  x14, x12, x13\n"

        "li x15, 0xFFFFFFFF\n"
        "li x16, 0x00000000\n"
        "add x17, x15, x16\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * Pattern 3
     *
     * 0xAAAAAAAA <-> 0x55555555
     * ============================================================
     */

    asm volatile(
        "li x5,  0x55555555\n"
        "li x6,  0xAAAAAAAA\n"
        "add x7,  x5, x6\n"

        "li x9,  0x55555555\n"
        "li x10, 0xAAAAAAAA\n"
        "sub x11, x9, x10\n"

        "li x12, 0x55555555\n"
        "li x13, 0xAAAAAAAA\n"
        "xor x14, x12, x13\n"

        "li x15, 0x55555555\n"
        "li x16, 0xAAAAAAAA\n"
        "or  x17, x15, x16\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * Pattern 4
     *
     * 0x00000000 -> 0xFFFFFFFF -> 0xAAAAAAAA
     * ============================================================
     */

    asm volatile(
        "li x5,  0x00000000\n"
        "li x6,  0xFFFFFFFF\n"
        "xor x7,  x5, x6\n"

        "li x9,  0xAAAAAAAA\n"
        "li x10, 0x00000000\n"
        "xor x11, x9, x10\n"

        "li x12, 0xFFFFFFFF\n"
        "li x13, 0xAAAAAAAA\n"
        "and x14, x12, x13\n"

        "li x15, 0x00000000\n"
        "li x16, 0x55555555\n"
        "or  x17, x15, x16\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * Pattern 5
     *
     * Exercise different register addresses.
     *
     * rd changes while rs1/rs2 remain valid.
     * ============================================================
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"

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
        "add x27, x5, x0\n        "
        "add x28, x5, x0\n"
        "add x29, x5, x0\n"
        "add x30, x5, x0\n"
        "add x31, x5, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * Pattern 6
     *
     * Exercise different rs1 addresses.
     * x0 is used as rs2.
     * ============================================================
     */

    asm volatile(
        "add x5, x6,  x0\n"
        "add x5, x7,  x0\n"
        "add x5, x9,  x0\n"
        "add x5, x10, x0\n"
        "add x5, x11, x0\n"
        "add x5, x12, x0\n"
        "add x5, x13, x0\n"
        "add x5, x14, x0\n"
        "add x5, x15, x0\n"
        "add x5, x16, x0\n"
        "add x5, x17, x0\n"
        "add x5, x18, x0\n"
        "add x5, x19, x0\n"
        "add x5, x20, x0\n"
        "add x5, x21, x0\n"
        "add x5, x22, x0\n"
        "add x5, x23, x0\n"
        "add x5, x24, x0\n"
        "add x5, x25, x0\n"
        "add x5, x26, x0\n"
        "add x5, x27, x0\n"
        "add x5, x28, x0\n"
        "add x5, x29, x0\n"
        "add x5, x30, x0\n"
        "add x5, x31, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * Pattern 7
     *
     * Exercise different rs2 addresses.
     * x0 is used as rs1.
     * ============================================================
     */

    asm volatile(
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
     * x0 READ TEST
     *
     * x0 must always return zero.
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