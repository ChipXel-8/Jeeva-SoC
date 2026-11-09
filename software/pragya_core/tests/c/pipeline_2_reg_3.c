#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * PIPELINE BUBBLE / CONTROL TRANSITION TEST
     * ============================================================
     */

    asm volatile(
        "li x5, 0\n"

        /*
         * Taken branch.
         */
        "beq x5, x0, 1f\n"

        /*
         * Instructions which should be flushed/skipped.
         */
        "li x6, 0xAAAAAAAA\n"
        "li x7, 0xAAAAAAAA\n"

        "1:\n"

        /*
         * Normal instructions after branch.
         */
        "li x6, 0x55555555\n"
        "li x7, 0xFFFFFFFF\n"

        /*
         * Another branch.
         */
        "bne x6, x7, 2f\n"

        "li x8, 0x11111111\n"

        "2:\n"
        "li x8, 0x22222222\n"

        /*
         * Jump.
         */
        "jal x1, 3f\n"

        "li x9, 0xAAAAAAAA\n"

        "3:\n"
        "li x9, 0x55555555\n"

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