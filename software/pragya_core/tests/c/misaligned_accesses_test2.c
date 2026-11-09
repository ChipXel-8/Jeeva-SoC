#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void byte_accesses(void)
{
    volatile uint8_t a;
    volatile uint8_t b;

    /*
     * LB at odd address.
     *
     * This is LEGAL because byte accesses
     * have no alignment restriction.
     */
    a = *(volatile int8_t *)&memory_area[1];

    /*
     * LBU at odd address.
     */
    b = memory_area[3];

    /*
     * SB at odd address.
     */
    memory_area[5] = 0xAA;

    sink = a;
    sink ^= b;
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 16; i++)
        memory_area[i] = (uint8_t)(0x80 + i);

    byte_accesses();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}