#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_lw_offset2(void)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[2];

    /*
     * address[1:0] = 10
     */
    sink = *p;
}

int main(void)
{
    memory_area[0] = 0xAA;
    memory_area[1] = 0xBB;
    memory_area[2] = 0xCC;
    memory_area[3] = 0xDD;
    memory_area[4] = 0xEE;
    memory_area[5] = 0xFF;

    misaligned_lw_offset2();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}