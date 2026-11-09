#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * CROSS R-TYPE RESULT TEST
 * ============================================================
 *
 * Goal:
 *
 *     Cover:
 *
 *         SLL × NEGATIVE
 *
 * Coverage definition:
 *
 *     RESULT_NEGATIVE =
 *         0xFFFFFF80 to 0xFFFFFFFF
 *
 * Therefore we deliberately generate:
 *
 *     SLL result = 0xFFFFFFFF
 *
 * ============================================================
 */

static void test_sll_negative(void)
{
    asm volatile(

        /*
         * ====================================================
         * Generate 0xFFFFFFFF in t0
         * ====================================================
         *
         * lui:
         *
         *     t0 = 0xFFFFF000
         *
         * addi -1:
         *
         *     t0 = 0xFFFFFFFF
         *
         * ====================================================
         */

        "lui   t0, 0xfffff\n"
        "addi  t0, t0, -1\n"


        /*
         * Allow t0 to become available.
         */

        "nop\n"
        "nop\n"


        /*
         * Shift amount = 0
         */

        "addi  t1, zero, 0\n"

        "nop\n"
        "nop\n"


        /*
         * ====================================================
         * SLL × NEGATIVE
         * ====================================================
         *
         * t0 = 0xFFFFFFFF
         * t1 = 0
         *
         * SLL:
         *
         *     0xFFFFFFFF << 0
         *
         *   = 0xFFFFFFFF
         *
         * Coverage classification:
         *
         *     0xFFFFFF80 <= 0xFFFFFFFF <= 0xFFFFFFFF
         *
         * Therefore:
         *
         *     RESULT_NEGATIVE
         *
         * ====================================================
         */

        "sll   t2, t0, t1\n"


        /*
         * Allow instruction to reach commit.
         */

        "nop\n"
        "nop\n"
        "nop\n"

        :
        :
        : "t0", "t1", "t2", "memory"
    );
}


int main(void)
{
    test_sll_negative();

    test_pass();

    return 0;
}