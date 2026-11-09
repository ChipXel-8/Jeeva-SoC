#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * PIPELINE2 REGISTER TOGGLE TEST
     *
     * Purpose:
     *
     *   Exercise large portions of the DE -> MW pipeline register
     *   with different operand/result/PC/instruction patterns.
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Pattern 1
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0xAAAAAAAA\n"
        "li x6,  0x55555555\n"
        "add x7, x5, x6\n"
        "xor x8, x5, x6\n"
        "and x9, x5, x6\n"
        "or  x10, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 2
     *
     * Opposite bit pattern.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0x55555555\n"
        "li x6,  0xAAAAAAAA\n"
        "sub x7, x5, x6\n"
        "xor x8, x5, x6\n"
        "and x9, x5, x6\n"
        "or  x10, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 3
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000000\n"
        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "xor x9, x5, x6\n"
        "and x10, x5, x6\n"
        "or x11, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 4
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"
        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "xor x9, x5, x6\n"
        "and x10, x5, x6\n"
        "or x11, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 5
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80000000\n"
        "li x6, 0x7FFFFFFF\n"
        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "xor x9, x5, x6\n"
        "and x10, x5, x6\n"
        "or x11, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 6
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0x80000000\n"
        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "xor x9, x5, x6\n"
        "and x10, x5, x6\n"
        "or x11, x5, x6\n"
        :
        :
        : "memory"
    );


    asm volatile(
        "mv %0, x11"
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