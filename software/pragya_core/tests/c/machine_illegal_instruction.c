#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /*
     * Illegal instruction
     *
     * 0xffffffff is not a valid RV32I instruction
     * for your decoder.
     *
     * MCAUSE = 2
     */
    asm volatile(
        ".word 0xffffffff\n"
        :
        :
        : "memory"
    );

    /*
     * Must execute after MRET.
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "mv %0, x7"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}