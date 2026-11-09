#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    /*
     * MRET pattern with rs1 = x1 instead of x0.
     *
     * Expected:
     *   is_system       = 1
     *   FUNCT7_mret     = 1
     *   rs2_addr_mret   = 1
     *   rs1_addr_zero   = 0
     *
     * This targets:
     *   rs1_addr_zero_0
     */
    asm volatile(
        ".word 0x30208073\n"
        :
        :
        : "memory"
    );

    sink = 0x11111111;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}