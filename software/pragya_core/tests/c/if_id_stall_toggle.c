#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t memory_value = 0x12345678;
volatile uint32_t sink;

__attribute__((noinline))
static uint32_t load_then_use(void)
{
    uint32_t a;
    uint32_t b;

    /*
     * Load followed immediately by dependent operation.
     *
     * This is intended to exercise the pipeline hazard
     * path that can generate stall_d.
     */
    a = memory_value;

    b = a + 0x11111111;

    return b;
}

__attribute__((noinline))
static uint32_t load_chain(void)
{
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;

    a = memory_value;
    b = a + 1;
    c = b + 2;
    d = c + 3;

    return d;
}

int main(void)
{
    volatile uint32_t i;
    uint32_t result;

    /*
     * Repeated load-use sequences.
     */
    for (i = 0; i < 32; i++)
    {
        result = load_then_use();
        sink = result;
    }

    /*
     * Longer dependency chain.
     */
    for (i = 0; i < 32; i++)
    {
        result = load_chain();
        sink = result;
    }

    /*
     * Alternating independent/dependent instructions.
     */
    for (i = 0; i < 64; i++)
    {
        uint32_t a;
        uint32_t b;

        a = memory_value;

        if (i & 1)
            b = a + 0xAAAAAAAA;
        else
            b = a ^ 0x55555555;

        sink = b;
    }

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}