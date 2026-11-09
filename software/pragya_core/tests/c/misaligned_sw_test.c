#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_sw_offset1(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[1];

    /*
     * SW
     *
     * address[1:0] = 01
     */
    *p = 0x12345678;

    sink = memory_area[1];
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 16; i++)
        memory_area[i] = 0xAA;

    misaligned_sw_offset1();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}