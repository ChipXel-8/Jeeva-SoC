#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    /*
     * MRET pattern with FUNCT3 = 001.
     *
     * Targets:
     *   FUNCT3_zero_0
     */

    asm volatile(
        ".word 0x30201073\n"
        :
        :
        : "memory"
    );

    sink = 0x22222222;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}