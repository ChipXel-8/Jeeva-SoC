#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[64];

__attribute__((noinline))
static void dynamic_misaligned_lw(uint32_t offset)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[offset];

    sink = *p;
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 64; i++)
        memory_area[i] = (uint8_t)(i + 1);

    /*
     * Effective addresses:
     *
     * base + 1
     * base + 2
     * base + 3
     */
    dynamic_misaligned_lw(1);

    dynamic_misaligned_lw(2);

    dynamic_misaligned_lw(3);

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}