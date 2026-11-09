#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * SIGNED / UNSIGNED COMPARISON TEST
     * ============================================================
     */

    asm volatile(

        /*
         * --------------------------------------------------------
         * SLT
         * --------------------------------------------------------
         */

        /* 0 < 1 */
        "li x5, 0\n"
        "li x6, 1\n"
        "slt x7, x5, x6\n"

        /* 1 < 0 */
        "li x5, 1\n"
        "li x6, 0\n"
        "slt x7, x5, x6\n"

        /* -1 < 0 */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0\n"
        "slt x7, x5, x6\n"

        /* 0 < -1 */
        "li x5, 0\n"
        "li x6, 0xFFFFFFFF\n"
        "slt x7, x5, x6\n"

        /* MIN_INT < 0 */
        "li x5, 0x80000000\n"
        "li x6, 0\n"
        "slt x7, x5, x6\n"

        /* 0 < MIN_INT */
        "li x5, 0\n"
        "li x6, 0x80000000\n"
        "slt x7, x5, x6\n"

        /* MAX_INT > 0 */
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0\n"
        "slt x7, x5, x6\n"

        /* MAX_INT < -1 */
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "slt x7, x5, x6\n"

        /* equal */
        "li x5, 0x80000000\n"
        "li x6, 0x80000000\n"
        "slt x7, x5, x6\n"


        /*
         * --------------------------------------------------------
         * SLTU
         * --------------------------------------------------------
         */

        /* 0 < 1 */
        "li x5, 0\n"
        "li x6, 1\n"
        "sltu x7, x5, x6\n"

        /* 1 < 0 */
        "li x5, 1\n"
        "li x6, 0\n"
        "sltu x7, x5, x6\n"

        /* 0 < FFFFFFFF */
        "li x5, 0\n"
        "li x6, 0xFFFFFFFF\n"
        "sltu x7, x5, x6\n"

        /* FFFFFFFF < 0 */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0\n"
        "sltu x7, x5, x6\n"

        /* 7FFFFFFF < 80000000 */
        "li x5, 0x7FFFFFFF\n"
        "li x6, 0x80000000\n"
        "sltu x7, x5, x6\n"

        /* 80000000 < 7FFFFFFF */
        "li x5, 0x80000000\n"
        "li x6, 0x7FFFFFFF\n"
        "sltu x7, x5, x6\n"

        /* equal */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "sltu x7, x5, x6\n"

        :
        :
        : "memory"
    );

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