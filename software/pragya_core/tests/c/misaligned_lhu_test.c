#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_lhu(void)
{
    volatile uint16_t *p;

    p = (volatile uint16_t *)&memory_area[1];

    /*
     * LHU
     *
     * funct3 = 101
     * address[0] = 1
     */
    sink = *p;
}

int main(void)
{
    memory_area[0] = 0x80;
    memory_area[1] = 0x01;
    memory_area[2] = 0xFE;
    memory_area[3] = 0x7F;

    misaligned_lhu();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}