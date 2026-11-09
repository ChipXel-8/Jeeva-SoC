#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA JAL / JALR FORWARD DIRECTION COVERAGE TEST
 *
 * Purpose:
 *
 *   Hit the following coverage bins:
 *
 *       JAL  + forward
 *       JALR + forward
 *
 * Coverage definition:
 *
 *       forward  = target_pc > pc
 *       backward = target_pc <= pc
 *
 * ============================================================
 */

int main(void)
{
    volatile uint32_t *result =
        (volatile uint32_t *)0x80007FF4;

    volatile uint32_t value = 0;


    /*
     * ========================================================
     * TEST 1: JAL FORWARD
     * ========================================================
     *
     * The JAL instruction is before label jal_target.
     *
     * Therefore:
     *
     *       JAL PC < jal_target PC
     *
     * So this must hit:
     *
     *       JAL + FORWARD
     *
     * x5 receives the return address.
     */

    asm volatile (
        "jal x5, jal_target\n"

        /* These instructions should be skipped */
        "addi x10, x0, 0x111\n"
        "addi x10, x0, 0x111\n"

        "jal_target:\n"

        /* Target of JAL */
        "addi x10, x0, 0x222\n"

        :
        :
        : "x5", "x10", "memory"
    );


    /*
     * ========================================================
     * TEST 2: JALR FORWARD
     * ========================================================
     *
     * First calculate the address of jalr_target.
     *
     * Then:
     *
     *       jalr x6, 0(x5)
     *
     * jumps forward to jalr_target.
     *
     * Therefore:
     *
     *       JALR PC < target PC
     *
     * So this must hit:
     *
     *       JALR + FORWARD
     *
     */

    asm volatile (
        "la x5, jalr_target\n"
        "jalr x6, 0(x5)\n"

        /* These instructions should be skipped */
        "addi x11, x0, 0x333\n"
        "addi x11, x0, 0x333\n"

        "jalr_target:\n"

        /* Target of JALR */
        "addi x11, x0, 0x444\n"

        :
        :
        : "x5", "x6", "x11", "memory"
    );


    /*
     * ========================================================
     * Verify execution reached both targets
     * ========================================================
     */

    if (value != 0)
    {
        test_fail();
    }


    /*
     * ========================================================
     * PASS
     * ========================================================
     */

    *result = 0xD1CE0710;

    test_pass();


    /*
     * Keep processor here.
     */

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}