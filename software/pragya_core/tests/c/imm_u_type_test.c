#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * IMMEDIATE GENERATOR - U TYPE TEST
     *
     * Exercises:
     *
     *   imm_src = 3'b100
     *   u_type
     *
     * Instructions:
     *
     *   LUI
     *   AUIPC
     *
     * ============================================================
     */


    /*
     * LUI with different upper immediate patterns.
     */

    asm volatile(
        "lui x5, 0x12345\n"
        "lui x6, 0xABCDE\n"
        "lui x7, 0x55555\n"
        :
        :
        : "memory"
    );


    /*
     * AUIPC with different upper immediates.
     */

    asm volatile(
        "auipc x8, 0x11111\n"
        "auipc x9, 0x22222\n"
        "auipc x10, 0xAAAAA\n"
        :
        :
        : "memory"
    );


    /*
     * Test zero upper immediate.
     */

    asm volatile(
        "lui x11, 0x00000\n"
        "auipc x12, 0x00000\n"
        :
        :
        : "memory"
    );


    /*
     * Test maximum upper immediate.
     */

    asm volatile(
        "lui x13, 0xFFFFF\n"
        "auipc x14, 0xFFFFF\n"
        :
        :
        : "memory"
    );


    value = 0xDEADBEEF;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}