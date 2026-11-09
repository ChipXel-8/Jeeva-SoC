#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * CORE PC TOGGLE TEST
     *
     * Covers:
     *   sequential PC
     *   JAL
     *   JALR
     *   taken branch
     *   not-taken branch
     *   link register
     *   PC+4
     * ============================================================
     */

    asm volatile(
        "li x5, 0\n"
        "li x6, 0\n"

        /* NOT TAKEN */
        "bne x5, x6, 1f\n"
        "addi x7, x0, 1\n"

        "1:\n"

        /* TAKEN */
        "beq x5, x6, 2f\n"
        "addi x7, x0, 2\n"

        "2:\n"

        "addi x8, x0, 10\n"
        "addi x8, x8, 1\n"
        "addi x8, x8, 1\n"
        "addi x8, x8, 1\n"

        /* JAL */
        "jal x1, 3f\n"
        "addi x9, x0, 9\n"
        "addi x9, x0, 9\n"

        "3:\n"

        "addi x10, x0, 20\n"
        "addi x10, x10, 1\n"

        /* JALR */
        "la x11, 4f\n"
        "jalr x12, 0(x11)\n"
        "addi x13, x0, 13\n"

        "4:\n"

        "addi x14, x0, 14\n"
        "addi x14, x14, 1\n"

        :
        :
        : "memory"
    );

    value = 0x12345678;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}