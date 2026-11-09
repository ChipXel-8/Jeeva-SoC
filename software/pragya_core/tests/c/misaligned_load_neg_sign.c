#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void test_negative_halfword(void)
{
    volatile int16_t value;

    /*
     * 0x8001 is a negative signed 16-bit value.
     *
     * Address is odd -> misaligned LH.
     */
    value =
        *(volatile int16_t *)&memory_area[1];

    sink = (uint32_t)value;
}

int main(void)
{
    memory_area[0] = 0xAA;
    memory_area[1] = 0x01;
    memory_area[2] = 0x80;
    memory_area[3] = 0x55;

    test_negative_halfword();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}