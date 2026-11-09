#include "pragya_test.h"
#include <stdint.h>

#define MSTATUS_MIE  (1u << 3)
#define MIE_MEIE     (1u << 11)

volatile uint32_t result;

int main(void)
{
    uint32_t mstatus;

    /*
     * Enable external interrupt source.
     */
    asm volatile(
        "li t0, %0\n"
        "csrs mie, t0\n"
        :
        : "i"(MIE_MEIE)
        : "t0", "memory"
    );

    /*
     * Keep global MIE = 0.
     *
     * This creates the required condition:
     *
     * meie_in = 1
     * eip     = 1
     * mie_in  = 0
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
        : "=r"(mstatus)
        :
        : "memory"
    );

    result = mstatus;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}