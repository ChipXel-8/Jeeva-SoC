#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[32];

__attribute__((noinline))
static void prepare_memory(void)
{
    for (volatile uint32_t i = 0; i < 32; i++)
        memory_area[i] = (uint8_t)(i + 1);
}

__attribute__((noinline))
static void misaligned_sequence(void)
{
    volatile uint16_t h;
    volatile uint32_t w;

    /*
     * First misaligned load.
     */
    h = *(volatile uint16_t *)&memory_area[1];

    sink = h;

    /*
     * If the exception handler returns execution,
     * this gives another misaligned access.
     */
    w = *(volatile uint32_t *)&memory_area[3];

    sink = w;
}

int main(void)
{
    prepare_memory();

    misaligned_sequence();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}