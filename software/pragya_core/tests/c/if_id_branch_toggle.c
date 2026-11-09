#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    volatile uint32_t i;
    volatile uint32_t a;

    a = 0;

    /*
     * BEQ/BNE-style branches.
     */
    for (i = 0; i < 128; i++)
    {
        if (i == 0)
            a += 1;

        if (i == 1)
            a += 2;

        if (i == 2)
            a += 4;

        if (i == 4)
            a += 8;

        if (i == 8)
            a += 16;

        if (i & 1)
            a ^= 0xAAAAAAAA;
        else
            a ^= 0x55555555;
    }

    /*
     * Nested branches.
     */
    for (i = 0; i < 64; i++)
    {
        if (i < 16)
        {
            if (i & 1)
                a += 3;
            else
                a += 5;
        }
        else
        {
            if (i & 2)
                a += 7;
            else
                a += 9;
        }
    }

    sink = a;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}