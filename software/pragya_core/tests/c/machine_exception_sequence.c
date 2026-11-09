#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL - EXCEPTION CAUSE TRANSITION TEST
     *
     * Cause sequence:
     *
     *   11 -> 3 -> 2 -> 4 -> 6
     *
     * ============================================================
     */

    /* ECALL : 11 = 1011 */
    asm volatile(
        "ecall\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* EBREAK : 3 = 0011 */
    asm volatile(
        "ebreak\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* ILLEGAL : 2 = 0010 */
    asm volatile(
        ".word 0xffffffff\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* MISALIGNED LOAD : 4 = 0100 */
    asm volatile(
        "li x5, 0x80008001\n"
        "lw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x5, 0x33333333\n"
        "li x6, 0x44444444\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* MISALIGNED STORE : 6 = 0110 */
    asm volatile(
        "li x5, 0x80008001\n"
        "li x6, 0xCAFEBABE\n"
        "sw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

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