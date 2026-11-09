#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_lh_offset1(void)
{
    volatile uint16_t *p;

    /*
     * Base address is 4-byte aligned.
     *
     * +1 makes the address odd:
     *
     * address[0] = 1
     *
     * LH requires 2-byte alignment.
     */
    p = (volatile uint16_t *)&memory_area[1];

    sink = *p;
}

int main(void)
{
    memory_area[0] = 0x11;
    memory_area[1] = 0x22;
    memory_area[2] = 0x33;
    memory_area[3] = 0x44;

    /*
     * Generates:
     *
     * LH x?, 1(x?)
     *
     * funct3 = 001
     * address[0] = 1
     */
    misaligned_lh_offset1();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}