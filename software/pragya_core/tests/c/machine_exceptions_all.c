#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * COMPLETE MACHINE CONTROL EXCEPTION TEST
     * ============================================================
     */

    /* NORMAL */
    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* ECALL : MCAUSE = 11 */
    asm volatile(
        "ecall\n"
        :
        :
        : "memory"
    );

    /* NORMAL AFTER ECALL */
    asm volatile(
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* EBREAK : MCAUSE = 3 */
    asm volatile(
        "ebreak\n"
        :
        :
        : "memory"
    );

    /* NORMAL AFTER EBREAK */
    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0xFFFFFFFF\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* ILLEGAL : MCAUSE = 2 */
    asm volatile(
        ".word 0xffffffff\n"
        :
        :
        : "memory"
    );

    /* NORMAL AFTER ILLEGAL */
    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* MISALIGNED LOAD : MCAUSE = 4 */
    asm volatile(
        "li x5, 0x80008001\n"
        "lw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    /* NORMAL AFTER LOAD TRAP */
    asm volatile(
        "li x5, 0x33333333\n"
        "li x6, 0x44444444\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /* MISALIGNED STORE : MCAUSE = 6 */
    asm volatile(
        "li x5, 0x80008001\n"
        "li x6, 0xCAFEBABE\n"
        "sw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    /* NORMAL AFTER STORE TRAP */
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