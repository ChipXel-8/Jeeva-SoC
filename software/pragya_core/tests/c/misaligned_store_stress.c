#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[32];

__attribute__((noinline))
static void test_sh_patterns(void)
{
    volatile uint16_t *p;

    p = (volatile uint16_t *)&memory_area[1];

    *p = 0x0000;
    *p = 0xFFFF;
    *p = 0xAAAA;
    *p = 0x5555;
    *p = 0x8000;
    *p = 0x7FFF;

    sink = memory_area[1];
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 32; i++)
        memory_area[i] = 0xCC;

    test_sh_patterns();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}