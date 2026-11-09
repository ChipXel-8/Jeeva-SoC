#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * ALU OUTPUT TRANSITION TEST
     *
     * Deliberately alternate between:
     *
     * 00000000
     * FFFFFFFF
     * AAAAAAAA
     * 55555555
     * 80000000
     * 7FFFFFFF
     * ============================================================
     */

    asm volatile(

        /*
         * ADD output transitions
         */
        "li x5, 0\n"
        "li x6, 0\n"
        "add x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0\n"
        "add x7, x5, x6\n"

        "li x5, 0xAAAAAAAA\n"
        "li x6, 0\n"
        "add x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0\n"
        "add x7, x5, x6\n"

        /*
         * AND output transitions
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        "li x5, 0\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        "li x5, 0xAAAAAAAA\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        /*
         * OR output transitions
         */
        "li x5, 0\n"
        "li x6, 0\n"
        "or x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0\n"
        "or x7, x5, x6\n"

        "li x5, 0xAAAAAAAA\n"
        "li x6, 0\n"
        "or x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0\n"
        "or x7, x5, x6\n"

        /*
         * XOR output transitions
         */
        "li x5, 0\n"
        "li x6, 0\n"
        "xor x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0\n"
        "xor x7, x5, x6\n"

        "li x5, 0xAAAAAAAA\n"
        "li x6, 0\n"
        "xor x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0\n"
        "xor x7, x5, x6\n"

        /*
         * Shift output transitions
         */
        "li x5, 0x80000000\n"
        "li x6, 0\n"
        "srl x7, x5, x6\n"

        "li x6, 1\n"
        "srl x7, x5, x6\n"

        "li x6, 31\n"
        "srl x7, x5, x6\n"

        "li x5, 1\n"
        "li x6, 0\n"
        "sll x7, x5, x6\n"

        "li x6, 31\n"
        "sll x7, x5, x6\n"

        /*
         * SRA output transitions
         */
        "li x5, 0x80000000\n"

        "li x6, 0\n"
        "sra x7, x5, x6\n"

        "li x6, 1\n"
        "sra x7, x5, x6\n"

        "li x6, 31\n"
        "sra x7, x5, x6\n"

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