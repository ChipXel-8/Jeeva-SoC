#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * CROSS WRITE-X0 TEST
 * ============================================================
 *
 * Goal:
 *
 *     Cover:
 *
 *         cp_write_x0
 *
 *     WRITE_X0:
 *
 *         rd = x0
 *         reg_write = 1
 *
 * IMPORTANT:
 *
 *     RISC-V x0 is hardwired to zero.
 *
 *     These instructions have a register-write DESTINATION
 *     of x0, but the register file must discard the write.
 *
 *     Therefore:
 *
 *         instruction rd = x0
 *         reg_write intent = 1
 *         actual x0 value remains 0
 *
 * ============================================================
 */


/*
 * ============================================================
 * SOURCE REGISTER SETUP
 * ============================================================
 */

static void setup_registers(void)
{
    asm volatile (

        "addi x5, x0, 20\n"
        "addi x6, x0, 5\n"
        "addi x7, x0, 2\n"

        /*
         * Allow values to propagate through the pipeline.
         */
        "nop\n"
        "nop\n"

        :
        :
        : "x5", "x6", "x7", "memory"
    );
}


/*
 * ============================================================
 * R-TYPE × WRITE_X0
 * ============================================================
 */

static void test_rtype_write_x0(void)
{
    asm volatile (

        /*
         * ADD
         *
         * rd = x0
         * reg_write = 1
         */

        "add  x0, x5, x6\n"
        "nop\n"
        "nop\n"


        /*
         * SUB
         */

        "sub  x0, x5, x6\n"
        "nop\n"
        "nop\n"


        /*
         * SLL
         */

        "sll  x0, x5, x7\n"
        "nop\n"
        "nop\n"


        /*
         * SLT
         */

        "slt  x0, x5, x6\n"
        "nop\n"
        "nop\n"


        /*
         * SLTU
         */

        "sltu x0, x5, x6\n"
        "nop\n"
        "nop\n"


        /*
         * XOR
         */

        "xor  x0, x5, x6\n"
        "nop\n"
        "nop\n"


        /*
         * SRL
         */

        "srl  x0, x5, x7\n"
        "nop\n"
        "nop\n"


        /*
         * SRA
         */

        "sra  x0, x5, x7\n"
        "nop\n"
        "nop\n"


        /*
         * OR
         */

        "or   x0, x5, x6\n"
        "nop\n"
        "nop\n"


        /*
         * AND
         */

        "and  x0, x5, x6\n"
        "nop\n"
        "nop\n"

        :
        :
        : "memory"
    );
}


/*
 * ============================================================
 * I-TYPE ALU × WRITE_X0
 * ============================================================
 */

static void test_itype_write_x0(void)
{
    asm volatile (

        /*
         * ADDI
         */

        "addi  x0, x5, 7\n"
        "nop\n"
        "nop\n"


        /*
         * SLTI
         */

        "slti  x0, x5, 30\n"
        "nop\n"
        "nop\n"


        /*
         * SLTIU
         */

        "sltiu x0, x5, 30\n"
        "nop\n"
        "nop\n"


        /*
         * XORI
         */

        "xori  x0, x5, 0x55\n"
        "nop\n"
        "nop\n"


        /*
         * ORI
         */

        "ori   x0, x5, 0x55\n"
        "nop\n"
        "nop\n"


        /*
         * ANDI
         */

        "andi  x0, x5, 0x0f\n"
        "nop\n"
        "nop\n"

        :
        :
        : "memory"
    );
}


/*
 * ============================================================
 * SHIFT-IMMEDIATE × WRITE_X0
 * ============================================================
 */

static void test_shift_write_x0(void)
{
    asm volatile (

        /*
         * SLLI
         */

        "slli x0, x5, 3\n"
        "nop\n"
        "nop\n"


        /*
         * SRLI
         */

        "srli x0, x5, 2\n"
        "nop\n"
        "nop\n"


        /*
         * SRAI
         */

        "srai x0, x5, 2\n"
        "nop\n"
        "nop\n"

        :
        :
        : "memory"
    );
}


/*
 * ============================================================
 * U-TYPE × WRITE_X0
 * ============================================================
 */

static void test_utype_write_x0(void)
{
    asm volatile (

        /*
         * LUI
         */

        "lui x0, 0x12345\n"
        "nop\n"
        "nop\n"


        /*
         * AUIPC
         */

        "auipc x0, 0x1\n"
        "nop\n"
        "nop\n"

        :
        :
        : "memory"
    );
}


/*
 * ============================================================
 * JAL × WRITE_X0
 * ============================================================
 *
 * JAL x0,target:
 *
 *     rd = x0
 *     reg_write intent = 1
 *
 * but x0 remains unchanged.
 *
 * ============================================================
 */

static void test_jal_write_x0(void)
{
    asm volatile (

        "jal x0, jal_x0_target\n"

        /*
         * Skipped.
         */

        "addi x7, x0, 0\n"

        "jal_x0_target:\n"

        "nop\n"
        "nop\n"

        :
        :
        : "memory"
    );
}


/*
 * ============================================================
 * JALR × WRITE_X0
 * ============================================================
 */

static void test_jalr_write_x0(void)
{
    asm volatile (

        /*
         * Get target address.
         */

        "la x5, jalr_x0_target\n"

        "nop\n"
        "nop\n"


        /*
         * JALR:
         *
         *     rd  = x0
         *     rs1 = x5
         *     imm = 0
         *
         * reg_write intent = 1
         *
         * actual x0 write = suppressed
         */

        "jalr x0, 0(x5)\n"

        /*
         * Skipped.
         */

        "addi x7, x0, 0\n"

        "jalr_x0_target:\n"

        "nop\n"
        "nop\n"

        :
        :
        : "memory"
    );
}


/*
 * ============================================================
 * VERIFY x0 IS STILL ZERO
 * ============================================================
 *
 * This is NOT required for the coverage bin itself.
 *
 * It verifies the architectural behavior:
 *
 *     attempted write to x0
 *             ↓
 *         x0 remains 0
 *
 * ============================================================
 */

static void verify_x0(void)
{
    uint32_t x0_value;

    asm volatile (
        "mv %0, x0\n"
        : "=r"(x0_value)
        :
        : "memory"
    );

    /*
     * x0 must always be zero.
     *
     * Do not use x0 as the destination of this check.
     */

    if (x0_value != 0)
        test_fail();
}


/*
 * ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{
    setup_registers();

    test_rtype_write_x0();

    test_itype_write_x0();

    test_shift_write_x0();

    test_utype_write_x0();

    test_jal_write_x0();

    test_jalr_write_x0();

    verify_x0();

    test_pass();

    return 0;
}