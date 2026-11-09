#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((noinline))
static void block_a(void)
{
    volatile uint32_t a = 0xAAAAAAAA;

    a = a + 0x11111111;
    a = a ^ 0x55555555;
    a = a + 0x12345678;

    sink = a;
}

__attribute__((noinline))
static void block_b(void)
{
    volatile uint32_t a = 0x55555555;

    a = a + 0x22222222;
    a = a ^ 0xAAAAAAAA;
    a = a + 0x87654321;

    sink = a;
}

int main(void)
{
    volatile uint32_t i;
    volatile uint32_t value;

    /* Normal sequential execution */
    for (i = 0; i < 128; i++)
    {
        value = i;
        value = value + 4;
        value = value ^ 0xAAAAAAAA;
        value = value + 0x1234;
        value = value ^ 0x55555555;

        sink = value;
    }

    /* Function calls */
    block_a();
    block_b();
    block_a();
    block_b();

    /* More sequential execution */
    for (i = 0; i < 256; i++)
    {
        value = i * 4;
        value ^= 0xFFFFFFFF;
        value += 0x1000;

        sink = value;
    }

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}