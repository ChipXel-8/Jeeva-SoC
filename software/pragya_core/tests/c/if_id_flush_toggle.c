#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((noinline))
static void target_a(void)
{
    volatile uint32_t x = 0xAAAAAAAA;

    x ^= 0x55555555;
    x += 0x12345678;

    sink = x;
}

__attribute__((noinline))
static void target_b(void)
{
    volatile uint32_t x = 0x55555555;

    x ^= 0xAAAAAAAA;
    x += 0x87654321;

    sink = x;
}

int main(void)
{
    volatile uint32_t i;

    /*
     * Forward branches.
     */
    for (i = 0; i < 64; i++)
    {
        if (i == 4)
            target_a();

        if (i == 16)
            target_b();

        sink = i;
    }

    /*
     * Alternating branch paths.
     */
    for (i = 0; i < 128; i++)
    {
        if (i & 1)
        {
            target_a();
        }
        else
        {
            target_b();
        }
    }

    /*
     * Nested branches.
     */
    for (i = 0; i < 64; i++)
    {
        if (i & 1)
        {
            if (i & 2)
                target_a();
            else
                target_b();
        }
        else
        {
            sink = i;
        }
    }

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}