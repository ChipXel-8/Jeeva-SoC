#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA CROSS INSTRUCTION x IMMEDIATE REMAINING TEST
 * ============================================================
 *
 * Remaining reachable bins:
 *
 * NEGATIVE:
 *     BLTU × NEGATIVE
 *     BEQ  × NEGATIVE
 *
 * LARGE:
 *     SH  × LARGE
 *     SB  × LARGE
 *     LBU × LARGE
 *     LH  × LARGE
 *     LHU × LARGE
 *     LB  × LARGE
 *
 * ZERO:
 *     BLTU × ZERO
 *     BLT  × ZERO
 *     BNE  × ZERO
 *     BGEU × ZERO
 *     BEQ  × ZERO
 *     BGE  × ZERO
 *
 * Intentionally ignored:
 *
 *     LUI   × NEGATIVE
 *     AUIPC × NEGATIVE
 *     JAL   × ZERO
 *
 * ============================================================
 */


/*
 * ============================================================
 * MEMORY
 * ============================================================
 *
 * Make the arrays large enough for offset 128.
 * ============================================================
 */

volatile uint8_t  mem8[256]  __attribute__((aligned(4)));
volatile uint16_t mem16[128] __attribute__((aligned(4)));
volatile uint32_t mem32[64]  __attribute__((aligned(4)));

volatile uint32_t result;


/*
 * ============================================================
 * INITIALIZE MEMORY
 * ============================================================
 */

static void init_memory(void)
{
    /*
     * BYTE MEMORY
     */

    mem8[0]   = 0x11;
    mem8[1]   = 0x22;
    mem8[2]   = 0x33;
    mem8[3]   = 0x44;

    mem8[128] = 0xAA;
    mem8[129] = 0xBB;
    mem8[130] = 0xCC;
    mem8[131] = 0xDD;


    /*
     * HALF-WORD MEMORY
     */

    mem16[0]  = 0x1234;
    mem16[1]  = 0x5678;
    mem16[2]  = 0x8001;
    mem16[3]  = 0xFFFF;

    mem16[64] = 0x1234;
    mem16[65] = 0x5678;
    mem16[66] = 0x8001;


    /*
     * WORD MEMORY
     */

    mem32[0] = 0x12345678;
    mem32[1] = 0x87654321;
    mem32[2] = 0xDEADBEEF;
    mem32[3] = 0x11223344;
}


/*
 * ============================================================
 * NEGATIVE IMMEDIATE
 * ============================================================
 *
 * Required:
 *
 *     BLTU × NEGATIVE
 *     BEQ  × NEGATIVE
 *
 * We use an offset of -4.
 *
 * -4 = 0xFFFFFFFC
 *
 * Your coverage classifier considers this NEGATIVE because:
 *
 *     0xFFFFFF80 <= 0xFFFFFFFC
 *
 * and bit 31 = 1.
 *
 * The branch condition is deliberately FALSE so that the
 * processor does not actually jump backward.
 *
 * ============================================================
 */

static void test_negative_branches(void)
{
    asm volatile(

        /*
         * ----------------------------------------------------
         * BLTU × NEGATIVE
         * ----------------------------------------------------
         *
         * t0 = 20
         * t1 = 10
         *
         * 20 < 10 unsigned = FALSE
         *
         * Target is previous instruction.
         *
         * Immediate = -4
         */

        "addi t0, zero, 20\n"
        "addi t1, zero, 10\n"

        "bltu_neg_target:\n"
        "addi t2, zero, 1\n"

        "bltu t0, t1, bltu_neg_target\n"


        /*
         * ----------------------------------------------------
         * BEQ × NEGATIVE
         * ----------------------------------------------------
         *
         * 20 == 10 = FALSE
         *
         * Immediate = -4
         */

        "beq_neg_target:\n"
        "addi t2, zero, 2\n"

        "beq t0, t1, beq_neg_target\n"

        :
        :
        : "t0", "t1", "t2", "memory"
    );
}


/*
 * ============================================================
 * LARGE LOADS
 * ============================================================
 *
 * IMPORTANT:
 *
 * Your coverage classifier defines:
 *
 *     0x00       -> ZERO
 *     0x01-0x7F  -> POSITIVE
 *     0xFFFFFF80-FFFFFFFF -> NEGATIVE
 *     everything else -> LARGE
 *
 * Therefore:
 *
 *     128 = 0x80
 *
 * is LARGE.
 *
 * We deliberately use 128 and 130.
 *
 * ============================================================
 */

static void test_large_loads(void)
{
    asm volatile(

        /*
         * ----------------------------------------------------
         * LB × LARGE
         * ----------------------------------------------------
         *
         * Immediate = 128
         */

        "la   t6, mem8\n"
        "lb   t0, 128(t6)\n"


        /*
         * ----------------------------------------------------
         * LBU × LARGE
         * ----------------------------------------------------
         *
         * Immediate = 129
         */

        "la   t6, mem8\n"
        "lbu  t0, 129(t6)\n"


        /*
         * ----------------------------------------------------
         * LH × LARGE
         * ----------------------------------------------------
         *
         * Immediate = 128
         *
         * 128 is half-word aligned.
         */

        "la   t6, mem16\n"
        "lh   t0, 128(t6)\n"


        /*
         * ----------------------------------------------------
         * LHU × LARGE
         * ----------------------------------------------------
         *
         * Immediate = 130
         *
         * 130 is half-word aligned.
         */

        "la   t6, mem16\n"
        "lhu  t0, 130(t6)\n"

        :
        :
        : "t0", "t6", "memory"
    );
}


/*
 * ============================================================
 * LARGE STORES
 * ============================================================
 *
 * Required:
 *
 *     SB × LARGE
 *     SH × LARGE
 *
 * ============================================================
 */

static void test_large_stores(void)
{
    asm volatile(

        /*
         * ----------------------------------------------------
         * SB × LARGE
         * ----------------------------------------------------
         *
         * Immediate = 128
         */

        "la   t6, mem8\n"
        "addi t0, zero, 0x55\n"
        "sb   t0, 128(t6)\n"


        /*
         * ----------------------------------------------------
         * SH × LARGE
         * ----------------------------------------------------
         *
         * Immediate = 128
         *
         * 128 is half-word aligned.
         */

        "la   t6, mem16\n"

        "lui  t0, 0x12345\n"
        "addi t0, t0, 0x678\n"

        "sh   t0, 128(t6)\n"

        :
        :
        : "t0", "t6", "memory"
    );
}


/*
 * ============================================================
 * ZERO IMMEDIATE BRANCHES
 * ============================================================
 *
 * We create:
 *
 *     label:
 *     branch ..., label
 *
 * Therefore:
 *
 *     branch offset = 0
 *
 * The conditions are deliberately FALSE so that the branch
 * does not loop.
 *
 * ============================================================
 */

static void test_zero_branches(void)
{
    asm volatile(

        /*
         * ----------------------------------------------------
         * BLTU × ZERO
         * ----------------------------------------------------
         *
         * t0 < t0 = FALSE
         */

        "bltu_zero_target:\n"
        "bltu t0, t0, bltu_zero_target\n"


        /*
         * ----------------------------------------------------
         * BLT × ZERO
         * ----------------------------------------------------
         *
         * t0 < t0 = FALSE
         */

        "blt_zero_target:\n"
        "blt t0, t0, blt_zero_target\n"


        /*
         * ----------------------------------------------------
         * BNE × ZERO
         * ----------------------------------------------------
         *
         * t0 != t0 = FALSE
         */

        "bne_zero_target:\n"
        "bne t0, t0, bne_zero_target\n"


        /*
         * ----------------------------------------------------
         * BGEU × ZERO
         * ----------------------------------------------------
         *
         * t0 = 10
         * t1 = 20
         *
         * 10 >= 20 unsigned = FALSE
         */

        "bgeu_zero_target:\n"
        "bgeu t0, t1, bgeu_zero_target\n"


        /*
         * ----------------------------------------------------
         * BEQ × ZERO
         * ----------------------------------------------------
         *
         * 10 == 20 = FALSE
         */

        "beq_zero_target:\n"
        "beq t0, t1, beq_zero_target\n"


        /*
         * ----------------------------------------------------
         * BGE × ZERO
         * ----------------------------------------------------
         *
         * 10 >= 20 = FALSE
         */

        "bge_zero_target:\n"
        "bge t0, t1, bge_zero_target\n"

        :
        :
        : "t0", "t1", "memory"
    );
}


/*
 * ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{
    /*
     * Initialize memory.
     */

    init_memory();


    /*
     * --------------------------------------------------------
     * NEGATIVE
     * --------------------------------------------------------
     */

    test_negative_branches();


    /*
     * --------------------------------------------------------
     * LARGE LOADS
     * --------------------------------------------------------
     */

    test_large_loads();


    /*
     * --------------------------------------------------------
     * LARGE STORES
     * --------------------------------------------------------
     */

    test_large_stores();


    /*
     * --------------------------------------------------------
     * ZERO BRANCHES
     * --------------------------------------------------------
     */

    /*
     * Set source registers.
     *
     * t0 = 10
     * t1 = 20
     */

    asm volatile(
        "addi t0, zero, 10\n"
        "addi t1, zero, 20\n"
        :
        :
        : "t0", "t1"
    );

    test_zero_branches();


    /*
     * --------------------------------------------------------
     * PASS
     * --------------------------------------------------------
     */

    test_pass();

    return 0;
}