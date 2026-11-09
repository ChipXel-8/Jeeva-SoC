#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_sh(void)
{
    volatile uint16_t *p;

    p = (volatile uint16_t *)&memory_area[1];

    /*
     * SH at odd address.
     *
     * funct3 = 001
     * address[0] = 1
     */
    *p = 0xA55A;

    sink = memory_area[1];
}

int main(void)
{
    memory_area[0] = 0x11;
    memory_area[1] = 0x22;
    memory_area[2] = 0x33;
    memory_area[3] = 0x44;

    misaligned_sh();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}