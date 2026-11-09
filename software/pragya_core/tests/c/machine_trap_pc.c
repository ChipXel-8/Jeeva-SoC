#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL TRAP PC TOGGLE TEST
     *
     * Generate traps at different PC values.
     *
     * Different PC bits can toggle depending on the
     * instruction locations.
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

    /*
     * ------------------------------------------------------------
     * ECALL
     * ------------------------------------------------------------
     */

    asm volatile(
        "ecall\n"
        :
        :
        : "memory"
    );

    /*
     * Large block of instructions.
     * This moves the next trap to a different PC.
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "add x7, x5, x6\n"
        "xor x8, x5, x6\n"
        "or  x9, x5, x6\n"
        "and x10, x5, x6\n"
        "add x11, x7, x8\n"
        "sub x12, x9, x10\n"
        "xor x13, x11, x12\n"
        "or  x14, x13, x7\n"
        "and x15, x14, x8\n"
        "add x16, x15, x9\n"
        "sub x17, x16, x10\n"
        "xor x18, x17, x11\n"
        "or  x19, x18, x12\n"
        "and x20, x19, x13\n"
        "add x21, x20, x14\n"
        "sub x22, x21, x15\n"
        "xor x23, x22, x16\n"
        "or  x24, x23, x17\n"
        "and x25, x24, x18\n"
        :
        :
        : "memory"
    );

    /*
     * ------------------------------------------------------------
     * EBREAK
     * ------------------------------------------------------------
     */

    asm volatile(
        "ebreak\n"
        :
        :
        : "memory"
    );

    /*
     * Another large distance.
     */

    asm volatile(
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        "xor x8, x5, x6\n"
        "or  x9, x5, x6\n"
        "and x10, x5, x6\n"
        "add x11, x7, x8\n"
        "sub x12, x9, x10\n"
        "xor x13, x11, x12\n"
        "or  x14, x13, x7\n"
        "and x15, x14, x8\n"
        "add x16, x15, x9\n"
        "sub x17, x16, x10\n"
        "xor x18, x17, x11\n"
        "or  x19, x18, x12\n"
        "and x20, x19, x13\n"
        :
        :
        : "memory"
    );

    /*
     * ------------------------------------------------------------
     * MISALIGNED LOAD
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80008001\n"
        "lw x6, 0(x5)\n"
        :
        :
        : "memory"
    );

    /*
     * ------------------------------------------------------------
     * More normal instructions
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xDEADBEEF\n"
        "li x6, 0x11111111\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /*
     * ------------------------------------------------------------
     * MISALIGNED STORE
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80008001\n"
        "li x6, 0xCAFEBABE\n"
        "sw x6, 0(x5)\n"
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