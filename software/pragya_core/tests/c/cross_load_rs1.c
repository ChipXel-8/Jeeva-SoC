#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 *                  CROSS LOAD RS1 TEST
 * ============================================================
 *
 * LOAD instructions:
 *
 *   LB
 *   LH
 *   LW
 *   LBU
 *   LHU
 *
 * RS1 registers:
 *
 *   x5  = t0
 *   x6  = t1
 *   x7  = t2
 *   x28 = t3
 *   x29 = t4
 *   x30 = t5
 *   x31 = t6
 *
 * Important:
 *
 *   For RS1 = x31, RD is NOT x31.
 *
 *   Example:
 *
 *       lb  t5, 0(t6)
 *
 *   NOT:
 *
 *       lb  t6, 0(t6)
 *
 * This keeps RTL and Spike architectural commit streams
 * deterministic.
 *
 * ============================================================
 */


/*
 * ============================================================
 * TEST MEMORY
 * ============================================================
 */

volatile uint8_t mem8[16] __attribute__((aligned(4)));

volatile uint16_t mem16[8] __attribute__((aligned(4)));

volatile uint32_t mem32[8] __attribute__((aligned(4)));


/*
 * ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{

    /*
     * ========================================================
     * MEMORY INITIALIZATION
     * ========================================================
     */

    mem8[0] = 0x80;
    mem8[1] = 0x7f;
    mem8[2] = 0x34;
    mem8[3] = 0x12;

    mem8[4] = 0xff;
    mem8[5] = 0x01;
    mem8[6] = 0x55;
    mem8[7] = 0xaa;


    mem16[0] = 0x1234;
    mem16[1] = 0x5678;
    mem16[2] = 0x8000;
    mem16[3] = 0xffff;


    mem32[0] = 0x12345678;
    mem32[1] = 0x89abcdef;
    mem32[2] = 0x80000000;
    mem32[3] = 0xffffffff;


    /*
     * ========================================================
     * LOAD BASE ADDRESSES
     * ========================================================
     *
     * x5  -> mem8
     * x6  -> mem16
     * x7  -> mem32
     * x28 -> mem8
     * x29 -> mem16
     * x30 -> mem32
     * x31 -> mem8
     *
     * All addresses are valid.
     * ========================================================
     */

    asm volatile (

        "la t0, mem8\n"
        "la t1, mem16\n"
        "la t2, mem32\n"

        "la t3, mem8\n"
        "la t4, mem16\n"
        "la t5, mem32\n"

        "la t6, mem8\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "t4",
          "t5",
          "t6",
          "memory"
    );


    /*
     * ========================================================
     * LB
     * ========================================================
     *
     * RS1 = x5
     *
     * mem8[0] = 0x80
     *
     * Expected:
     *
     *   0xffffff80
     * ========================================================
     */

    asm volatile (
        "lb t0, 0(t0)\n"
        :
        :
        : "t0", "memory"
    );


    /*
     * RS1 = x6
     *
     * mem16 address is also byte-addressable.
     */

    asm volatile (
        "la t1, mem8\n"
        "lb t0, 0(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem8\n"
        "lb t0, 0(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem8\n"
        "lb t0, 0(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem8\n"
        "lb t0, 0(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem8\n"
        "lb t0, 0(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     *
     * IMPORTANT:
     *
     * RS1 = t6
     * RD  = t5
     *
     * NOT t6,t6.
     */

    asm volatile (
        "la t6, mem8\n"
        "lb t5, 0(t6)\n"
        :
        :
        : "t5", "t6", "memory"
    );


    /*
     * ========================================================
     * LB WITH OFFSETS
     * ========================================================
     */

    asm volatile (
        "la t0, mem8\n"

        "lb t1, 1(t0)\n"
        "lb t2, 2(t0)\n"
        "lb t3, 3(t0)\n"
        "lb t4, 4(t0)\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "t4",
          "memory"
    );


    /*
     * ========================================================
     * LBU
     * ========================================================
     *
     * mem8[0] = 0x80
     *
     * Expected:
     *
     *   0x00000080
     * ========================================================
     */

    asm volatile (
        "la t0, mem8\n"
        "lbu t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem8\n"
        "lbu t0, 0(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem8\n"
        "lbu t0, 0(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem8\n"
        "lbu t0, 0(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem8\n"
        "lbu t0, 0(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem8\n"
        "lbu t0, 0(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     *
     * RD = x5
     */

    asm volatile (
        "la t6, mem8\n"
        "lbu t0, 0(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * LH
     * ========================================================
     *
     * Halfword accesses use naturally aligned addresses.
     *
     * mem16[0] = 0x1234
     * ========================================================
     */

    asm volatile (
        "la t0, mem16\n"
        "lh t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem16\n"
        "lh t0, 0(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem16\n"
        "lh t0, 0(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem16\n"
        "lh t0, 0(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem16\n"
        "lh t0, 0(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem16\n"
        "lh t0, 0(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     */

    asm volatile (
        "la t6, mem16\n"
        "lh t0, 0(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * LH WITH ALIGNED OFFSET
     * ========================================================
     */

    asm volatile (
        "la t0, mem16\n"

        "lh t1, 2(t0)\n"
        "lh t2, 4(t0)\n"
        "lh t3, 6(t0)\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "memory"
    );


    /*
     * ========================================================
     * LHU
     * ========================================================
     */

    asm volatile (
        "la t0, mem16\n"
        "lhu t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem16\n"
        "lhu t0, 0(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem16\n"
        "lhu t0, 0(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem16\n"
        "lhu t0, 0(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem16\n"
        "lhu t0, 0(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem16\n"
        "lhu t0, 0(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     */

    asm volatile (
        "la t6, mem16\n"
        "lhu t0, 0(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * LHU WITH ALIGNED OFFSETS
     * ========================================================
     */

    asm volatile (
        "la t0, mem16\n"

        "lhu t1, 2(t0)\n"
        "lhu t2, 4(t0)\n"
        "lhu t3, 6(t0)\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "memory"
    );


    /*
     * ========================================================
     * LW
     * ========================================================
     *
     * Naturally aligned 32-bit accesses.
     *
     * mem32[0] = 0x12345678
     * ========================================================
     */

    asm volatile (
        "la t0, mem32\n"
        "lw t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem32\n"
        "lw t0, 0(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem32\n"
        "lw t0, 0(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem32\n"
        "lw t0, 0(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem32\n"
        "lw t0, 0(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem32\n"
        "lw t0, 0(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     */

    asm volatile (
        "la t6, mem32\n"
        "lw t0, 0(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * LW WITH ALIGNED OFFSETS
     * ========================================================
     */

    asm volatile (
        "la t0, mem32\n"

        "lw t1, 4(t0)\n"
        "lw t2, 8(t0)\n"
        "lw t3, 12(t0)\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "memory"
    );


    /*
     * ========================================================
     * SIGN EXTENSION CASES
     * ========================================================
     */

    asm volatile (
        "la t0, mem8\n"

        "lb  t1, 0(t0)\n"
        "lbu t2, 0(t0)\n"

        "la t3, mem16\n"

        "lh  t4, 4(t3)\n"
        "lhu t5, 4(t3)\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "t4",
          "t5",
          "memory"
    );


    /*
     * ========================================================
     * LOAD-USE HAZARD CASES
     * ========================================================
     */

    asm volatile (
        "la t0, mem8\n"
        "lb t1, 0(t0)\n"
        "addi t2, t1, 1\n"

        "la t3, mem16\n"
        "lh t4, 0(t3)\n"
        "addi t5, t4, 1\n"

        "la t6, mem32\n"
        "lw t0, 0(t6)\n"
        "addi t1, t0, 1\n"

        :
        :
        : "t0",
          "t1",
          "t2",
          "t3",
          "t4",
          "t5",
          "t6",
          "memory"
    );


    /*
     * ========================================================
     * FINAL
     * ========================================================
     */

    test_pass();

    return 0;
}