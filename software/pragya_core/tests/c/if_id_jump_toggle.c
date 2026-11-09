#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((noinline))
static uint32_t function_a(uint32_t x)
{
    x = x + 0x11111111;
    x = x ^ 0xAAAAAAAA;

    return x;
}

__attribute__((noinline))
static uint32_t function_b(uint32_t x)
{
    x = x + 0x22222222;
    x = x ^ 0x55555555;

    return x;
}

__attribute__((noinline))
static uint32_t function_c(uint32_t x)
{
    x = x + 0x33333333;
    x = x ^ 0xFFFFFFFF;

    return x;
}

int main(void)
{
    volatile uint32_t i;
    uint32_t result;

    for (i = 0; i < 64; i++)
    {
        result = function_a(i);
        sink = result;

        result = function_b(result);
        sink = result;

        result = function_c(result);
        sink = result;
    }

    /*
     * Variable function calls cause different JALR targets.
     */
    for (i = 0; i < 32; i++)
    {
        if (i & 1)
            result = function_a(i);
        else
            result = function_b(i);

        sink = result;
    }

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}