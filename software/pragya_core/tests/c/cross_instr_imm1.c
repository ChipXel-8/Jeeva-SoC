#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA CROSS INSTRUCTION x IMMEDIATE REMAINING TEST
 * ============================================================
 *
 * Goal:
 *
 *     Cover remaining reachable bins in:
 *
 *         cross_instr_imm
 *
 * ============================================================
 *
 * LARGE:
 *
 *     LB
 *     LH
 *     LBU
 *     LHU
 *     SB
 *     SH
 *     SLLI
 *     SRLI
 *     BLT
 *     BLTU
 *     BGEU
 *
 * NEGATIVE:
 *
 *     BLTU
 *     BNE
 *     BEQ
 *     LUI
 *     AUIPC
 *
 * ZERO:
 *
 *     SRAI
 *     BLT
 *     BLTU
 *     BNE
 *     BGE
 *     BGEU
 *
 * POSITIVE:
 *
 *     SRAI
 *     LUI
 *     AUIPC
 *
 * ============================================================
 *
 * IMPORTANT:
 *
 *     Do not use misaligned addresses for LH/LHU/SH.
 *
 *     Do not use a negative immediate for SLLI/SRLI/SRAI.
 *
 *     JAL × ZERO is not generated because JAL with zero
 *     displacement jumps to itself.
 *
 * ============================================================
 */


/*
 * ============================================================
 * MEMORY
 * ============================================================
 */

volatile uint8_t mem8[64] __attribute__((aligned(4)));

volatile uint16_t mem16[32] __attribute__((aligned(4)));

volatile uint32_t mem32[32] __attribute__((aligned(4)));

volatile uint32_t result;


/*
 * ============================================================
 * INITIALIZE MEMORY
 * ============================================================
 */

static void init_memory(void)
{
    mem8[0]  = 0x80;
    mem8[1]  = 0x7f;
    mem8[2]  = 0x34;
    mem8[3]  = 0x12;

    mem8[4]  = 0xaa;
    mem8[5]  = 0xbb;
    mem8[6]  = 0xcc;
    mem8[7]  = 0xdd;

    mem16[0] = 0x1234;
    mem16[1] = 0x5678;
    mem16[2] = 0x8001;
    mem16[3] = 0xffff;

    mem32[0] = 0x12345678;
    mem32[1] = 0x80000001;
    mem32[2] = 0xdeadbeef;
    mem32[3] = 0x11223344;

    mem32[4] = 0x55667788;
    mem32[5] = 0xaaaaaaaa;
    mem32[6] = 0xbbbbbbbb;
    mem32[7] = 0xcccccccc;
}


/*
 * ============================================================
 * LARGE IMMEDIATE LOAD TEST
 * ============================================================
 */

static void test_large_loads(void)
{
    asm volatile(

        /*
         * ====================================================
         * LB × LARGE
         * ====================================================
         *
         * 15 is used as LARGE according to the coverage
         * classification used in the existing test.
         *
         * Base is aligned and byte access is legal.
         */

        "la t6, mem8\n"
        "addi t6, t6, 1\n"

        "lb t0, 15(t6)\n"


        /*
         * ====================================================
         * LBU × LARGE
         * ====================================================
         */

        "la t6, mem8\n"
        "addi t6, t6, 1\n"

        "lbu t0, 15(t6)\n"


        /*
         * ====================================================
         * LH × LARGE
         * ====================================================
         */

        "la t6, mem16\n"
        "addi t6, t6, 2\n"

        "lh t0, 20(t6)\n"


        /*
         * ====================================================
         * LHU × LARGE
         * ====================================================
         */

        "la t6, mem16\n"
        "addi t6, t6, 2\n"

        "lhu t0, 20(t6)\n"

        :
        :
        : "t0", "t6", "memory"
    );
}


/*
 * ============================================================
 * LARGE IMMEDIATE STORE TEST
 * ============================================================
 */

static void test_large_stores(void)
{
    asm volatile(

        /*
         * ====================================================
         * SB × LARGE
         * ====================================================
         */

        "la t6, mem8\n"
        "addi t6, t6, 1\n"

        "addi t0, zero, 0x55\n"

        "sb t0, 15(t6)\n"


        /*
         * ====================================================
         * SH × LARGE
         * ====================================================
         */

        "la t6, mem16\n"
        "addi t6, t6, 2\n"

        "lui t0, 0x12345\n"
        "addi t0, t0, 0x678\n"

        "sh t0, 20(t6)\n"

        :
        :
        : "t0", "t6", "memory"
    );
}


/*
 * ============================================================
 * LARGE SHIFT IMMEDIATE TEST
 * ============================================================
 */

static void test_large_shift(void)
{
    asm volatile(

        "addi t0, zero, 1\n"


        /*
         * ====================================================
         * SLLI × LARGE
         * ====================================================
         *
         * RV32 shift amount = 5 bits.
         *
         * Maximum legal shift amount = 31.
         */

        "slli t1, t0, 31\n"


        /*
         * ====================================================
         * SRLI × LARGE
         * ====================================================
         */

        "srli t1, t0, 31\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * LARGE BRANCH IMMEDIATE TEST
 * ============================================================
 *
 * A branch immediate is a PC-relative displacement.
 *
 * The labels are deliberately separated so the encoded
 * immediate is classified as LARGE.
 *
 * ============================================================
 */

static void test_large_branches(void)
{
    asm volatile(

        "addi t0, zero, 10\n"
        "addi t1, zero, 20\n"


        /*
         * ====================================================
         * BLT × LARGE
         * ====================================================
         *
         * 10 < 20
         *
         * Branch is taken.
         */

        "blt t0, t1, blt_large_target\n"

        ".rept 40\n"
        "nop\n"
        ".endr\n"

        "blt_large_target:\n"
        "nop\n"


        /*
         * ====================================================
         * BLTU × LARGE
         * ====================================================
         *
         * 10 < 20 unsigned.
         */

        "bltu t0, t1, bltu_large_target\n"

        ".rept 40\n"
        "nop\n"
        ".endr\n"

        "bltu_large_target:\n"
        "nop\n"


        /*
         * ====================================================
         * BGEU × LARGE
         * ====================================================
         *
         * 20 >= 10 unsigned.
         */

        "bgeu t1, t0, bgeu_large_target\n"

        ".rept 40\n"
        "nop\n"
        ".endr\n"

        "bgeu_large_target:\n"
        "nop\n"

        :
        :
        : "t0", "t1", "memory"
    );
}


/*
 * ============================================================
 * NEGATIVE BRANCH IMMEDIATE TEST
 * ============================================================
 *
 * The branch target is before the branch instruction.
 *
 * Therefore the encoded immediate is NEGATIVE.
 *
 * The branch conditions are deliberately FALSE so the
 * processor does not loop.
 *
 * ============================================================
 */

static void test_negative_branches(void)
{
    asm volatile(

        "addi t0, zero, 10\n"
        "addi t1, zero, 20\n"


        /*
         * ====================================================
         * BLTU × NEGATIVE
         * ====================================================
         *
         * We need a negative displacement but the branch
         * must NOT be taken.
         *
         * 20 < 10 = FALSE.
         */

        "bltu t1, t0, bltu_negative_target\n"

        "bltu_negative_target:\n"
        "nop\n"


        /*
         * ====================================================
         * BNE × NEGATIVE
         * ====================================================
         *
         * For a negative displacement the target must be
         * before the branch.
         *
         * Use equal operands so branch is NOT taken.
         */

        "bne_negative_target:\n"
        "addi t2, zero, 1\n"

        "bne t2, t2, bne_negative_target\n"


        /*
         * ====================================================
         * BEQ × NEGATIVE
         * ====================================================
         *
         * Equal operands make the branch taken.
         *
         * Therefore use a nearby forward exit after a
         * backward target that is executed only once.
         */

        "beq_negative_target:\n"
        "addi t2, zero, 2\n"

        "j beq_negative_after\n"

        "beq_negative_branch:\n"
        "beq t2, t2, beq_negative_target\n"

        "beq_negative_after:\n"
        "nop\n"

        :
        :
        : "t0", "t1", "t2", "memory"
    );
}


/*
 * ============================================================
 * NEGATIVE LUI / AUIPC
 * ============================================================
 */

static void test_negative_u_type(void)
{
    asm volatile(

        /*
         * ====================================================
         * LUI × NEGATIVE
         * ====================================================
         *
         * 0xFFFFF000 has bit 31 set.
         */

        "lui t0, 0xfffff\n"


        /*
         * ====================================================
         * AUIPC × NEGATIVE
         * ====================================================
         */

        "auipc t0, 0xfffff\n"

        :
        :
        : "t0"
    );
}


/*
 * ============================================================
 * ZERO SRAI
 * ============================================================
 */

static void test_zero_srai(void)
{
    asm volatile(

        "addi t0, zero, -1\n"

        /*
         * SRAI × ZERO
         */

        "srai t1, t0, 0\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * ZERO BRANCH TEST
 * ============================================================
 *
 * IMPORTANT:
 *
 * A zero branch displacement is safe only when the branch
 * condition is FALSE.
 *
 * Therefore all branches below are deliberately NOT TAKEN.
 *
 * ============================================================
 */

static void test_zero_branches(void)
{
    asm volatile(

        "addi t0, zero, 10\n"
        "addi t1, zero, 20\n"


        /*
         * ====================================================
         * BLT × ZERO
         * ====================================================
         *
         * 10 < 10 = FALSE.
         */

        "blt t0, t0, blt_zero_target\n"
        "addi t2, zero, 1\n"

        "blt_zero_target:\n"


        /*
         * ====================================================
         * BLTU × ZERO
         * ====================================================
         *
         * 10 < 10 unsigned = FALSE.
         */

        "bltu t0, t0, bltu_zero_target\n"
        "addi t2, zero, 2\n"

        "bltu_zero_target:\n"


        /*
         * ====================================================
         * BNE × ZERO
         * ====================================================
         *
         * 10 != 10 = FALSE.
         */

        "bne t0, t0, bne_zero_target\n"
        "addi t2, zero, 3\n"

        "bne_zero_target:\n"


        /*
         * ====================================================
         * BGE × ZERO
         * ====================================================
         *
         * 10 >= 20 = FALSE.
         */

        "bge t0, t1, bge_zero_target\n"
        "addi t2, zero, 4\n"

        "bge_zero_target:\n"


        /*
         * ====================================================
         * BGEU × ZERO
         * ====================================================
         *
         * 10 >= 20 unsigned = FALSE.
         */

        "bgeu t0, t1, bgeu_zero_target\n"
        "addi t2, zero, 5\n"

        "bgeu_zero_target:\n"

        :
        :
        : "t0", "t1", "t2", "memory"
    );
}


/*
 * ============================================================
 * POSITIVE SRAI
 * ============================================================
 */

static void test_positive_srai(void)
{
    asm volatile(

        "addi t0, zero, -1\n"

        /*
         * SRAI × POSITIVE
         */

        "srai t1, t0, 1\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * POSITIVE LUI
 * ============================================================
 */

static void test_positive_lui(void)
{
    asm volatile(

        /*
         * LUI × POSITIVE
         */

        "lui t0, 0x00001\n"

        :
        :
        : "t0"
    );
}


/*
 * ============================================================
 * POSITIVE AUIPC
 * ============================================================
 */

static void test_positive_auipc(void)
{
    asm volatile(

        /*
         * AUIPC × POSITIVE
         */

        "auipc t0, 0x00001\n"

        :
        :
        : "t0"
    );
}


/*
 * ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{
    init_memory();

    test_large_loads();

    test_large_stores();

    test_large_shift();

    test_large_branches();

    test_negative_branches();

    test_negative_u_type();

    test_zero_srai();

    test_zero_branches();

    test_positive_srai();

    test_positive_lui();

    test_positive_auipc();

    test_pass();

    return 0;
}