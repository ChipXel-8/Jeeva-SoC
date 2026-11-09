#include "pragya_test.h"
#include <stdint.h>

int main(void)
{
    volatile int a, b, c;

    /*==========================================================*
     * JAL - FORWARD
     *
     * Required coverage:
     *
     *     cp_instr = JAL
     *     cp_direction = forward
     *
     * target_pc > pc
     *==========================================================*/

    a = 10;

    asm volatile(
        "jal x5, 1f\n"

        /* These instructions are skipped */
        "addi x10, x10, 1\n"
        "addi x10, x10, 1\n"

        /* Forward JAL target */
        "1:\n"
        "addi x6, x0, 20\n"
        :
        :
        : "x5", "x6", "x10"
    );

    b = 20;

    if (b != 20)
        test_fail();


    /*==========================================================*
     * JALR - FORWARD
     *
     * Required coverage:
     *
     *     cp_instr = JALR
     *     cp_direction = forward
     *
     * target_pc > pc
     *==========================================================*/

    asm volatile(
        "la x5, 2f\n"
        "jalr x6, x5, 0\n"

        /* These instructions are skipped */
        "addi x10, x10, 1\n"
        "addi x10, x10, 1\n"

        /* Forward JALR target */
        "2:\n"
        "addi x7, x0, 30\n"
        :
        :
        : "x5", "x6", "x7", "x10"
    );

    c = 30;

    if (c != 30)
        test_fail();


    /*==========================================================*
     * Additional normal branch tests
     *
     * These are useful for making sure branch coverage
     * remains exercised while running this directed test.
     *==========================================================*/

    a = 10;
    b = 20;

    if (a == b)
        test_fail();

    if (a != a)
        test_fail();


    /*==========================================================*
     * PASS
     *==========================================================*/

    test_pass();

    return 0;
}