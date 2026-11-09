#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_sw_offset2(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[2];

    /*
     * address[1:0] = 10
     */
    *p = 0xDEADBEEF;

    sink = memory_area[2];
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 16; i++)
        memory_area[i] = 0x55;

    misaligned_sw_offset2();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}