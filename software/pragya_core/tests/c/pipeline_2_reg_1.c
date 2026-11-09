#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * PIPELINE-2 REGISTER TRANSITION / TOGGLE COVERAGE TEST
     *
     * Targets:
     *
     *   PC
     *   PC+4
     *   INSTRUCTION
     *   RD
     *   FUNCT3
     *   WB MUX SELECT
     *   REG WRITE
     *   MEMORY REQUEST
     *   MEMORY WRITE
     *   ALU RESULT
     *   IMMEDIATE
     *   STORE DATA
     *   CSR CONTROL/DATA
     *   MDU RESULT
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * RESET -> NORMAL
     * ------------------------------------------------------------
     */

    asm volatile(
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * ALU RESULT TRANSITIONS
     *
     * Generate many different result bit patterns.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0x00000000\n"
        "li x6,  0xffffffff\n"

        "add x7,  x5, x6\n"
        "sub x8,  x5, x6\n"
        "and x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        "li x12, 0xaaaaaaaa\n"
        "li x13, 0x55555555\n"

        "and x14, x12, x13\n"
        "or  x15, x12, x13\n"
        "xor x16, x12, x13\n"
        "add x17, x12, x13\n"
        "sub x18, x12, x13\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * SHIFT OPERATIONS
     *
     * Exercise result bits across the complete 32-bit datapath.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0x80000001\n"

        "slli x6,  x5, 1\n"
        "slli x7,  x5, 7\n"
        "slli x8,  x5, 15\n"
        "slli x9,  x5, 31\n"

        "srli x10, x5, 1\n"
        "srli x11, x5, 7\n"
        "srli x12, x5, 15\n"
        "srli x13, x5, 31\n"

        "srai x14, x5, 1\n"
        "srai x15, x5, 7\n"
        "srai x16, x5, 15\n"
        "srai x17, x5, 31\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * SIGNED / UNSIGNED COMPARISON
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0x80000000\n"
        "li x6,  0x00000001\n"

        "slt  x7, x5, x6\n"
        "slt  x8, x6, x5\n"

        "sltu x9,  x5, x6\n"
        "sltu x10, x6, x5\n"

        "li x11, 0x7fffffff\n"
        "li x12, 0xffffffff\n"

        "slt  x13, x11, x12\n"
        "sltu x14, x11, x12\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * STORE PIPELINE
     *
     * Different store sizes / funct3 values.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x20, 0x80008000\n"

        "li x21, 0x11223344\n"
        "sw  x21, 0(x20)\n"

        "li x21, 0x000055aa\n"
        "sh  x21, 4(x20)\n"

        "li x21, 0x000000ff\n"
        "sb  x21, 6(x20)\n"

        "li x21, 0xa5a5a5a5\n"
        "sw  x21, 8(x20)\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * LOAD PIPELINE
     *
     * Different funct3 values.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x20, 0x80008000\n"

        "lw  x5,  0(x20)\n"
        "lh  x6,  0(x20)\n"
        "lhu x7,  0(x20)\n"
        "lb  x8,  0(x20)\n"
        "lbu x9,  0(x20)\n"

        "lw  x10, 8(x20)\n"
        "lh  x11, 8(x20)\n        "
        "lhu x12, 8(x20)\n"
        "lb  x13, 8(x20)\n"
        "lbu x14, 8(x20)\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * IMMEDIATE VALUES
     *
     * Positive / negative / alternating bit patterns.
     * ------------------------------------------------------------
     */

    asm volatile(
        "addi x5, x0,  1\n"
        "addi x6, x0, -1\n"
        "addi x7, x5, 127\n"
        "addi x8, x6, -128\n"

        "xori x9,  x5,  0x55\n"
        "ori  x10, x5, 0x155\n"
        "andi x11, x6, 0x155\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * U-TYPE
     *
     * Make upper instruction/immediate bits toggle.
     * ------------------------------------------------------------
     */

    asm volatile(
        "lui   x5,  0x00000\n"
        "lui   x6,  0x12345\n"
        "lui   x7,  0x7ffff\n"
        "lui   x8,  0x80000\n"
        "lui   x9,  0xfffff\n"

        "auipc x10, 0x00001\n"
        "auipc x11, 0x12345\n"
        "auipc x12, 0x7ffff\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * BRANCHES
     *
     * Exercise B-type instructions and PC transitions.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 1\n"
        "li x6, 1\n"

        "beq x5, x6, 1f\n"
        "addi x7, x0, 0x11\n"
        "addi x7, x0, 0x22\n"

        "1:\n"
        "bne x5, x0, 2f\n"
        "addi x7, x0, 0x33\n"

        "2:\n"
        "blt x5, x6, 3f\n"
        "addi x7, x0, 0x44\n"

        "3:\n"
        "bge x5, x6, 4f\n"
        "addi x7, x0, 0x55\n"

        "4:\n"
        "bltu x5, x6, 5f\n"
        "addi x7, x0, 0x66\n"

        "5:\n"
        "bgeu x5, x6, 6f\n"
        "addi x7, x0, 0x77\n"

        "6:\n"
        "nop\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * JAL
     *
     * Change PC and PC+4.
     * ------------------------------------------------------------
     */

    asm volatile(
        "jal x1, 1f\n"

        "li x20, 0x11111111\n"
        "li x21, 0x22222222\n"
        "li x22, 0x33333333\n"

        "1:\n"
        "addi x23, x0, 0x55\n"
        "addi x24, x23, 1\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * JALR
     *
     * Another PC transition and rd transition.
     * ------------------------------------------------------------
     */

    asm volatile(
        "auipc x5, 0\n"
        "addi  x5, x5, 12\n"
        "jalr  x2, 0(x5)\n"

        "addi x25, x0, 0x11\n"
        "addi x26, x0, 0x22\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * CSR PIPELINE
     *
     * Change CSR control signals and CSR data.
     * ------------------------------------------------------------
     */

    asm volatile(
        "csrr x5,  mstatus\n"
        "csrr x6,  mie\n"
        "csrr x7,  mtvec\n"
        "csrr x8,  mepc\n"
        "csrr x9,  mcause\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * CSR WRITE / SET / CLEAR
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x00000008\n"
        "csrs mstatus, x5\n"
        "csrc mstatus, x5\n"

        "li x6, 0x00000001\n"
        "csrs mie, x6\n"
        "csrc mie, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * M EXTENSION
     *
     * Exercise mdu_result pipeline register.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0x12345678\n"
        "li x6,  0x00001234\n"

        "mul    x7,  x5, x6\n"
        "mulh   x8,  x5, x6\n"
        "mulhu  x9,  x5, x6\n"
        "mulhsu x10, x5, x6\n"

        "div    x11, x5, x6\n"
        "divu   x12, x5, x6\n"
        "rem    x13, x5, x6\n"
        "remu   x14, x5, x6\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * DEPENDENCY CHAIN
     *
     * Keeps pipeline2 active continuously.
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0x11111111\n"
        "add x6, x5, x5\n"
        "add x7, x6, x5\n"
        "xor x8, x7, x6\n"
        "or  x9, x8, x7\n"
        "and x10, x9, x8\n"
        "add x11, x10, x9\n"
        "sub x12, x11, x10\n"
        "xor x13, x12, x11\n"
        "or  x14, x13, x12\n"

        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * FINAL SIGNATURE
     * ------------------------------------------------------------
     */

    asm volatile(
        "mv %0, x14"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}