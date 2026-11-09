#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * Enable MIE and MEIE.
     *
     * MSTATUS.MIE = bit 3
     * MIE.MEIE    = bit 11
     */

    asm volatile(
        "li x5, 0x800\n"
        "csrs mie, x5\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x5, 0x8\n"
        "csrs mstatus, x5\n"
        :
        :
        : "memory"
    );

    /*
     * Wait for external interrupt from TB.
     */
    asm volatile(
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );

    value = 0x11111111;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}