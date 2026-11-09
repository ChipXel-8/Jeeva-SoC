#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void test_lhu_max(void)
{
    volatile uint16_t value;

    value =
        *(volatile uint16_t *)&memory_area[1];

    sink = value;
}

int main(void)
{
    memory_area[0] = 0xAA;
    memory_area[1] = 0xFF;
    memory_area[2] = 0xFF;
    memory_area[3] = 0x55;

    test_lhu_max();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}