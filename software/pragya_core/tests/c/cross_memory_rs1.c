#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * cross_memory_rs1_001
 *
 * Goal:
 *
 *     cross_memory_rs1
 *
 * Legal memory rs1 coverage:
 *
 *     LB  x1-x31
 *     LH  x1-x31
 *     LW  x1-x31
 *     LBU x1-x31
 *     LHU x1-x31
 *
 *     SB  x1-x31
 *     SH  x1-x31
 *     SW  x1-x31
 *
 * x0-load combinations are excluded from the legal cross
 * because x0 always contains zero.
 *
 * ============================================================
 */

volatile uint32_t mem_test[64];


/*
 * ------------------------------------------------------------
 * Put test data into ordinary data memory.
 *
 * The compiler will place this away from the tohost address.
 * ------------------------------------------------------------
 */

int main(void)
{
    int i;

    /*
     * Initialize memory.
     */
    for(i = 0; i < 64; i++)
        mem_test[i] = 0x12345678 + i;


    /*
     * ========================================================
     * LB
     * ========================================================
     *
     * rd = x0
     *
     * Only rs1 matters for cross_memory_rs1.
     *
     * Each address register is loaded immediately before
     * the memory instruction.
     * ========================================================
     */

    asm volatile(
        "la x3, mem_test\n"

        "mv x1,x3\n"
        "lb x0,0(x1)\n"

        "mv x2,x3\n"
        "lb x0,0(x2)\n"

        "mv x4,x3\n"
        "lb x0,0(x4)\n"

        "mv x5,x3\n"
        "lb x0,0(x5)\n"

        "mv x6,x3\n"
        "lb x0,0(x6)\n"

        "mv x7,x3\n"
        "lb x0,0(x7)\n"

        "mv x8,x3\n"
        "lb x0,0(x8)\n"

        "mv x9,x3\n"
        "lb x0,0(x9)\n"

        "mv x10,x3\n"
        "lb x0,0(x10)\n"

        "mv x11,x3\n"
        "lb x0,0(x11)\n"

        "mv x12,x3\n"
        "lb x0,0(x12)\n"

        "mv x13,x3\n"
        "lb x0,0(x13)\n"

        "mv x14,x3\n"
        "lb x0,0(x14)\n"

        "mv x15,x3\n"
        "lb x0,0(x15)\n"

        "mv x16,x3\n"
        "lb x0,0(x16)\n"

        "mv x17,x3\n"
        "lb x0,0(x17)\n"

        "mv x18,x3\n"
        "lb x0,0(x18)\n"

        "mv x19,x3\n"
        "lb x0,0(x19)\n"

        "mv x20,x3\n"
        "lb x0,0(x20)\n"

        "mv x21,x3\n"
        "lb x0,0(x21)\n"

        "mv x22,x3\n"
        "lb x0,0(x22)\n"

        "mv x23,x3\n"
        "lb x0,0(x23)\n"

        "mv x24,x3\n"
        "lb x0,0(x24)\n"

        "mv x25,x3\n"
        "lb x0,0(x25)\n"

        "mv x26,x3\n"
        "lb x0,0(x26)\n"

        "mv x27,x3\n"
        "lb x0,0(x27)\n"

        "mv x28,x3\n"
        "lb x0,0(x28)\n"

        "mv x29,x3\n"
        "lb x0,0(x29)\n"

        "mv x30,x3\n"
        "lb x0,0(x30)\n"

        "mv x31,x3\n"
        "lb x0,0(x31)\n"

        :
        :
        : "x3", "memory"
    );


    /*
     * ========================================================
     * LH
     * ========================================================
     */

    asm volatile(
        "la x3,mem_test\n"

        "lh x0,0(x1)\n"
        "lh x0,0(x2)\n"
        "lh x0,0(x4)\n"
        "lh x0,0(x5)\n"
        "lh x0,0(x6)\n"
        "lh x0,0(x7)\n"
        "lh x0,0(x8)\n"
        "lh x0,0(x9)\n"
        "lh x0,0(x10)\n"
        "lh x0,0(x11)\n"
        "lh x0,0(x12)\n"
        "lh x0,0(x13)\n"
        "lh x0,0(x14)\n"
        "lh x0,0(x15)\n"
        "lh x0,0(x16)\n"
        "lh x0,0(x17)\n"
        "lh x0,0(x18)\n"
        "lh x0,0(x19)\n"
        "lh x0,0(x20)\n"
        "lh x0,0(x21)\n"
        "lh x0,0(x22)\n"
        "lh x0,0(x23)\n"
        "lh x0,0(x24)\n"
        "lh x0,0(x25)\n"
        "lh x0,0(x26)\n"
        "lh x0,0(x27)\n"
        "lh x0,0(x28)\n"
        "lh x0,0(x29)\n"
        "lh x0,0(x30)\n"
        "lh x0,0(x31)\n"

        :
        :
        : "x3", "memory"
    );


    /*
     * ========================================================
     * LW
     * ========================================================
     */

    asm volatile(
        "la x3,mem_test\n"

        "lw x0,0(x1)\n"
        "lw x0,0(x2)\n"
        "lw x0,0(x4)\n"
        "lw x0,0(x5)\n"
        "lw x0,0(x6)\n"
        "lw x0,0(x7)\n"
        "lw x0,0(x8)\n"
        "lw x0,0(x9)\n"
        "lw x0,0(x10)\n"
        "lw x0,0(x11)\n"
        "lw x0,0(x12)\n"
        "lw x0,0(x13)\n"
        "lw x0,0(x14)\n"
        "lw x0,0(x15)\n"
        "lw x0,0(x16)\n"
        "lw x0,0(x17)\n"
        "lw x0,0(x18)\n"
        "lw x0,0(x19)\n"
        "lw x0,0(x20)\n"
        "lw x0,0(x21)\n"
        "lw x0,0(x22)\n"
        "lw x0,0(x23)\n"
        "lw x0,0(x24)\n"
        "lw x0,0(x25)\n"
        "lw x0,0(x26)\n"
        "lw x0,0(x27)\n"
        "lw x0,0(x28)\n"
        "lw x0,0(x29)\n"
        "lw x0,0(x30)\n"
        "lw x0,0(x31)\n"

        :
        :
        : "x3", "memory"
    );


    /*
     * ========================================================
     * LBU
     * ========================================================
     */

    asm volatile(
        "la x3,mem_test\n"

        "lbu x0,0(x1)\n"
        "lbu x0,0(x2)\n"
        "lbu x0,0(x4)\n"
        "lbu x0,0(x5)\n"
        "lbu x0,0(x6)\n"
        "lbu x0,0(x7)\n"
        "lbu x0,0(x8)\n"
        "lbu x0,0(x9)\n"
        "lbu x0,0(x10)\n"
        "lbu x0,0(x11)\n"
        "lbu x0,0(x12)\n"
        "lbu x0,0(x13)\n"
        "lbu x0,0(x14)\n"
        "lbu x0,0(x15)\n"
        "lbu x0,0(x16)\n"
        "lbu x0,0(x17)\n"
        "lbu x0,0(x18)\n"
        "lbu x0,0(x19)\n"
        "lbu x0,0(x20)\n"
        "lbu x0,0(x21)\n"
        "lbu x0,0(x22)\n"
        "lbu x0,0(x23)\n"
        "lbu x0,0(x24)\n"
        "lbu x0,0(x25)\n"
        "lbu x0,0(x26)\n"
        "lbu x0,0(x27)\n"
        "lbu x0,0(x28)\n"
        "lbu x0,0(x29)\n"
        "lbu x0,0(x30)\n"
        "lbu x0,0(x31)\n"

        :
        :
        : "x3", "memory"
    );


    /*
     * ========================================================
     * LHU
     * ========================================================
     */

    asm volatile(
        "la x3,mem_test\n"

        "lhu x0,0(x1)\n"
        "lhu x0,0(x2)\n"
        "lhu x0,0(x4)\n"
        "lhu x0,0(x5)\n"
        "lhu x0,0(x6)\n"
        "lhu x0,0(x7)\n"
        "lhu x0,0(x8)\n"
        "lhu x0,0(x9)\n"
        "lhu x0,0(x10)\n"
        "lhu x0,0(x11)\n"
        "lhu x0,0(x12)\n"
        "lhu x0,0(x13)\n"
        "lhu x0,0(x14)\n"
        "lhu x0,0(x15)\n"
        "lhu x0,0(x16)\n"
        "lhu x0,0(x17)\n"
        "lhu x0,0(x18)\n"
        "lhu x0,0(x19)\n"
        "lhu x0,0(x20)\n"
        "lhu x0,0(x21)\n"
        "lhu x0,0(x22)\n"
        "lhu x0,0(x23)\n"
        "lhu x0,0(x24)\n"
        "lhu x0,0(x25)\n"
        "lhu x0,0(x26)\n"
        "lhu x0,0(x27)\n"
        "lhu x0,0(x28)\n"
        "lhu x0,0(x29)\n"
        "lhu x0,0(x30)\n"
        "lhu x0,0(x31)\n"

        :
        :
        : "x3", "memory"
    );


    /*
     * ========================================================
     * STORES
     * ========================================================
     *
     * x1-x31 are already valid memory addresses.
     *
     * rs2 = x0, therefore store data = 0.
     *
     * ========================================================
     */

    asm volatile(
        "sb x0,0(x1)\n"
        "sb x0,0(x2)\n"
        "sb x0,0(x4)\n"
        "sb x0,0(x5)\n"
        "sb x0,0(x6)\n"
        "sb x0,0(x7)\n"
        "sb x0,0(x8)\n"
        "sb x0,0(x9)\n"
        "sb x0,0(x10)\n"
        "sb x0,0(x11)\n"
        "sb x0,0(x12)\n"
        "sb x0,0(x13)\n"
        "sb x0,0(x14)\n"
        "sb x0,0(x15)\n"
        "sb x0,0(x16)\n"
        "sb x0,0(x17)\n"
        "sb x0,0(x18)\n"
        "sb x0,0(x19)\n"
        "sb x0,0(x20)\n"
        "sb x0,0(x21)\n"
        "sb x0,0(x22)\n"
        "sb x0,0(x23)\n"
        "sb x0,0(x24)\n"
        "sb x0,0(x25)\n"
        "sb x0,0(x26)\n"
        "sb x0,0(x27)\n"
        "sb x0,0(x28)\n"
        "sb x0,0(x29)\n"
        "sb x0,0(x30)\n"
        "sb x0,0(x31)\n"

        "sh x0,0(x1)\n"
        "sh x0,0(x2)\n"
        "sh x0,0(x4)\n"
        "sh x0,0(x5)\n"
        "sh x0,0(x6)\n"
        "sh x0,0(x7)\n"
        "sh x0,0(x8)\n"
        "sh x0,0(x9)\n"
        "sh x0,0(x10)\n"
        "sh x0,0(x11)\n"
        "sh x0,0(x12)\n"
        "sh x0,0(x13)\n"
        "sh x0,0(x14)\n"
        "sh x0,0(x15)\n"
        "sh x0,0(x16)\n"
        "sh x0,0(x17)\n"
        "sh x0,0(x18)\n"
        "sh x0,0(x19)\n"
        "sh x0,0(x20)\n"
        "sh x0,0(x21)\n"
        "sh x0,0(x22)\n"
        "sh x0,0(x23)\n"
        "sh x0,0(x24)\n"
        "sh x0,0(x25)\n"
        "sh x0,0(x26)\n"
        "sh x0,0(x27)\n"
        "sh x0,0(x28)\n"
        "sh x0,0(x29)\n"
        "sh x0,0(x30)\n"
        "sh x0,0(x31)\n"

        "sw x0,0(x1)\n"
        "sw x0,0(x2)\n"
        "sw x0,0(x4)\n"
        "sw x0,0(x5)\n"
        "sw x0,0(x6)\n"
        "sw x0,0(x7)\n"
        "sw x0,0(x8)\n"
        "sw x0,0(x9)\n"
        "sw x0,0(x10)\n"
        "sw x0,0(x11)\n"
        "sw x0,0(x12)\n"
        "sw x0,0(x13)\n"
        "sw x0,0(x14)\n"
        "sw x0,0(x15)\n"
        "sw x0,0(x16)\n"
        "sw x0,0(x17)\n"
        "sw x0,0(x18)\n"
        "sw x0,0(x19)\n"
        "sw x0,0(x20)\n"
        "sw x0,0(x21)\n"
        "sw x0,0(x22)\n"
        "sw x0,0(x23)\n"
        "sw x0,0(x24)\n"
        "sw x0,0(x25)\n"
        "sw x0,0(x26)\n"
        "sw x0,0(x27)\n"
        "sw x0,0(x28)\n"
        "sw x0,0(x29)\n"
        "sw x0,0(x30)\n"
        "sw x0,0(x31)\n"

        :
        :
        : "memory"
    );


    test_pass();

    return 0;
}