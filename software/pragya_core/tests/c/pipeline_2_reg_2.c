#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;


/*
 * ============================================================
 * PIPELINE-2 PC HIGH-BIT TOGGLE TEST
 *
 * Target:
 *
 *   pc_reg_out[15:30]
 *   pc_plus_4_reg_out[15:30]
 *
 * Also exercises:
 *
 *   JAL
 *   JALR
 *   PC+4
 *   instruction register
 *   rd
 * ============================================================
 */


/*
 * ------------------------------------------------------------
 * First code region
 * ------------------------------------------------------------
 */

__attribute__((section(".text")))
static void region_low(void)
{
    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        "xor x8, x5, x6\n"
        "or  x9, x5, x6\n"
        "and x10, x5, x6\n"
        :
        :
        : "memory"
    );
}


/*
 * ------------------------------------------------------------
 * Main
 * ------------------------------------------------------------
 */

int main(void)
{
    uint32_t value;

    /*
     * Normal instructions
     */

    asm volatile(
        "li x5, 0\n"
        "li x6, 1\n"
        "add x7, x5, x6\n"
        "addi x7, x7, 1\n"
        "addi x7, x7, 1\n"
        :
        :
        : "memory"
    );


    /*
     * Call first region.
     */

    region_low();


    /*
     * --------------------------------------------------------
     * Large instruction-memory spacing
     *
     * The purpose is to make the executable contain code at
     * a substantially different PC address.
     * --------------------------------------------------------
     */

    asm volatile(
        "jal x1, high_region\n"
        :
        :
        : "memory"
    );


    /*
     * These instructions should be skipped by JAL.
     */

    asm volatile(
        "li x20, 0xaaaaaaaa\n"
        "li x21, 0xbbbbbbbb\n"
        :
        :
        : "memory"
    );


    /*
     * --------------------------------------------------------
     * Return
     * --------------------------------------------------------
     */

    value = 0x12345678;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}


/*
 * ============================================================
 * HIGH PC REGION
 *
 * Force linker to place this function far enough away from
 * the beginning of the program.
 * ============================================================
 */

__attribute__((noinline, used))
void high_region(void)
{
    asm volatile(
        "li x5,  0xaaaaaaaa\n"
        "li x6,  0x55555555\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "xor x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "and x11, x5, x6\n"

        "li x12, 0x80000000\n"
        "li x13, 0x7fffffff\n"

        "add x14, x12, x13\n"
        "sub x15, x12, x13\n"

        :
        :
        : "memory"
    );
}