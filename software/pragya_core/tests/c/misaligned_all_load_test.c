#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[32];

__attribute__((noinline))
static void test_all_misaligned_loads(void)
{
    volatile uint16_t lh_value;
    volatile uint16_t lhu_value;

    volatile uint32_t lw1;
    volatile uint32_t lw2;
    volatile uint32_t lw3;

    /*
     * LH
     * offset = 1
     */
    lh_value =
        *(volatile uint16_t *)&memory_area[1];

    sink = lh_value;

    /*
     * LHU
     * offset = 3
     */
    lhu_value =
        *(volatile uint16_t *)&memory_area[3];

    sink = lhu_value;

    /*
     * LW offset = 1
     */
    lw1 =
        *(volatile uint32_t *)&memory_area[1];

    sink = lw1;

    /*
     * LW offset = 2
     */
    lw2 =
        *(volatile uint32_t *)&memory_area[2];

    sink = lw2;

    /*
     * LW offset = 3
     */
    lw3 =
        *(volatile uint32_t *)&memory_area[3];

    sink = lw3;
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 32; i++)
        memory_area[i] =
            (uint8_t)(0x10 + i);

    test_all_misaligned_loads();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}