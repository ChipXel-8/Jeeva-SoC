#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    /*
     * ECALL-like SYSTEM instruction:
     *
     * funct7 = 0000001 instead of 0000000
     *
     * rs2 = x0
     * rs1 = x0
     * funct3 = 000
     * rd = x0
     *
     * Targets:
     *   FUNCT7_zero_0
     * in the ECALL expression.
     */

    asm volatile(
        ".word 0x02000073\n"
        :
        :
        : "memory"
    );

    sink = 0x44444444;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}