#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * I-TYPE IMMEDIATE GENERATOR COVERAGE TEST
     *
     * Purpose:
     *
     *   Exercise the I-type immediate generator with different
     *   immediate bit patterns.
     *
     *   I-type immediate:
     *
     *       imm[11:0]
     *
     *   is sign extended to 32 bits.
     *
     *   This test specifically exercises:
     *
     *       imm[0]
     *       imm[1]
     *       imm[2]
     *       ...
     *       imm[10]
     *       imm[11]
     *
     *   and both positive and negative sign extension.
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Pattern 1
     *
     * Toggle immediate bit [0]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x001\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 2
     *
     * Toggle immediate bit [1]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x002\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 3
     *
     * Toggle immediate bit [2]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x004\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 4
     *
     * Toggle immediate bit [3]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x008\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 5
     *
     * Toggle immediate bit [4]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x010\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 6
     *
     * Toggle immediate bit [5]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x020\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 7
     *
     * Toggle immediate bit [6]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x040\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 8
     *
     * Toggle immediate bit [7]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x080\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 9
     *
     * Toggle immediate bit [8]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x100\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 10
     *
     * Toggle immediate bit [9]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x200\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 11
     *
     * Toggle immediate bit [10]
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x400\n"
        "addi x6, x0, 0x000\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 12
     *
     * Toggle immediate bit [11].
     *
     * 0x800 is interpreted as -2048 in a 12-bit signed
     * I-type immediate.
     *
     * This also exercises sign extension.
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, -2048\n"
        "addi x6, x0, 0\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 13
     *
     * All 12 immediate bits = 1.
     *
     * 0x7FF = +2047
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 2047\n"
        "addi x6, x0, 0\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 14
     *
     * Negative immediate.
     *
     * Exercises sign extension into bits [31:12].
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, -1\n"
        "addi x6, x0, 0\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 15
     *
     * Another negative immediate pattern.
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, -1024\n"
        "addi x6, x0, -512\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Pattern 16
     *
     * Mixed positive immediate patterns.
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0, 0x155\n"
        "addi x6, x0, 0x2AA\n"
        "addi x7, x0, 0x3FF\n"
        "addi x8, x0, 0x555\n        "
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Capture result
     * ------------------------------------------------------------
     */

    asm volatile(
        "mv %0, x8"
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