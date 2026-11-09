#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t memory_area[16];

__attribute__((noinline))
static void misaligned_sh_offset3(void)
{
    volatile uint16_t *p;

    p = (volatile uint16_t *)&memory_area[3];

    *p = 0x55AA;

    sink = memory_area[3];
}

int main(void)
{
    memory_area[0] = 0x00;
    memory_area[1] = 0x11;
    memory_area[2] = 0x22;
    memory_area[3] = 0x33;
    memory_area[4] = 0x44;

    misaligned_sh_offset3();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}