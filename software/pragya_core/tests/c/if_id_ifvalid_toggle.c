#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((noinline))
static void work(void)
{
    volatile uint32_t a;

    a = 0xAAAAAAAA;
    a ^= 0x55555555;
    a += 0x12345678;

    sink = a;
}

int main(void)
{
    volatile uint32_t i;

    /*
     * Normal instructions continuously provide
     * valid instruction fetches.
     */
    for (i = 0; i < 64; i++)
    {
        sink = i;
        sink = sink ^ 0xAAAAAAAA;
        sink = sink + 1;
    }

    /*
     * Function boundaries create additional
     * fetch/control transitions.
     */
    work();
    work();

    for (i = 0; i < 64; i++)
    {
        if (i & 1)
            work();
        else
            sink = i;
    }

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}