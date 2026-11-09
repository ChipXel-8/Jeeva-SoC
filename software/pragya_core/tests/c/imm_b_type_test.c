#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * IMMEDIATE GENERATOR - B TYPE TEST
     *
     * Exercises:
     *
     *   imm_src = 3'b011
     *   b_type[0]
     *   B-type immediate:
     *
     *       imm[12]   = instr[31]
     *       imm[11]   = instr[7]
     *       imm[10:5] = instr[30:25]
     *       imm[4:1]  = instr[11:8]
     *       imm[0]    = 0
     *
     * ============================================================
     */

    /*
     * Branch taken.
     *
     * This forces B-type immediate generation.
     */

    asm volatile(
        "li x5, 0\n"
        "li x6, 1\n"
        "beq x5, x6, branch_not_taken_1\n"
        "li x7, 0x11111111\n"

        "branch_not_taken_1:\n"
        "li x7, 0x22222222\n"
        :
        :
        : "memory"
    );


    /*
     * Branch with negative displacement.
     */

    asm volatile(
        "li x5, 5\n"
        "li x6, 5\n"
        "beq x5, x6, branch_taken_2\n"
        "li x7, 0xAAAAAAAA\n"

        "branch_taken_2:\n"
        "li x7, 0x55555555\n"
        :
        :
        : "memory"
    );


    /*
     * BNE.
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 2\n"
        "bne x5, x6, branch_taken_3\n"
        "li x7, 0x33333333\n"

        "branch_taken_3:\n"
        "li x7, 0x44444444\n"
        :
        :
        : "memory"
    );


    /*
     * BLT
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 2\n"
        "blt x5, x6, branch_taken_4\n"
        "li x7, 0xAAAAAAAA\n"

        "branch_taken_4:\n"
        "li x7, 0xBBBBBBBB\n"
        :
        :
        : "memory"
    );


    /*
     * BGE
     */

    asm volatile(
        "li x5, 2\n"
        "li x6, 1\n"
        "bge x5, x6, branch_taken_5\n"
        "li x7, 0xCCCCCCCC\n"

        "branch_taken_5:\n"
        "li x7, 0xDDDDDDDD\n"
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