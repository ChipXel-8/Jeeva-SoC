#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * ALU BIT-PATTERN STRESS TEST
     * ============================================================
     */

    asm volatile(

        /* AND patterns */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        "li x5, 0xF0F0F0F0\n"
        "li x6, 0x0F0F0F0F\n"
        "and x7, x5, x6\n"

        "li x5, 0xFF00FF00\n"
        "li x6, 0x00FF00FF\n"
        "and x7, x5, x6\n"


        /* OR patterns */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "or x7, x5, x6\n"

        "li x5, 0xF0F0F0F0\n"
        "li x6, 0x0F0F0F0F\n"
        "or x7, x5, x6\n"

        "li x5, 0xFF00FF00\n"
        "li x6, 0x00FF00FF\n"
        "or x7, x5, x6\n"


        /* XOR patterns */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"

        "li x5, 0xF0F0F0F0\n"
        "li x6, 0x0F0F0F0F\n"
        "xor x7, x5, x6\n"

        "li x5, 0xFF00FF00\n"
        "li x6, 0x00FF00FF\n"
        "xor x7, x5, x6\n"


        /* Alternating result transitions */
        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"
        "xor x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "xor x7, x5, x6\n"


        /* ADD */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "add x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0xAAAAAAAA\n"
        "add x7, x5, x6\n"

        "li x5, 0xF0F0F0F0\n"
        "li x6, 0x0F0F0F0F\n"
        "add x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "add x7, x5, x6\n"


        /* SUB */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "sub x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0xAAAAAAAA\n"
        "sub x7, x5, x6\n"

        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"
        "sub x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

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