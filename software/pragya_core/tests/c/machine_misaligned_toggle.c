#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL - MISALIGNED LOAD/STORE TOGGLE
     *
     * MCAUSE:
     *
     *   4 = LOAD MISALIGNED
     *   6 = STORE MISALIGNED
     *
     * ============================================================
     */

    /* LOAD MISALIGNED #1 */
    asm volatile(
        "li x5, 0x80008001\n"
        "lw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x7, 0x11111111\n"
        :
        :
        : "memory"
    );

    /* STORE MISALIGNED #1 */
    asm volatile(
        "li x5, 0x80008001\n"
        "li x6, 0x12345678\n"
        "sw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x7, 0x22222222\n"
        :
        :
        : "memory"
    );

    /* LOAD MISALIGNED #2 */
    asm volatile(
        "li x5, 0x80008001\n"
        "lw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "li x7, 0x33333333\n"
        :
        :
        : "memory"
    );

    /* STORE MISALIGNED #2 */
    asm volatile(
        "li x5, 0x80008001\n"
        "li x6, 0x87654321\n"
        "sw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    value = 0x55555555;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}