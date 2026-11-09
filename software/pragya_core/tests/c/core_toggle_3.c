#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * IMMEDIATE / DECODER TEST
     * ============================================================
     */

    asm volatile(

        /* I-type */
        "addi x5, x0, 127\n"
        "addi x6, x0, -128\n"
        "andi x7, x5, 0x7f\n"
        "ori  x8, x5, 0x55\n"
        "xori x9, x5, 0x33\n"

        /* U-type */
        "lui x10, 0x12345\n"
        "auipc x11, 0x10\n"

        /* S-type */
        "li x12, 0x80008000\n"
        "li x13, 0xabcdef01\n"
        "sw x13, 4(x12)\n"

        /* Load I-type */
        "lw x14, 4(x12)\n"

        /* B-type */
        "li x15, 1\n"
        "li x16, 1\n"
        "beq x15, x16, 1f\n"
        "nop\n"

        "1:\n"

        /* J-type */
        "jal x17, 2f\n"
        "nop\n"

        "2:\n"
        "addi x18, x0, 18\n"

        :
        :
        : "memory"
    );

    value = 0x55aa55aa;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}