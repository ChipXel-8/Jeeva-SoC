#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * PRAGYA ALU COMPREHENSIVE TOGGLE COVERAGE TEST
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
     * ============================================================
     * ADD
     * alu_control = 4'd0
     * ============================================================
     */

    asm volatile(
        /*
         * Zero cases
         */
        "li x5, 0x00000000\n"
        "li x6, 0x00000000\n"
        "add x7, x5, x6\n"

        /*
         * Alternating pattern
         */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "add x7, x5, x6\n"

        /*
         * Carry through all bits
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        /*
         * Large positive values
         */
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        /*
         * Signed overflow
         */
        "li x5, 0x80000000\n"
        "li x6, 0xFFFFFFFF\n"
        "add x7, x5, x6\n"

        /*
         * Pattern transition
         */
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SUB
     * alu_control = 4'd1
     * ============================================================
     */

    asm volatile(
        /*
         * Zero result
         */
        "li x5, 0x00000000\n"
        "li x6, 0x00000000\n"
        "sub x7, x5, x6\n"

        /*
         * 0 - 1
         */
        "li x5, 0x00000000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        /*
         * FFFFFFFF - 1
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        /*
         * Alternating patterns
         */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "sub x7, x5, x6\n"

        "li x5, 0x55555555\n"
        "li x6, 0xAAAAAAAA\n"
        "sub x7, x5, x6\n"

        /*
         * Signed overflow
         */
        "li x5, 0x80000000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        "li x5, 0x7FFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "sub x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * AND
     * alu_control = 4'd2
     * ============================================================
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "and x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xAAAAAAAA\n"
        "and x7, x5, x6\n"

        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"
        "and x7, x5, x6\n"

        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "and x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * OR
     * alu_control = 4'd3
     * ============================================================
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "or x7, x5, x6\n"

        "li x5, 0x00000000\n"
        "li x6, 0xAAAAAAAA\n"
        "or x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000000\n"
        "or x7, x5, x6\n"

        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "or x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * XOR
     * alu_control = 4'd4
     * ============================================================
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "xor x7, x5, x6\n"

        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"
        "xor x7, x5, x6\n"

        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SLL
     * alu_control = 4'd5
     *
     * Shift amounts:
     * 0, 1, 7, 8, 15, 16, 31
     * ============================================================
     */

    asm volatile(
        "li x5, 0x00000001\n"

        "li x6, 0\n"
        "sll x7, x5, x6\n"

        "li x6, 1\n"
        "sll x7, x5, x6\n"

        "li x6, 7\n"
        "sll x7, x5, x6\n"

        "li x6, 8\n"
        "sll x7, x5, x6\n"

        "li x6, 15\n"
        "sll x7, x5, x6\n"

        "li x6, 16\n"
        "sll x7, x5, x6\n"

        "li x6, 31\n"
        "sll x7, x5, x6\n"

        /*
         * Alternating pattern
         */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 4\n"
        "sll x7, x5, x6\n"

        "li x6, 16\n"
        "sll x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SRL
     * alu_control = 4'd6
     * ============================================================
     */

    asm volatile(
        "li x5, 0xFFFFFFFF\n"

        "li x6, 0\n"
        "srl x7, x5, x6\n"

        "li x6, 1\n"
        "srl x7, x5, x6\n"

        "li x6, 7\n"
        "srl x7, x5, x6\n"

        "li x6, 8\n"
        "srl x7, x5, x6\n"

        "li x6, 15\n"
        "srl x7, x5, x6\n"

        "li x6, 16\n"
        "srl x7, x5, x6\n"

        "li x6, 31\n"
        "srl x7, x5, x6\n"

        /*
         * Alternating pattern
         */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 4\n"
        "srl x7, x5, x6\n"

        "li x6, 16\n"
        "srl x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SRA
     * alu_control = 4'd7
     *
     * Explicitly test negative numbers.
     * ============================================================
     */

    asm volatile(
        /*
         * Negative number
         */
        "li x5, 0x80000000\n"

        "li x6, 1\n"
        "sra x7, x5, x6\n"

        "li x6, 7\n"
        "sra x7, x5, x6\n"

        "li x6, 8\n"
        "sra x7, x5, x6\n"

        "li x6, 15\n"
        "sra x7, x5, x6\n"

        "li x6, 16\n"
        "sra x7, x5, x6\n"

        "li x6, 31\n"
        "sra x7, x5, x6\n"

        /*
         * Positive number
         */
        "li x5, 0x7FFFFFFF\n"
        "li x6, 4\n"
        "sra x7, x5, x6\n"

        /*
         * Alternating negative pattern
         */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 4\n"
        "sra x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SLT
     * alu_control = 4'd8
     *
     * SIGNED comparison
     * ============================================================
     */

    asm volatile(
        /*
         * 1 < 2 => 1
         */
        "li x5, 1\n"
        "li x6, 2\n"
        "slt x7, x5, x6\n"

        /*
         * 2 < 1 => 0
         */
        "li x5, 2\n"
        "li x6, 1\n"
        "slt x7, x5, x6\n"

        /*
         * -1 < +1 => 1
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 1\n"
        "slt x7, x5, x6\n"

        /*
         * +1 < -1 => 0
         */
        "li x5, 1\n"
        "li x6, 0xFFFFFFFF\n"
        "slt x7, x5, x6\n"

        /*
         * Minimum signed integer
         */
        "li x5, 0x80000000\n"
        "li x6, 0x00000000\n"
        "slt x7, x5, x6\n"

        /*
         * Maximum signed integer
         */
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "slt x7, x5, x6\n"

        /*
         * Equal
         */
        "li x5, 0x12345678\n"
        "li x6, 0x12345678\n"
        "slt x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ============================================================
     * SLTU
     * alu_control = 4'd9
     *
     * UNSIGNED comparison
     * ============================================================
     */

    asm volatile(
        /*
         * 1 < 2 => 1
         */
        "li x5, 1\n"
        "li x6, 2\n"
        "sltu x7, x5, x6\n"

        /*
         * 2 < 1 => 0
         */
        "li x5, 2\n"
        "li x6, 1\n"
        "sltu x7, x5, x6\n"

        /*
         * 0xFFFFFFFF > 1 unsigned
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 1\n"
        "sltu x7, x5, x6\n"

        /*
         * 1 < 0xFFFFFFFF unsigned
         */
        "li x5, 1\n"
        "li x6, 0xFFFFFFFF\n"
        "sltu x7, x5, x6\n"

        /*
         * 0 < 0xFFFFFFFF
         */
        "li x5, 0\n"
        "li x6, 0xFFFFFFFF\n"
        "sltu x7, x5, x6\n"

        /*
         * Equal
         */
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0xAAAAAAAA\n"
        "sltu x7, x5, x6\n"

        /*
         * Maximum versus zero
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0\n"
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

    value = 0xCAFEBABE;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}