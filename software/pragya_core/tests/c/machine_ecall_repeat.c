#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL - REPEATED ECALL / MRET
     * ============================================================
     */

    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* ECALL #1 */
    asm volatile("ecall" ::: "memory");

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* ECALL #2 */
    asm volatile("ecall" ::: "memory");

    asm volatile(
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* ECALL #3 */
    asm volatile("ecall" ::: "memory");

    asm volatile(
        "li x5, 0xDEADBEEF\n"
        "li x6, 0x11111111\n"
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