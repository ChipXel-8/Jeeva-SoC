#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 *                 CROSS STORE RS1 TEST
 * ============================================================
 *
 * STORE instructions:
 *
 *   SB
 *   SH
 *   SW
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
 * Each store uses a different RS1 register.
 *
 * IMPORTANT:
 *
 * For stores there is no RD register.
 *
 * Therefore the important coverage condition is:
 *
 *        STORE TYPE + RS1
 *
 * All addresses are valid and naturally aligned for SH/SW.
 *
 * ============================================================
 */


/*
 * ============================================================
 * TEST MEMORY
 * ============================================================
 */

volatile uint8_t mem8[32] __attribute__((aligned(4)));

volatile uint16_t mem16[16] __attribute__((aligned(4)));

volatile uint32_t mem32[16] __attribute__((aligned(4)));


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

    mem8[0]  = 0x00;
    mem8[1]  = 0x00;
    mem8[2]  = 0x00;
    mem8[3]  = 0x00;
    mem8[4]  = 0x00;
    mem8[5]  = 0x00;
    mem8[6]  = 0x00;
    mem8[7]  = 0x00;

    mem16[0] = 0x0000;
    mem16[1] = 0x0000;
    mem16[2] = 0x0000;
    mem16[3] = 0x0000;
    mem16[4] = 0x0000;
    mem16[5] = 0x0000;
    mem16[6] = 0x0000;
    mem16[7] = 0x0000;

    mem32[0] = 0x00000000;
    mem32[1] = 0x00000000;
    mem32[2] = 0x00000000;
    mem32[3] = 0x00000000;
    mem32[4] = 0x00000000;
    mem32[5] = 0x00000000;
    mem32[6] = 0x00000000;
    mem32[7] = 0x00000000;


    /*
     * ========================================================
     * LOAD BASE ADDRESSES
     * ========================================================
     *
     * x5  -> mem8
     * x6  -> mem8
     * x7  -> mem8
     * x28 -> mem8
     * x29 -> mem8
     * x30 -> mem8
     * x31 -> mem8
     *
     * ========================================================
     */

    asm volatile (

        "la t0, mem8\n"
        "la t1, mem8\n"
        "la t2, mem8\n"

        "la t3, mem8\n"
        "la t4, mem8\n"
        "la t5, mem8\n"

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
     * SB
     * ========================================================
     *
     * RS1 = x5
     *
     * Instruction:
     *
     *     sb t1, 0(t0)
     *
     * RS1 = x5
     *
     * ========================================================
     */

    asm volatile (
        "la t0, mem8\n"
        "li t1, 0x11\n"
        "sb t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem8\n"
        "li t0, 0x22\n"
        "sb t0, 1(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem8\n"
        "li t0, 0x33\n"
        "sb t0, 2(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem8\n"
        "li t0, 0x44\n"
        "sb t0, 3(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem8\n"
        "li t0, 0x55\n"
        "sb t0, 4(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem8\n"
        "li t0, 0x66\n"
        "sb t0, 5(t5)\n"
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
     * Data  = t0
     *
     * ========================================================
     */

    asm volatile (
        "la t6, mem8\n"
        "li t0, 0x77\n"
        "sb t0, 6(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * SH
     * ========================================================
     *
     * Halfword stores use naturally aligned addresses.
     *
     * ========================================================
     */


    /*
     * RS1 = x5
     */

    asm volatile (
        "la t0, mem16\n"
        "li t1, 0x1111\n"
        "sh t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem16\n"
        "li t0, 0x2222\n"
        "sh t0, 2(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem16\n"
        "li t0, 0x3333\n"
        "sh t0, 4(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem16\n"
        "li t0, 0x4444\n"
        "sh t0, 6(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem16\n"
        "li t0, 0x5555\n"
        "sh t0, 8(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem16\n"
        "li t0, 0x6666\n"
        "sh t0, 10(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     */

    asm volatile (
        "la t6, mem16\n"
        "li t0, 0x7777\n"
        "sh t0, 12(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * SW
     * ========================================================
     *
     * Word stores use naturally aligned addresses.
     *
     * ========================================================
     */


    /*
     * RS1 = x5
     */

    asm volatile (
        "la t0, mem32\n"
        "li t1, 0x11111111\n"
        "sw t1, 0(t0)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x6
     */

    asm volatile (
        "la t1, mem32\n"
        "li t0, 0x22222222\n"
        "sw t0, 4(t1)\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * RS1 = x7
     */

    asm volatile (
        "la t2, mem32\n"
        "li t0, 0x33333333\n"
        "sw t0, 8(t2)\n"
        :
        :
        : "t0", "t2", "memory"
    );


    /*
     * RS1 = x28
     */

    asm volatile (
        "la t3, mem32\n"
        "li t0, 0x44444444\n"
        "sw t0, 12(t3)\n"
        :
        :
        : "t0", "t3", "memory"
    );


    /*
     * RS1 = x29
     */

    asm volatile (
        "la t4, mem32\n"
        "li t0, 0x55555555\n"
        "sw t0, 16(t4)\n"
        :
        :
        : "t0", "t4", "memory"
    );


    /*
     * RS1 = x30
     */

    asm volatile (
        "la t5, mem32\n"
        "li t0, 0x66666666\n"
        "sw t0, 20(t5)\n"
        :
        :
        : "t0", "t5", "memory"
    );


    /*
     * RS1 = x31
     */

    asm volatile (
        "la t6, mem32\n"
        "li t0, 0x77777777\n"
        "sw t0, 24(t6)\n"
        :
        :
        : "t0", "t6", "memory"
    );


    /*
     * ========================================================
     * CROSS STORE HAZARD CASES
     * ========================================================
     *
     * Store immediately after producing the store data.
     *
     * ========================================================
     */

    asm volatile (
        "la t0, mem32\n"
        "li t1, 0xaaaaaaaa\n"
        "sw t1, 0(t0)\n"

        "la t2, mem32\n"
        "li t3, 0xbbbbbbbb\n"
        "sw t3, 4(t2)\n"

        "la t4, mem32\n"
        "li t5, 0xcccccccc\n"
        "sw t5, 8(t4)\n"

        "la t6, mem32\n"
        "li t0, 0xdddddddd\n"
        "sw t0, 12(t6)\n"

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
     * STORE OFFSETS
     * ========================================================
     *
     * Additional offsets to exercise immediate generation.
     *
     * ========================================================
     */

    asm volatile (
        "la t0, mem8\n"
        "li t1, 0x81\n"
        "sb t1, 7(t0)\n"

        "la t2, mem16\n"
        "li t3, 0x8282\n"
        "sh t3, 14(t2)\n"

        "la t4, mem32\n"
        "li t5, 0x83838383\n"
        "sw t5, 28(t4)\n"

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
     * FINAL
     * ========================================================
     *
     * IMPORTANT:
     *
     * Do not replace this with a store to another address.
     *
     * test_pass() generates the expected:
     *
     *     mem 0x80008000 0x00000001
     *
     * which your Makefile uses to terminate Spike.
     *
     * ========================================================
     */

    test_pass();

    return 0;
}
