#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void aligned_accesses(void)
{
    volatile uint16_t h;
    volatile uint32_t w;

    /*
     * Properly aligned LH.
     */
    h = *(volatile uint16_t *)&memory_area[0];

    /*
     * Properly aligned LW.
     */
    w = *(volatile uint32_t *)&memory_area[0];

    /*
     * Properly aligned SH.
     */
    *(volatile uint16_t *)&memory_area[4] = 0x1234;

    /*
     * Properly aligned SW.
     */
    *(volatile uint32_t *)&memory_area[8] = 0x12345678;

    sink = h;
    sink ^= w;
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 16; i++)
        memory_area[i] = (uint8_t)i;

    aligned_accesses();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}