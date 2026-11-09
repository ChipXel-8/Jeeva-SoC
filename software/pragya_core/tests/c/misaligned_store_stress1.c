#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[32];

__attribute__((noinline))
static void test_sw_patterns(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[1];

    *p = 0x00000000;
    *p = 0xFFFFFFFF;
    *p = 0xAAAAAAAA;
    *p = 0x55555555;
    *p = 0x80000000;
    *p = 0x7FFFFFFF;
    *p = 0x12345678;
    *p = 0xDEADBEEF;

    sink = memory_area[1];
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 32; i++)
        memory_area[i] = 0xCC;

    test_sw_patterns();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}