#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 *                  CROSS STORE RS1 TEST
 * ============================================================
 *
 * Coverage:
 *
 *   cp_store_type : SB / SH / SW
 *   cp_rs1        : x0 ... x31
 *
 * Required:
 *
 *       3 store types x 32 RS1 registers = 96 bins
 *
 * Every combination is explicitly generated.
 *
 * ============================================================
 */


/*
 * ------------------------------------------------------------
 * Test memory
 * ------------------------------------------------------------
 */

volatile uint8_t  store_mem8[64]  __attribute__((aligned(4)));
volatile uint16_t store_mem16[32] __attribute__((aligned(4)));
volatile uint32_t store_mem32[32] __attribute__((aligned(4)));


/*
 * ------------------------------------------------------------
 * Main
 * ------------------------------------------------------------
 */

int main(void)
{
    /*
     * Initialize memory so that the store operations have
     * valid destinations.
     */
    store_mem8[0] = 0;
    store_mem16[0] = 0;
    store_mem32[0] = 0;


    /*
     * ========================================================
     * SB : RS1 = x0 ... x31
     * ========================================================
     *
     * Each instruction below has a different RS1.
     *
     * SB rd/value register = x31
     *
     * RS1 is what is being crossed.
     *
     * --------------------------------------------------------
     */

    asm volatile (

        /*
         * x0
         */
        "la  x31, store_mem8\n"
        "sb  x31, 0(x0)\n"

        /*
         * x1
         */
        "la  x1, store_mem8\n"
        "sb  x31, 1(x1)\n"

        /*
         * x2
         */
        "la  x2, store_mem8\n"
        "sb  x31, 2(x2)\n"

        /*
         * x3
         */
        "la  x3, store_mem8\n"
        "sb  x31, 3(x3)\n"

        /*
         * x4
         */
        "la  x4, store_mem8\n"
        "sb  x31, 4(x4)\n"

        /*
         * x5
         */
        "la  x5, store_mem8\n"
        "sb  x31, 5(x5)\n"

        /*
         * x6
         */
        "la  x6, store_mem8\n"
        "sb  x31, 6(x6)\n"

        /*
         * x7
         */
        "la  x7, store_mem8\n"
        "sb  x31, 7(x7)\n"

        /*
         * x8
         */
        "la  x8, store_mem8\n"
        "sb  x31, 8(x8)\n"

        /*
         * x9
         */
        "la  x9, store_mem8\n"
        "sb  x31, 9(x9)\n"

        /*
         * x10
         */
        "la  x10, store_mem8\n"
        "sb  x31, 10(x10)\n"

        /*
         * x11
         */
        "la  x11, store_mem8\n"
        "sb  x31, 11(x11)\n"

        /*
         * x12
         */
        "la  x12, store_mem8\n"
        "sb  x31, 12(x12)\n"

        /*
         * x13
         */
        "la  x13, store_mem8\n"
        "sb  x31, 13(x13)\n"

        /*
         * x14
         */
        "la  x14, store_mem8\n"
        "sb  x31, 14(x14)\n"

        /*
         * x15
         */
        "la  x15, store_mem8\n"
        "sb  x31, 15(x15)\n"

        /*
         * x16
         */
        "la  x16, store_mem8\n"
        "sb  x31, 16(x16)\n"

        /*
         * x17
         */
        "la  x17, store_mem8\n"
        "sb  x31, 17(x17)\n"

        /*
         * x18
         */
        "la  x18, store_mem8\n"
        "sb  x31, 18(x18)\n"

        /*
         * x19
         */
        "la  x19, store_mem8\n"
        "sb  x31, 19(x19)\n"

        /*
         * x20
         */
        "la  x20, store_mem8\n"
        "sb  x31, 20(x20)\n"

        /*
         * x21
         */
        "la  x21, store_mem8\n"
        "sb  x31, 21(x21)\n"

        /*
         * x22
         */
        "la  x22, store_mem8\n"
        "sb  x31, 22(x22)\n"

        /*
         * x23
         */
        "la  x23, store_mem8\n"
        "sb  x31, 23(x23)\n"

        /*
         * x24
         */
        "la  x24, store_mem8\n"
        "sb  x31, 24(x24)\n"

        /*
         * x25
         */
        "la  x25, store_mem8\n"
        "sb  x31, 25(x25)\n"

        /*
         * x26
         */
        "la  x26, store_mem8\n"
        "sb  x31, 26(x26)\n"

        /*
         * x27
         */
        "la  x27, store_mem8\n"
        "sb  x31, 27(x27)\n"

        /*
         * x28
         */
        "la  x28, store_mem8\n"
        "sb  x31, 28(x28)\n"

        /*
         * x29
         */
        "la  x29, store_mem8\n"
        "sb  x31, 29(x29)\n"

        /*
         * x30
         */
        "la  x30, store_mem8\n"
        "sb  x31, 30(x30)\n"

        /*
         * x31
         *
         * IMPORTANT:
         * x31 is RS1 here.
         * x30 is store data.
         */
        "la  x31, store_mem8\n"
        "la  x30, store_mem8\n"
        "sb  x30, 31(x31)\n"

        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * SH : RS1 = x0 ... x31
     * ========================================================
     */

    asm volatile (

        /*
         * x0
         */
        "la  x31, store_mem16\n"
        "sh  x31, 0(x0)\n"

        /*
         * x1
         */
        "la  x1, store_mem16\n"
        "sh  x31, 2(x1)\n"

        /*
         * x2
         */
        "la  x2, store_mem16\n"
        "sh  x31, 4(x2)\n"

        /*
         * x3
         */
        "la  x3, store_mem16\n"
        "sh  x31, 6(x3)\n"

        /*
         * x4
         */
        "la  x4, store_mem16\n"
        "sh  x31, 8(x4)\n"

        /*
         * x5
         */
        "la  x5, store_mem16\n"
        "sh  x31, 10(x5)\n"

        /*
         * x6
         */
        "la  x6, store_mem16\n"
        "sh  x31, 12(x6)\n"

        /*
         * x7
         */
        "la  x7, store_mem16\n"
        "sh  x31, 14(x7)\n"

        /*
         * x8
         */
        "la  x8, store_mem16\n"
        "sh  x31, 16(x8)\n"

        /*
         * x9
         */
        "la  x9, store_mem16\n"
        "sh  x31, 18(x9)\n"

        /*
         * x10
         */
        "la  x10, store_mem16\n"
        "sh  x31, 20(x10)\n"

        /*
         * x11
         */
        "la  x11, store_mem16\n"
        "sh  x31, 22(x11)\n"

        /*
         * x12
         */
        "la  x12, store_mem16\n"
        "sh  x31, 24(x12)\n"

        /*
         * x13
         */
        "la  x13, store_mem16\n"
        "sh  x31, 26(x13)\n"

        /*
         * x14
         */
        "la  x14, store_mem16\n"
        "sh  x31, 28(x14)\n"

        /*
         * x15
         */
        "la  x15, store_mem16\n"
        "sh  x31, 30(x15)\n"

        /*
         * x16
         */
        "la  x16, store_mem16\n"
        "sh  x31, 32(x16)\n"

        /*
         * x17
         */
        "la  x17, store_mem16\n"
        "sh  x31, 34(x17)\n"

        /*
         * x18
         */
        "la  x18, store_mem16\n"
        "sh  x31, 36(x18)\n"

        /*
         * x19
         */
        "la  x19, store_mem16\n"
        "sh  x31, 38(x19)\n"

        /*
         * x20
         */
        "la  x20, store_mem16\n"
        "sh  x31, 40(x20)\n"

        /*
         * x21
         */
        "la  x21, store_mem16\n"
        "sh  x31, 42(x21)\n"

        /*
         * x22
         */
        "la  x22, store_mem16\n"
        "sh  x31, 44(x22)\n"

        /*
         * x23
         */
        "la  x23, store_mem16\n"
        "sh  x31, 46(x23)\n"

        /*
         * x24
         */
        "la  x24, store_mem16\n"
        "sh  x31, 48(x24)\n"

        /*
         * x25
         */
        "la  x25, store_mem16\n"
        "sh  x31, 50(x25)\n"

        /*
         * x26
         */
        "la  x26, store_mem16\n"
        "sh  x31, 52(x26)\n"

        /*
         * x27
         */
        "la  x27, store_mem16\n"
        "sh  x31, 54(x27)\n"

        /*
         * x28
         */
        "la  x28, store_mem16\n"
        "sh  x31, 56(x28)\n"

        /*
         * x29
         */
        "la  x29, store_mem16\n"
        "sh  x31, 58(x29)\n"

        /*
         * x30
         */
        "la  x30, store_mem16\n"
        "sh  x31, 60(x30)\n"

        /*
         * x31
         */
        "la  x31, store_mem16\n"
        "la  x30, store_mem16\n"
        "sh  x30, 62(x31)\n"

        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * SW : RS1 = x0 ... x31
     * ========================================================
     *
     * Word accesses are kept 4-byte aligned.
     *
     * ========================================================
     */

    asm volatile (

        /*
         * x0
         */
        "la  x31, store_mem32\n"
        "sw  x31, 0(x0)\n"

        /*
         * x1
         */
        "la  x1, store_mem32\n"
        "sw  x31, 4(x1)\n"

        /*
         * x2
         */
        "la  x2, store_mem32\n"
        "sw  x31, 8(x2)\n"

        /*
         * x3
         */
        "la  x3, store_mem32\n"
        "sw  x31, 12(x3)\n"

        /*
         * x4
         */
        "la  x4, store_mem32\n"
        "sw  x31, 16(x4)\n"

        /*
         * x5
         */
        "la  x5, store_mem32\n"
        "sw  x31, 20(x5)\n"

        /*
         * x6
         */
        "la  x6, store_mem32\n"
        "sw  x31, 24(x6)\n"

        /*
         * x7
         */
        "la  x7, store_mem32\n"
        "sw  x31, 28(x7)\n"

        /*
         * x8
         */
        "la  x8, store_mem32\n"
        "sw  x31, 32(x8)\n"

        /*
         * x9
         */
        "la  x9, store_mem32\n"
        "sw  x31, 36(x9)\n"

        /*
         * x10
         */
        "la  x10, store_mem32\n"
        "sw  x31, 40(x10)\n"

        /*
         * x11
         */
        "la  x11, store_mem32\n"
        "sw  x31, 44(x11)\n"

        /*
         * x12
         */
        "la  x12, store_mem32\n"
        "sw  x31, 48(x12)\n"

        /*
         * x13
         */
        "la  x13, store_mem32\n"
        "sw  x31, 52(x13)\n"

        /*
         * x14
         */
        "la  x14, store_mem32\n"
        "sw  x31, 56(x14)\n"

        /*
         * x15
         */
        "la  x15, store_mem32\n"
        "sw  x31, 60(x15)\n"

        /*
         * x16
         */
        "la  x16, store_mem32\n"
        "sw  x31, 64(x16)\n"

        /*
         * x17
         */
        "la  x17, store_mem32\n"
        "sw  x31, 68(x17)\n"

        /*
         * x18
         */
        "la  x18, store_mem32\n"
        "sw  x31, 72(x18)\n"

        /*
         * x19
         */
        "la  x19, store_mem32\n"
        "sw  x31, 76(x19)\n"

        /*
         * x20
         */
        "la  x20, store_mem32\n"
        "sw  x31, 80(x20)\n"

        /*
         * x21
         */
        "la  x21, store_mem32\n"
        "sw  x31, 84(x21)\n"

        /*
         * x22
         */
        "la  x22, store_mem32\n"
        "sw  x31, 88(x22)\n"

        /*
         * x23
         */
        "la  x23, store_mem32\n"
        "sw  x31, 92(x23)\n"

        /*
         * x24
         */
        "la  x24, store_mem32\n"
        "sw  x31, 96(x24)\n"

        /*
         * x25
         */
        "la  x25, store_mem32\n"
        "sw  x31, 100(x25)\n"

        /*
         * x26
         */
        "la  x26, store_mem32\n"
        "sw  x31, 104(x26)\n"

        /*
         * x27
         */
        "la  x27, store_mem32\n"
        "sw  x31, 108(x27)\n"

        /*
         * x28
         */
        "la  x28, store_mem32\n"
        "sw  x31, 112(x28)\n"

        /*
         * x29
         */
        "la  x29, store_mem32\n"
        "sw  x31, 116(x29)\n"

        /*
         * x30
         */
        "la  x30, store_mem32\n"
        "sw  x31, 120(x30)\n"

        /*
         * x31
         */
        "la  x31, store_mem32\n"
        "la  x30, store_mem32\n"
        "sw  x30, 124(x31)\n"

        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * FINISH
     * ========================================================
     */

    test_pass();

    return 0;
}