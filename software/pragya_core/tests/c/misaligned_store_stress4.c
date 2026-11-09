#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[64];

__attribute__((noinline))
static void dynamic_misaligned_sw(uint32_t offset,
                                  uint32_t value)
{
    volatile uint32_t *p;

    p = (volatile uint32_t *)&memory_area[offset];

    *p = value;

    sink = memory_area[offset];
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 64; i++)
        memory_area[i] = 0xAA;

    dynamic_misaligned_sw(1, 0x12345678);

    dynamic_misaligned_sw(2, 0xDEADBEEF);

    dynamic_misaligned_sw(3, 0xCAFEBABE);

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}