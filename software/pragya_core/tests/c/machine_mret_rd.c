#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    /*
     * MRET pattern with rd = x1.
     *
     * Targets:
     *   rd_zero_0
     */

    asm volatile(
        ".word 0x302000f3\n"
        :
        :
        : "memory"
    );

    sink = 0x33333333;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}