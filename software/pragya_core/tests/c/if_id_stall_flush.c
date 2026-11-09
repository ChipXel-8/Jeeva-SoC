#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t memory_value = 0xCAFEBABE;
volatile uint32_t sink;


__attribute__((noinline))
static uint32_t hazard_function(void)
{
    uint32_t a;
    uint32_t b;
    uint32_t c;

    a = memory_value;
    b = a + 0x11111111;
    c = b ^ 0xAAAAAAAA;

    return c;
}


__attribute__((noinline))
static void branch_function(uint32_t x)
{
    if (x & 1)
        sink = 0xAAAAAAAA;
    else
        sink = 0x55555555;
}


int main(void)
{
    volatile uint32_t i;
    uint32_t result;

    /*
     * Load-use hazards.
     */
    for (i = 0; i < 64; i++)
    {
        result = hazard_function();
        sink = result;
    }

    /*
     * Branches mixed with hazards.
     */
    for (i = 0; i < 128; i++)
    {
        result = hazard_function();

        if (result & 1)
            branch_function(i);
        else
            branch_function(i + 1);
    }

    /*
     * Repeated control-flow changes.
     */
    for (i = 0; i < 128; i++)
    {
        if (i & 1)
        {
            result = hazard_function();
            sink = result;
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