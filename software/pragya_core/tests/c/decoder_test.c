#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * DECODER - BRANCH TYPE TEST
     *
     * Exercises:
     *
     *   is_branch
     *   branch_legal
     *   funct3:
     *
     *       000 = BEQ
     *       001 = BNE
     *       100 = BLT
     *       101 = BGE
     *       110 = BLTU
     *       111 = BGEU
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * BEQ - funct3 = 000
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 5\n"
        "li x6, 5\n"
        "beq x5, x6, beq_taken\n"
        "li x7, 0x11111111\n"

        "beq_taken:\n"
        "li x7, 0x22222222\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BEQ NOT TAKEN
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 5\n"
        "li x6, 6\n"
        "beq x5, x6, beq_not_taken\n"
        "li x7, 0x33333333\n"

        "beq_not_taken:\n"
        "li x7, 0x44444444\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BNE - funct3 = 001
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 5\n"
        "li x6, 6\n"
        "bne x5, x6, bne_taken\n"
        "li x7, 0x55555555\n"

        "bne_taken:\n"
        "li x7, 0x66666666\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BLT - funct3 = 100
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 2\n"
        "blt x5, x6, blt_taken\n"
        "li x7, 0x77777777\n"

        "blt_taken:\n"
        "li x7, 0x88888888\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BGE - funct3 = 101
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 2\n"
        "li x6, 1\n"
        "bge x5, x6, bge_taken\n"
        "li x7, 0x99999999\n"

        "bge_taken:\n"
        "li x7, 0xAAAAAAAA\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BLTU - funct3 = 110
     *
     * Unsigned comparison
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 2\n"
        "bltu x5, x6, bltu_taken\n"
        "li x7, 0xBBBBBBBB\n"

        "bltu_taken:\n"
        "li x7, 0xCCCCCCCC\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BGEU - funct3 = 111
     *
     * Unsigned comparison
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 2\n"
        "li x6, 1\n"
        "bgeu x5, x6, bgeu_taken\n"
        "li x7, 0xDDDDDDDD\n"

        "bgeu_taken:\n"
        "li x7, 0xEEEEEEEE\n"
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