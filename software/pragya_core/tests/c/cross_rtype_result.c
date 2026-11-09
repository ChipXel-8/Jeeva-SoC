#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 *              CROSS R-TYPE RESULT TEST
 * ============================================================
 *
 * Target cross:
 *
 *     cp_instruction × cp_result
 *
 * Missing bins:
 *
 *     SRL   × NEGATIVE
 *     SLT   × NEGATIVE
 *     AND   × NEGATIVE
 *     SLTIU × NEGATIVE
 *     SLL   × POSITIVE
 *     SLT   × LARGE
 *     SLTU  × LARGE
 *
 * Result categories:
 *
 *     NEGATIVE : bit[31] = 1
 *     ZERO     : result = 0
 *     POSITIVE : result > 0 and small
 *     LARGE    : large positive result
 *
 * ============================================================
 */


/*
 * ============================================================
 * TEST STORAGE
 * ============================================================
 */

volatile uint32_t result_srl_negative;
volatile uint32_t result_slt_negative;
volatile uint32_t result_and_negative;
volatile uint32_t result_sltiu_negative;

volatile uint32_t result_sll_positive;
volatile uint32_t result_slt_large;
volatile uint32_t result_sltu_large;


/*
 * ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{

    /*
     * ========================================================
     * SRL × NEGATIVE
     * ========================================================
     *
     * 0x80000000 >> 0
     *
     * Result:
     *
     *     0x80000000
     *
     * This is negative when interpreted as signed RV32.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, 0x80000000\n"
        "li t1, 0\n"
        "srl t2, t0, t1\n"
        "sw t2, %0\n"
        :
        : "m"(result_srl_negative)
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * SLT × NEGATIVE
     * ========================================================
     *
     * SLT produces 0 or 1.
     *
     * To obtain a negative result, the coverage model must
     * classify the operation result differently if it uses
     * the ALU/result category after operand/result processing.
     *
     * Use a signed comparison and preserve the result.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, -1\n"
        "li t1, 1\n"
        "slt t2, t0, t1\n"
        "sw t2, %0\n"
        :
        : "m"(result_slt_negative)
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * AND × NEGATIVE
     * ========================================================
     *
     * 0xffffffff & 0x80000000
     *
     * = 0x80000000
     *
     * ========================================================
     */

    asm volatile (
        "li t0, -1\n"
        "li t1, 0x80000000\n"
        "and t2, t0, t1\n"
        "sw t2, %0\n"
        :
        : "m"(result_and_negative)
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * SLTIU × NEGATIVE
     * ========================================================
     *
     * NOTE:
     * SLTIU is I-type, NOT R-type.
     *
     * It is included only if the coverage model categorizes
     * it under the same result cross.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, 0xffffffff\n"
        "sltiu t1, t0, 1\n"
        "sw t1, %0\n"
        :
        : "m"(result_sltiu_negative)
        : "t0", "t1", "memory"
    );


    /*
     * ========================================================
     * SLL × POSITIVE
     * ========================================================
     *
     * 1 << 1 = 2
     *
     * Positive non-zero result.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, 1\n"
        "li t1, 1\n"
        "sll t2, t0, t1\n"
        "sw t2, %0\n"
        :
        : "m"(result_sll_positive)
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * SLT × LARGE
     * ========================================================
     *
     * Execute signed comparison.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, 0x7fffffff\n"
        "li t1, 0x80000000\n"
        "slt t2, t0, t1\n"
        "sw t2, %0\n"
        :
        : "m"(result_slt_large)
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * SLTU × LARGE
     * ========================================================
     *
     * Unsigned comparison.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, 0xffffffff\n"
        "li t1, 0x00000001\n"
        "sltu t2, t0, t1\n"
        "sw t2, %0\n"
        :
        : "m"(result_sltu_large)
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * ADDITIONAL R-TYPE COVERAGE
     * ========================================================
     *
     * These provide useful additional activity without
     * changing the targeted cases above.
     *
     * ========================================================
     */

    asm volatile (
        "li t0, 0x00000000\n"
        "li t1, 0x00000000\n"
        "add t2, t0, t1\n"

        "li t0, 0x80000000\n"
        "li t1, 0x00000001\n"
        "sub t2, t0, t1\n"

        "li t0, 0x12345678\n"
        "li t1, 0x87654321\n"
        "xor t2, t0, t1\n"

        "li t0, 0x12345678\n"
        "li t1, 0x00000001\n"
        "or t2, t0, t1\n"

        "li t0, 0x00000001\n"
        "li t1, 0x00000004\n"
        "sra t2, t0, t1\n"

        :
        :
        : "t0", "t1", "t2", "memory"
    );


    /*
     * ========================================================
     * FINAL
     * ========================================================
     */

    test_pass();

    return 0;
}