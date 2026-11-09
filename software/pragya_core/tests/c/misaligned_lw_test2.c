#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_lw_offset3(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[3];

    /*
     * address[1:0] = 11
     */
    sink = *p;
}

int main(void)
{
    memory_area[0] = 0x10;
    memory_area[1] = 0x20;
    memory_area[2] = 0x30;
    memory_area[3] = 0x40;
    memory_area[4] = 0x50;
    memory_area[5] = 0x60;
    memory_area[6] = 0x70;

    misaligned_lw_offset3();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}