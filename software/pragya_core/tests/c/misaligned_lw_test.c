#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_lw_offset1(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[1];

    /*
     * LW at address:
     *
     * base + 1
     *
     * address[1:0] = 01
     */
    sink = *p;
}

int main(void)
{
    memory_area[0] = 0x11;
    memory_area[1] = 0x22;
    memory_area[2] = 0x33;
    memory_area[3] = 0x44;
    memory_area[4] = 0x55;

    misaligned_lw_offset1();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}