#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    /*
     * EBREAK-like SYSTEM instruction:
     *
     * funct7 = 0000001 instead of 0000000
     *
     * rs2 = x1
     * rs1 = x0
     * funct3 = 000
     * rd = x0
     *
     * Targets:
     *   FUNCT7_zero_0
     * in the EBREAK expression.
     */

    asm volatile(
        ".word 0x02100073\n"
        :
        :
        : "memory"
    );

    sink = 0x55555555;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}