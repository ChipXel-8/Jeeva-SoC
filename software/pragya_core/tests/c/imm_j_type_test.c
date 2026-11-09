#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * IMMEDIATE GENERATOR - J TYPE TEST
     *
     * Exercises:
     *
     *   imm_src = 3'b101
     *   j_type
     *
     * J-type:
     *
     *   imm[20]    = instr[31]
     *   imm[10:1]  = instr[30:21]
     *   imm[11]    = instr[20]
     *   imm[19:12] = instr[19:12]
     *   imm[0]     = 0
     *
     * ============================================================
     */

    /*
     * JAL forward.
     */

    asm volatile(
        "jal x1, jump_1\n"

        "li x5, 0xAAAAAAAA\n"

        "jump_1:\n"
        "li x6, 0x12345678\n"
        :
        :
        : "memory"
    );


    /*
     * Second JAL.
     */

    asm volatile(
        "jal x1, jump_2\n"

        "li x5, 0x11111111\n"

        "jump_2:\n"
        "li x6, 0x87654321\n"
        :
        :
        : "memory"
    );


    /*
     * Use JAL with x0.
     *
     * This still generates a J-type immediate.
     */

    asm volatile(
        "jal x0, jump_3\n"

        "li x5, 0x55555555\n"

        "jump_3:\n"
        "li x6, 0xAAAAAAAA\n"
        :
        :
        : "memory"
    );


    value = 0xCAFEBABE;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}