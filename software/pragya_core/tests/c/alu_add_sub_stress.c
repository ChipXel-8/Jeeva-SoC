#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * ADD / SUB CARRY AND BORROW STRESS
     * ============================================================
     */

    asm volatile(

        /*
         * ADD carry propagation
         */
        "li x5, 0x00000001\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        "li x5, 0x0000FFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        "li x5, 0x00FFFFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        "li x5, 0x0FFFFFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        "li x5, 0x7FFFFFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"

        "li x5, 0xFFFFFFFF\n"
        "li x6, 0x00000001\n"
        "add x7, x5, x6\n"


        /*
         * SUB borrow propagation
         */
        "li x5, 0x00000000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        "li x5, 0x00010000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        "li x5, 0x00100000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        "li x5, 0x01000000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        "li x5, 0x10000000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        "li x5, 0x80000000\n"
        "li x6, 0x00000001\n"
        "sub x7, x5, x6\n"

        /*
         * Maximum/minimum
         */
        "li x5, 0xFFFFFFFF\n"
        "li x6, 0xFFFFFFFF\n"
        "sub x7, x5, x6\n"

        "li x5, 0x00000000\n"
        "li x6, 0xFFFFFFFF\n"
        "sub x7, x5, x6\n"

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