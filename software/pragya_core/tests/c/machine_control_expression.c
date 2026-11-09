#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    /*
     * ============================================================
     * MACHINE CONTROL EXPRESSION COVERAGE TEST
     * ============================================================
     *
     * Targets:
     *
     * 1. MRET rs1_addr_zero_0
     * 2. MRET FUNCT3_zero_0
     * 3. MRET rd_zero_0
     * 4. ECALL FUNCT7_zero_0
     * 5. EBREAK FUNCT7_zero_0
     *
     * All are deliberately malformed SYSTEM instructions.
     * They should enter the illegal-instruction trap path
     * and then continue through trap handling.
     * ============================================================
     */

    /*
     * ------------------------------------------------------------
     * MRET with rs1 = x1
     *
     * Normal:
     *     30200073
     *
     * Test:
     *     30208073
     *
     * Targets:
     *     rs1_addr_zero_0
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x30208073\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * MRET with funct3 = 001
     *
     * Normal:
     *     30200073
     *
     * Test:
     *     30201073
     *
     * Targets:
     *     FUNCT3_zero_0
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x30201073\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * MRET with rd = x1
     *
     * Normal:
     *     30200073
     *
     * Test:
     *     302000f3
     *
     * Targets:
     *     rd_zero_0
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x302000f3\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * ECALL-like SYSTEM instruction with non-zero funct7
     *
     * Normal ECALL:
     *     00000073
     *
     * Test:
     *     02000073
     *
     * Targets:
     *     FUNCT7_zero_0
     * in ECALL expression.
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x02000073\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * EBREAK-like SYSTEM instruction with non-zero funct7
     *
     * Normal EBREAK:
     *     00100073
     *
     * Test:
     *     02100073
     *
     * Targets:
     *     FUNCT7_zero_0
     * in EBREAK expression.
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x02100073\n"
        :
        :
        : "memory"
    );


    /*
     * Normal instructions after traps.
     *
     * This confirms that trap handling returns correctly.
     */

    asm volatile(
        "li x5, 0x1234\n"
        "li x6, 0x5678\n"
        "add x7, x5, x6\n"
        "sub x8, x7, x5\n"
        :
        :
        : "memory"
    );

    sink = 0xCAFEBABE;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}