#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_sw_offset3(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[3];

    /*
     * address[1:0] = 11
     */
    *p = 0xCAFEBABE;

    sink = memory_area[3];
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 16; i++)
        memory_area[i] = 0xCC;

    misaligned_sw_offset3();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}