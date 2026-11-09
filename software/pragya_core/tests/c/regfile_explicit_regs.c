#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ========================================================
     * REGISTER FILE WRITE ADDRESS COVERAGE
     *
     * Explicitly write x1-x31.
     * Avoid x2/x8 where possible because startup uses them
     * as stack/frame-pointer registers.
     * ========================================================
     */

    asm volatile(
        "li x1,  0x11111111\n"
        "li x3,  0x33333333\n"
        "li x4,  0x44444444\n"
        "li x5,  0x55555555\n"
        "li x6,  0x66666666\n"
        "li x7,  0x77777777\n"

        "li x9,  0x99999999\n"
        "li x10, 0xAAAAAAAA\n"
        "li x11, 0xBBBBBBBB\n"
        "li x12, 0xCCCCCCCC\n"
        "li x13, 0xDDDDDDDD\n"
        "li x14, 0xEEEEEEEE\n"
        "li x15, 0xFFFFFFFF\n"

        "li x16, 0x12345678\n"
        "li x17, 0x23456789\n"
        "li x18, 0x3456789A\n"
        "li x19, 0x456789AB\n"
        "li x20, 0x56789ABC\n"
        "li x21, 0x6789ABCD\n"
        "li x22, 0x789ABCDE\n"
        "li x23, 0x89ABCDEF\n"
        "li x24, 0xABCDEF01\n"
        "li x25, 0xBCDEF012\n"
        "li x26, 0xCDEF0123\n"
        "li x27, 0xDEF01234\n"
        "li x28, 0xEF012345\n"
        "li x29, 0xF0123456\n"
        "li x30, 0x01234567\n"
        "li x31, 0x89ABCDEF\n"
        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * REGISTER FILE READ ADDRESS COVERAGE
     * ========================================================
     */

    asm volatile(
        "add x3,  x1,  x4\n"
        "add x5,  x6,  x7\n"
        "add x9,  x10, x11\n"
        "add x12, x13, x14\n"
        "add x15, x16, x17\n"
        "add x18, x19, x20\n"
        "add x21, x22, x23\n"
        "add x24, x25, x26\n"
        "add x27, x28, x29\n"
        "add x30, x31, x1\n"
        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * READ x0
     *
     * Exercises:
     *
     * rs_1_addrs_in == 0
     * rs_2_addrs_in == 0
     * ========================================================
     */

    asm volatile(
        "add x3, x0, x1\n"
        "add x4, x1, x0\n"
        "add x5, x0, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * DIFFERENT REGISTER ADDRESS PATTERNS
     *
     * 00001
     * 00010
     * 00100
     * 01000
     * 10000
     * 11111
     * ========================================================
     */

    asm volatile(
        "add x1,  x2,  x4\n"
        "add x3,  x8,  x16\n"
        "add x5,  x16, x31\n"
        "add x6,  x31, x8\n"
        :
        :
        : "memory"
    );


    /*
     * Put a final value into a C variable.
     */
    asm volatile(
        "mv %0, x6"
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