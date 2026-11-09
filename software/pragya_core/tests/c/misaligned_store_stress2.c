#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

__attribute__((aligned(4)))
volatile uint8_t mem1[16];

__attribute__((aligned(4)))
volatile uint8_t mem2[16];

__attribute__((aligned(4)))
volatile uint8_t mem3[16];

__attribute__((noinline))
static void test_multiple_bases(void)
{
    volatile uint16_t a;
    volatile uint16_t b;
    volatile uint32_t c;

    /*
     * Base 1 + 1
     */
    a = *(volatile uint16_t *)&mem1[1];

    /*
     * Base 2 + 3
     */
    b = *(volatile uint16_t *)&mem2[3];

    /*
     * Base 3 + 2
     */
    c = *(volatile uint32_t *)&mem3[2];

    sink = a;
    sink ^= b;
    sink ^= c;
}

int main(void)
{
    for (volatile uint32_t i = 0; i < 16; i++)
    {
        mem1[i] = i;
        mem2[i] = i + 16;
        mem3[i] = i + 32;
    }

    test_multiple_bases();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}