#include "pragya_test.h"
#include <stdint.h>

#define MSTATUS_MIE  (1u << 3)
#define MIE_MSIE     (1u << 3)

volatile uint32_t result;

int main(void)
{
    /*
     * Enable machine software interrupt.
     */
    asm volatile(
        "li t0, %0\n"
        "csrs mie, t0\n"
        :
        : "i"(MIE_MSIE)
        : "t0", "memory"
    );

    /*
     * Disable global MIE.
     */
    asm volatile(
        "li t0, %0\n"
        "csrc mstatus, t0\n"
        :
        : "i"(MSTATUS_MIE)
        : "t0", "memory"
    );

    asm volatile(
        "csrr %0, mstatus"
        : "=r"(result)
        :
        : "memory"
    );

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}