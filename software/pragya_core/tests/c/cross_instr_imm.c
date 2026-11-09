#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA CROSS INSTRUCTION x IMMEDIATE TEST
 * ============================================================
 *
 * Immediate patterns:
 *
 *     NEGATIVE
 *     ZERO
 *     POSITIVE
 *     LARGE
 *
 * IMPORTANT:
 *
 * For memory instructions the effective address is controlled
 * explicitly so that:
 *
 *     LB/LBU/SB  -> any byte address
 *     LH/LHU/SH  -> 2-byte aligned
 *     LW/SW      -> 4-byte aligned
 *
 * DO NOT use:
 *
 *     lw  ..., -1(...)
 *     lw  ..., -2(...)
 *     lw  ..., -3(...)
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


/*
 * Prevent compiler from removing operations.
 */
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

    mem32[8] = 0xdddddddd;
    mem32[9] = 0xeeeeeeee;
}


/*
 * ============================================================
 * ADDI
 * ============================================================
 */

static void test_addi(void)
{
    asm volatile(

        /* NEGATIVE */
        "addi t0, zero, -1\n"

        /* ZERO */
        "addi t0, zero, 0\n"

        /* POSITIVE */
        "addi t0, zero, 1\n"

        /* LARGE POSITIVE */
        "addi t0, zero, 2047\n"

        /* LARGE NEGATIVE */
        "addi t0, zero, -2048\n"

        :
        :
        : "t0"
    );
}


/*
 * ============================================================
 * SLTI
 * ============================================================
 */

static void test_slti(void)
{
    asm volatile(

        "addi t0, zero, 10\n"

        /* NEGATIVE */
        "slti t1, t0, -1\n"

        /* ZERO */
        "slti t1, t0, 0\n"

        /* POSITIVE */
        "slti t1, t0, 1\n"

        /* LARGE */
        "slti t1, t0, 2047\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * SLTIU
 * ============================================================
 */

static void test_sltiu(void)
{
    asm volatile(

        "addi t0, zero, 10\n"

        /* NEGATIVE */
        "sltiu t1, t0, -1\n"

        /* ZERO */
        "sltiu t1, t0, 0\n"

        /* POSITIVE */
        "sltiu t1, t0, 1\n"

        /* LARGE */
        "sltiu t1, t0, 2047\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * XORI
 * ============================================================
 */

static void test_xori(void)
{
    asm volatile(

        "addi t0, zero, 0x55\n"

        /* NEGATIVE */
        "xori t1, t0, -1\n"

        /* ZERO */
        "xori t1, t0, 0\n"

        /* POSITIVE */
        "xori t1, t0, 1\n"

        /* LARGE */
        "xori t1, t0, 2047\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * ORI
 * ============================================================
 */

static void test_ori(void)
{
    asm volatile(

        "addi t0, zero, 0x55\n"

        /* NEGATIVE */
        "ori t1, t0, -1\n"

        /* ZERO */
        "ori t1, t0, 0\n"

        /* POSITIVE */
        "ori t1, t0, 1\n"

        /* LARGE */
        "ori t1, t0, 2047\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * ANDI
 * ============================================================
 */

static void test_andi(void)
{
    asm volatile(

        "addi t0, zero, 0x55\n"

        /* NEGATIVE */
        "andi t1, t0, -1\n"

        /* ZERO */
        "andi t1, t0, 0\n"

        /* POSITIVE */
        "andi t1, t0, 1\n"

        /* LARGE */
        "andi t1, t0, 2047\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * SHIFT IMMEDIATES
 * ============================================================
 */

static void test_shift(void)
{
    asm volatile(

        "addi t0, zero, 1\n"

        /* SLLI */
        "slli t1, t0, 0\n"
        "slli t1, t0, 1\n"
        "slli t1, t0, 31\n"

        /* SRLI */
        "srli t1, t0, 0\n"
        "srli t1, t0, 1\n"
        "srli t1, t0, 31\n"

        /* SRAI */
        "addi t0, zero, -1\n"
        "srai t1, t0, 0\n"
        "srai t1, t0, 1\n"
        "srai t1, t0, 31\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * LOAD TEST
 * ============================================================
 *
 * CRITICAL:
 *
 * We explicitly create aligned base addresses.
 *
 * ------------------------------------------------------------
 *
 * LB:
 *
 *     base = &mem8[1]
 *
 *     -1 -> mem8[0]
 *      0 -> mem8[1]
 *      1 -> mem8[2]
 *     15 -> mem8[16]
 *
 * ------------------------------------------------------------
 *
 * LH:
 *
 *     base = &mem16[1]
 *
 *     -2 -> mem16[0]
 *      0 -> mem16[1]
 *      2 -> mem16[2]
 *     20 -> mem16[11]
 *
 * ------------------------------------------------------------
 *
 * LW:
 *
 *     base = &mem32[1]
 *
 *     -4 -> mem32[0]
 *      0 -> mem32[1]
 *      4 -> mem32[2]
 *     20 -> mem32[6]
 *
 * NEVER use -1 for LW.
 *
 * ============================================================
 */

static void test_loads(void)
{
    asm volatile(

        /*
         * ====================================================
         * LB
         * ====================================================
         */

        "la t6, mem8\n"
        "addi t6, t6, 1\n"

        /* NEGATIVE */
        "lb t0, -1(t6)\n"

        /* ZERO */
        "lb t0, 0(t6)\n"

        /* POSITIVE */
        "lb t0, 1(t6)\n"

        /* LARGE */
        "lb t0, 15(t6)\n"


        /*
         * ====================================================
         * LBU
         * ====================================================
         */

        "la t6, mem8\n"
        "addi t6, t6, 1\n"

        /* NEGATIVE */
        "lbu t0, -1(t6)\n"

        /* ZERO */
        "lbu t0, 0(t6)\n"

        /* POSITIVE */
        "lbu t0, 1(t6)\n"

        /* LARGE */
        "lbu t0, 15(t6)\n"


        /*
         * ====================================================
         * LH
         * ====================================================
         */

        "la t6, mem16\n"
        "addi t6, t6, 2\n"

        /* NEGATIVE */
        "lh t0, -2(t6)\n"

        /* ZERO */
        "lh t0, 0(t6)\n"

        /* POSITIVE */
        "lh t0, 2(t6)\n"

        /* LARGE */
        "lh t0, 20(t6)\n"


        /*
         * ====================================================
         * LHU
         * ====================================================
         */

        "la t6, mem16\n"
        "addi t6, t6, 2\n"

        /* NEGATIVE */
        "lhu t0, -2(t6)\n"

        /* ZERO */
        "lhu t0, 0(t6)\n"

        /* POSITIVE */
        "lhu t0, 2(t6)\n"

        /* LARGE */
        "lhu t0, 20(t6)\n"


        /*
         * ====================================================
         * LW
         * ====================================================
         */

        "la t6, mem32\n"
        "addi t6, t6, 4\n"

        /* NEGATIVE: 4-byte aligned */
        "lw t0, -4(t6)\n"

        /* ZERO */
        "lw t0, 0(t6)\n"

        /* POSITIVE */
        "lw t0, 4(t6)\n"

        /* LARGE: 20-byte aligned */
        "lw t0, 20(t6)\n"

        :
        :
        : "t0", "t6", "memory"
    );
}


/*
 * ============================================================
 * STORE TEST
 * ============================================================
 */

static void test_stores(void)
{
    asm volatile(

        /*
         * ====================================================
         * SB
         * ====================================================
         */

        "la t6, mem8\n"
        "addi t6, t6, 1\n"
        "addi t0, zero, 0x55\n"

        /* NEGATIVE */
        "sb t0, -1(t6)\n"

        /* ZERO */
        "sb t0, 0(t6)\n"

        /* POSITIVE */
        "sb t0, 1(t6)\n"

        /* LARGE */
        "sb t0, 15(t6)\n"


        /*
         * ====================================================
         * SH
         * ====================================================
         */

        "la t6, mem16\n"
        "addi t6, t6, 2\n"
        "lui t0, 0x12345\n"
        "addi t0, t0, 0x678\n"

        /* NEGATIVE */
        "sh t0, -2(t6)\n"

        /* ZERO */
        "sh t0, 0(t6)\n"

        /* POSITIVE */
        "sh t0, 2(t6)\n"

        /* LARGE */
        "sh t0, 20(t6)\n"


        /*
         * ====================================================
         * SW
         * ====================================================
         */

        "la t6, mem32\n"
        "addi t6, t6, 4\n"

        "lui t0, 0x12345\n"
        "addi t0, t0, 0x678\n"

        /* NEGATIVE: aligned */
        "sw t0, -4(t6)\n"

        /* ZERO */
        "sw t0, 0(t6)\n"

        /* POSITIVE */
        "sw t0, 4(t6)\n"

        /* LARGE: aligned */
        "sw t0, 20(t6)\n"

        :
        :
        : "t0", "t6", "memory"
    );
}


/*
 * ============================================================
 * BRANCH TEST
 * ============================================================
 */

static void test_branches(void)
{
    asm volatile(

        "addi t0, zero, 10\n"
        "addi t1, zero, 20\n"


        /*
         * ====================================================
         * BEQ
         * ====================================================
         */

        /* POSITIVE */
        "beq t0, t1, beq_pos\n"
        "addi t2, zero, 1\n"
        "beq_pos:\n"


        /*
         * ====================================================
         * BNE
         * ====================================================
         */

        /* POSITIVE */
        "bne t0, t1, bne_pos\n"
        "addi t2, zero, 2\n"
        "bne_pos:\n"


        /*
         * ====================================================
         * BLT
         * ====================================================
         */

        /* POSITIVE */
        "blt t0, t1, blt_pos\n"
        "addi t2, zero, 3\n"
        "blt_pos:\n"


        /*
         * ====================================================
         * BGE
         * ====================================================
         */

        /* POSITIVE */
        "bge t1, t0, bge_pos\n"
        "addi t2, zero, 4\n"
        "bge_pos:\n"


        /*
         * ====================================================
         * BLTU
         * ====================================================
         */

        /* POSITIVE */
        "bltu t0, t1, bltu_pos\n"
        "addi t2, zero, 5\n"
        "bltu_pos:\n"


        /*
         * ====================================================
         * BGEU
         * ====================================================
         */

        /* POSITIVE */
        "bgeu t1, t0, bgeu_pos\n"
        "addi t2, zero, 6\n"
        "bgeu_pos:\n"


        /*
         * Negative branch displacement.
         *
         * These branches are NOT taken so execution does not
         * loop forever.
         */

        "bne t0, t0, beq_neg\n"
        "addi t2, zero, 7\n"
        "beq_neg:\n"

        "beq t0, t1, bne_neg\n"
        "addi t2, zero, 8\n"
        "bne_neg:\n"

        :
        :
        : "t0", "t1", "t2"
    );
}


/*
 * ============================================================
 * LUI
 * ============================================================
 */

static void test_lui(void)
{
    asm volatile(

        /* NEGATIVE */
        "lui t0, 0xfffff\n"

        /* ZERO */
        "lui t0, 0x00000\n"

        /* POSITIVE */
        "lui t0, 0x00001\n"

        /* LARGE */
        "lui t0, 0x12345\n"

        :
        :
        : "t0"
    );
}


/*
 * ============================================================
 * AUIPC
 * ============================================================
 */

static void test_auipc(void)
{
    asm volatile(

        /* NEGATIVE */
        "auipc t0, 0xfffff\n"

        /* ZERO */
        "auipc t0, 0x00000\n"

        /* POSITIVE */
        "auipc t0, 0x00001\n"

        /* LARGE */
        "auipc t0, 0x12345\n"

        :
        :
        : "t0"
    );
}


/*
 * ============================================================
 * JAL
 * ============================================================
 */

static void test_jal(void)
{
    asm volatile(

        /*
         * Small positive
         */
        "jal t0, jal_1\n"
        "addi t1, zero, 0\n"
        "jal_1:\n"


        /*
         * Larger positive
         */
        "jal t0, jal_2\n"

        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"
        "addi t1, zero, 0\n"

        "jal_2:\n"

        :
        :
        : "t0", "t1"
    );
}


/*
 * ============================================================
 * JALR
 * ============================================================
 *
 * Keep target addresses aligned.
 * ============================================================
 */

static void test_jalr(void)
{
    asm volatile(

        /*
         * ZERO
         */
        "la t6, jalr_zero\n"
        "jalr t0, 0(t6)\n"

        "jalr_zero:\n"
        "addi t1, zero, 1\n"


        /*
         * POSITIVE
         *
         * base = target - 4
         * immediate = +4
         */
        "la t6, jalr_pos\n"
        "addi t6, t6, -4\n"
        "jalr t0, 4(t6)\n"

        "jalr_pos:\n"
        "addi t1, zero, 2\n"


        /*
         * NEGATIVE
         *
         * base = target + 4
         * immediate = -4
         */
        "la t6, jalr_neg\n"
        "addi t6, t6, 4\n"
        "jalr t0, -4(t6)\n"

        "jalr_neg:\n"
        "addi t1, zero, 3\n"

        :
        :
        : "t0", "t1", "t6"
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

    test_addi();

    test_slti();

    test_sltiu();

    test_xori();

    test_ori();

    test_andi();

    test_shift();

    test_loads();

    test_stores();

    test_branches();

    test_lui();

    test_auipc();

    test_jal();

    test_jalr();

    test_pass();

    return 0;
}