#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA RV32I CROSS INSTRUCTION / RD TEST
 *
 * Target:
 *
 *   cross_instr_rd
 *
 * Missing combinations:
 *
 *   LB   x1..x31
 *   LBU  x1..x31
 *   LH   x1..x31
 *   LHU  x1..x31
 *   LW   x1..x31
 *   JAL  x1..x31
 *   JALR x1..x31
 *
 * ============================================================
 */


/* ------------------------------------------------------------
 * Test memory
 * ------------------------------------------------------------ */

volatile uint32_t test_mem[8] __attribute__((aligned(4))) =
{
    0x80FF7F01,
    0x12345678,
    0xFFFFFFFF,
    0x00008001,
    0xA5A5A5A5,
    0x55AA55AA,
    0x00000000,
    0x7FFFFFFF
};


/* ------------------------------------------------------------
 * Dummy variable to keep memory live
 * ------------------------------------------------------------ */

volatile uint32_t result;


/* ============================================================
 * LOAD TEST MACROS
 *
 * The important instruction is the actual load instruction.
 *
 * x31 is used as the base address register.
 *
 * ============================================================
 */

#define DO_LB(RD)                                           \
    asm volatile (                                           \
        "la x31, test_mem\n"                                 \
        "lb x" #RD ", 0(x31)\n"                              \
        :                                                   \
        :                                                   \
        : "memory", "x31")


#define DO_LBU(RD)                                          \
    asm volatile (                                           \
        "la x31, test_mem\n"                                 \
        "lbu x" #RD ", 0(x31)\n"                             \
        :                                                   \
        :                                                   \
        : "memory", "x31")


#define DO_LH(RD)                                           \
    asm volatile (                                           \
        "la x31, test_mem\n"                                 \
        "lh x" #RD ", 0(x31)\n"                              \
        :                                                   \
        :                                                   \
        : "memory", "x31")


#define DO_LHU(RD)                                          \
    asm volatile (                                           \
        "la x31, test_mem\n"                                 \
        "lhu x" #RD ", 0(x31)\n"                             \
        :                                                   \
        :                                                   \
        : "memory", "x31")


#define DO_LW(RD)                                           \
    asm volatile (                                           \
        "la x31, test_mem\n"                                 \
        "lw x" #RD ", 0(x31)\n"                              \
        :                                                   \
        :                                                   \
        : "memory", "x31")


/* ============================================================
 * JAL
 *
 * Numeric local label is used.
 *
 * 1f means:
 *     first local label "1:" forward from here
 *
 * This can safely be expanded many times.
 * ============================================================
 */

#define DO_JAL(RD)                                          \
    asm volatile (                                           \
        "jal x" #RD ", 1f\n"                                 \
        "1:\n"                                               \
        :                                                   \
        :                                                   \
        : "memory")


/* ============================================================
 * JALR
 *
 * x31 contains the target address.
 *
 * Numeric local label avoids duplicate-symbol errors.
 *
 * ============================================================
 */

#define DO_JALR(RD)                                         \
    asm volatile (                                           \
        "la x31, 1f\n"                                       \
        "jalr x" #RD ", 0(x31)\n"                            \
        "1:\n"                                               \
        :                                                   \
        :                                                   \
        : "memory", "x31")


/* ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{

    /*
     * ========================================================
     * LB
     * ========================================================
     */

    DO_LB(1);
    DO_LB(2);
    DO_LB(3);
    DO_LB(4);
    DO_LB(5);
    DO_LB(6);
    DO_LB(7);
    DO_LB(8);
    DO_LB(9);
    DO_LB(10);
    DO_LB(11);
    DO_LB(12);
    DO_LB(13);
    DO_LB(14);
    DO_LB(15);
    DO_LB(16);
    DO_LB(17);
    DO_LB(18);
    DO_LB(19);
    DO_LB(20);
    DO_LB(21);
    DO_LB(22);
    DO_LB(23);
    DO_LB(24);
    DO_LB(25);
    DO_LB(26);
    DO_LB(27);
    DO_LB(28);
    DO_LB(29);
    DO_LB(30);
    DO_LB(31);


    /*
     * ========================================================
     * LBU
     * ========================================================
     */

    DO_LBU(1);
    DO_LBU(2);
    DO_LBU(3);
    DO_LBU(4);
    DO_LBU(5);
    DO_LBU(6);
    DO_LBU(7);
    DO_LBU(8);
    DO_LBU(9);
    DO_LBU(10);
    DO_LBU(11);
    DO_LBU(12);
    DO_LBU(13);
    DO_LBU(14);
    DO_LBU(15);
    DO_LBU(16);
    DO_LBU(17);
    DO_LBU(18);
    DO_LBU(19);
    DO_LBU(20);
    DO_LBU(21);
    DO_LBU(22);
    DO_LBU(23);
    DO_LBU(24);
    DO_LBU(25);
    DO_LBU(26);
    DO_LBU(27);
    DO_LBU(28);
    DO_LBU(29);
    DO_LBU(30);
    DO_LBU(31);


    /*
     * ========================================================
     * LH
     * ========================================================
     */

    DO_LH(1);
    DO_LH(2);
    DO_LH(3);
    DO_LH(4);
    DO_LH(5);
    DO_LH(6);
    DO_LH(7);
    DO_LH(8);
    DO_LH(9);
    DO_LH(10);
    DO_LH(11);
    DO_LH(12);
    DO_LH(13);
    DO_LH(14);
    DO_LH(15);
    DO_LH(16);
    DO_LH(17);
    DO_LH(18);
    DO_LH(19);
    DO_LH(20);
    DO_LH(21);
    DO_LH(22);
    DO_LH(23);
    DO_LH(24);
    DO_LH(25);
    DO_LH(26);
    DO_LH(27);
    DO_LH(28);
    DO_LH(29);
    DO_LH(30);
    DO_LH(31);


    /*
     * ========================================================
     * LHU
     * ========================================================
     */

    DO_LHU(1);
    DO_LHU(2);
    DO_LHU(3);
    DO_LHU(4);
    DO_LHU(5);
    DO_LHU(6);
    DO_LHU(7);
    DO_LHU(8);
    DO_LHU(9);
    DO_LHU(10);
    DO_LHU(11);
    DO_LHU(12);
    DO_LHU(13);
    DO_LHU(14);
    DO_LHU(15);
    DO_LHU(16);
    DO_LHU(17);
    DO_LHU(18);
    DO_LHU(19);
    DO_LHU(20);
    DO_LHU(21);
    DO_LHU(22);
    DO_LHU(23);
    DO_LHU(24);
    DO_LHU(25);
    DO_LHU(26);
    DO_LHU(27);
    DO_LHU(28);
    DO_LHU(29);
    DO_LHU(30);
    DO_LHU(31);


    /*
     * ========================================================
     * LW
     * ========================================================
     */

    DO_LW(1);
    DO_LW(2);
    DO_LW(3);
    DO_LW(4);
    DO_LW(5);
    DO_LW(6);
    DO_LW(7);
    DO_LW(8);
    DO_LW(9);
    DO_LW(10);
    DO_LW(11);
    DO_LW(12);
    DO_LW(13);
    DO_LW(14);
    DO_LW(15);
    DO_LW(16);
    DO_LW(17);
    DO_LW(18);
    DO_LW(19);
    DO_LW(20);
    DO_LW(21);
    DO_LW(22);
    DO_LW(23);
    DO_LW(24);
    DO_LW(25);
    DO_LW(26);
    DO_LW(27);
    DO_LW(28);
    DO_LW(29);
    DO_LW(30);
    DO_LW(31);


    /*
     * ========================================================
     * JAL
     * ========================================================
     */

    DO_JAL(1);
    DO_JAL(2);
    DO_JAL(3);
    DO_JAL(4);
    DO_JAL(5);
    DO_JAL(6);
    DO_JAL(7);
    DO_JAL(8);
    DO_JAL(9);
    DO_JAL(10);
    DO_JAL(11);
    DO_JAL(12);
    DO_JAL(13);
    DO_JAL(14);
    DO_JAL(15);
    DO_JAL(16);
    DO_JAL(17);
    DO_JAL(18);
    DO_JAL(19);
    DO_JAL(20);
    DO_JAL(21);
    DO_JAL(22);
    DO_JAL(23);
    DO_JAL(24);
    DO_JAL(25);
    DO_JAL(26);
    DO_JAL(27);
    DO_JAL(28);
    DO_JAL(29);
    DO_JAL(30);
    DO_JAL(31);


    /*
     * ========================================================
     * JALR
     * ========================================================
     */

    DO_JALR(1);
    DO_JALR(2);
    DO_JALR(3);
    DO_JALR(4);
    DO_JALR(5);
    DO_JALR(6);
    DO_JALR(7);
    DO_JALR(8);
    DO_JALR(9);
    DO_JALR(10);
    DO_JALR(11);
    DO_JALR(12);
    DO_JALR(13);
    DO_JALR(14);
    DO_JALR(15);
    DO_JALR(16);
    DO_JALR(17);
    DO_JALR(18);
    DO_JALR(19);
    DO_JALR(20);
    DO_JALR(21);
    DO_JALR(22);
    DO_JALR(23);
    DO_JALR(24);
    DO_JALR(25);
    DO_JALR(26);
    DO_JALR(27);
    DO_JALR(28);
    DO_JALR(29);
    DO_JALR(30);
    DO_JALR(31);


    /*
     * ========================================================
     * Keep compiler from removing memory references
     * ========================================================
     */

    result = test_mem[0];


    /*
     * ========================================================
     * PASS
     * ========================================================
     */

    test_pass();

    return 0;
}