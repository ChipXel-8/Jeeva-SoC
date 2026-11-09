#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * ALU SHIFT BOUNDARY TEST
     * ============================================================
     */

    asm volatile(

        /*
         * SLL
         */
        "li x5, 0x00000001\n"

        "li x6, 0\n"
        "sll x7, x5, x6\n"

        "li x6, 1\n"
        "sll x7, x5, x6\n"

        "li x6, 2\n"
        "sll x7, x5, x6\n"

        "li x6, 7\n"
        "sll x7, x5, x6\n"

        "li x6, 8\n"
        "sll x7, x5, x6\n"

        "li x6, 15\n"
        "sll x7, x5, x6\n"

        "li x6, 16\n"
        "sll x7, x5, x6\n"

        "li x6, 23\n"
        "sll x7, x5, x6\n"

        "li x6, 24\n"
        "sll x7, x5, x6\n"

        "li x6, 30\n"
        "sll x7, x5, x6\n"

        "li x6, 31\n"
        "sll x7, x5, x6\n"


        /*
         * SRL
         */
        "li x5, 0x80000000\n"

        "li x6, 0\n"
        "srl x7, x5, x6\n"

        "li x6, 1\n"
        "srl x7, x5, x6\n"

        "li x6, 2\n"
        "srl x7, x5, x6\n"

        "li x6, 7\n"
        "srl x7, x5, x6\n"

        "li x6, 8\n"
        "srl x7, x5, x6\n"

        "li x6, 15\n"
        "srl x7, x5, x6\n"

        "li x6, 16\n"
        "srl x7, x5, x6\n"

        "li x6, 23\n"
        "srl x7, x5, x6\n"

        "li x6, 24\n"
        "srl x7, x5, x6\n"

        "li x6, 30\n"
        "srl x7, x5, x6\n"

        "li x6, 31\n"
        "srl x7, x5, x6\n"


        /*
         * SRA negative number
         */
        "li x5, 0x80000000\n"

        "li x6, 0\n"
        "sra x7, x5, x6\n"

        "li x6, 1\n"
        "sra x7, x5, x6\n"

        "li x6, 2\n"
        "sra x7, x5, x6\n"

        "li x6, 7\n"
        "sra x7, x5, x6\n"

        "li x6, 8\n"
        "sra x7, x5, x6\n"

        "li x6, 15\n"
        "sra x7, x5, x6\n"

        "li x6, 16\n"
        "sra x7, x5, x6\n"

        "li x6, 23\n"
        "sra x7, x5, x6\n"

        "li x6, 24\n"
        "sra x7, x5, x6\n"

        "li x6, 30\n"
        "sra x7, x5, x6\n"

        "li x6, 31\n"
        "sra x7, x5, x6\n"

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