#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * PRAGYA ALU TOGGLE COVERAGE TEST
     *
     * Purpose:
     *
     *   Exercise all functionally reachable ALU result bits.
     *
     * ALU operations:
     *
     *   ADD
     *   SUB
     *   AND
     *   OR
     *   XOR
     *   SLL
     *   SRL
     *   SRA
     *   SLT
     *   SLTU
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Pattern 1
     *
     * Basic arithmetic and logical operations.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "and x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 2
     *
     * Opposite alternating pattern.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x55555555\n"
        "li x6, 0xAAAAAAAA\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "and x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 3
     *
     * All ones versus zero.
     *
     * Useful for toggling many result bits.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000000\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "and x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 4
     *
     * Zero versus all ones.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "and x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 5
     *
     * Maximum positive and maximum negative signed values.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0x80000000\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "and x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SHIFT OPERATIONS
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Pattern 6
     *
     * Shift by 0.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0\n"

        "sll x7,  x5, x6\n"
        "srl x8,  x5, x6\n"
        "sra x9,  x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 7
     *
     * Shift by 1.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 1\n"

        "sll x7,  x5, x6\n"
        "srl x8,  x5, x6\n"
        "sra x9,  x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 8
     *
     * Shift by 4.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x55555555\n"
        "li x6, 4\n"

        "sll x7,  x5, x6\n"
        "srl x8,  x5, x6\n"
        "sra x9,  x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 9
     *
     * Shift by 8.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 8\n"

        "sll x7,  x5, x6\n"
        "srl x8,  x5, x6\n"
        "sra x9,  x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 10
     *
     * Shift by 16.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x55555555\n"
        "li x6, 16\n"

        "sll x7,  x5, x6\n"
        "srl x8,  x5, x6\n"
        "sra x9,  x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 11
     *
     * Shift by 31.
     *
     * Important for MSB/LSB behaviour.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80000000\n"
        "li x6, 31\n"

        "sll x7,  x5, x6\n"
        "srl x8,  x5, x6\n"
        "sra x9,  x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 12
     *
     * SRA with negative number.
     *
     * This specifically exercises sign propagation.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80000000\n"
        "li x6, 1\n"

        "sra x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 13
     *
     * SRA with all bits set.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xFFFFFFFF\n"
        "li x6, 4\n"

        "sra x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SIGNED LESS-THAN (SLT)
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Pattern 14
     *
     * Positive < positive
     *
     * Expected:
     *
     *   SLT = 1
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 10\n"
        "li x6, 20\n"

        "slt x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 15
     *
     * Positive > positive
     *
     * Expected:
     *
     *   SLT = 0
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 20\n"
        "li x6, 10\n"

        "slt x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 16
     *
     * Negative < positive.
     *
     * Expected:
     *
     *   SLT = 1
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, -10\n"
        "li x6, 10\n"

        "slt x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 17
     *
     * Positive > negative.
     *
     * Expected:
     *
     *   SLT = 0
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 10\n"
        "li x6, -10\n"

        "slt x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 18
     *
     * Minimum signed value versus maximum signed value.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x80000000\n"
        "li x6, 0x7FFFFFFF\n"

        "slt x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * UNSIGNED LESS-THAN (SLTU)
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Pattern 19
     *
     * 1 < 2
     *
     * Expected:
     *
     *   SLTU = 1
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 2\n"

        "sltu x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 20
     *
     * 2 > 1
     *
     * Expected:
     *
     *   SLTU = 0
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 2\n"
        "li x6, 1\n"

        "sltu x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 21
     *
     * 0xFFFFFFFF compared with 1.
     *
     * Unsigned:
     *
     *   0xFFFFFFFF > 1
     *
     * Expected:
     *
     *   SLTU = 0
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xFFFFFFFF\n"
        "li x6, 1\n"

        "sltu x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 22
     *
     * 1 compared with 0xFFFFFFFF.
     *
     * Unsigned:
     *
     *   1 < 0xFFFFFFFF
     *
     * Expected:
     *
     *   SLTU = 1
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 0xFFFFFFFF\n"

        "sltu x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 23
     *
     * Maximum unsigned values.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFE\n"

        "sltu x7, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * FINAL RESULT
     * ============================================================
     */

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