#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[32];

__attribute__((noinline))
static void test_lh_odd_addresses(void)
{
    volatile uint16_t a;
    volatile uint16_t b;

    /*
     * +1 -> odd
     */
    a = *(volatile uint16_t *)&memory_area[1];

    /*
     * +3 -> odd
     */
    b = *(volatile uint16_t *)&memory_area[3];

    sink = a;
    sink = b;
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 32; i++)
        memory_area[i] = (uint8_t)(i * 3 + 1);

    test_lh_odd_addresses();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}