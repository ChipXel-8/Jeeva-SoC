#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * RV32I cross_instr_rd TEST
 *
 * Goal:
 *
 *     cross_instr_rd = cp_instruction x cp_rd
 *
 * 28 rd-writing RV32I instructions
 * x 32 rd values
 *
 * = 896 legal bins
 *
 * No:
 *     RV32M
 *     SYSTEM
 *     FENCE
 *     branches
 *     stores
 *
 * IMPORTANT:
 * x1/x2/x8/etc. are restored after each test so that
 * Spike/C runtime does not get corrupted.
 * ============================================================
 */


/*
 * ------------------------------------------------------------
 * Scratch memory
 * ------------------------------------------------------------
 */

volatile uint32_t scratch = 0x12345678;


/*
 * ------------------------------------------------------------
 * Helper
 *
 * x18 is used as a temporary register, but we restore it too.
 * x2 (sp) is explicitly restored after every operation.
 *
 * The actual instruction under coverage is BEFORE the restore.
 * ------------------------------------------------------------
 */

#define RESTORE_SP() \
    asm volatile ( \
        "mv x2, x9\n" \
        ::: "x2", "memory" \
    )


int main(void)
{
    /*
     * ========================================================
     * Establish safe registers
     * ========================================================
     *
     * x9 = known stack pointer backup
     * x10/x11 = source operands
     * x12 = address
     *
     * Do NOT use x2 as a source for the coverage instruction.
     */

    asm volatile (
        "mv x9, x2\n"
        "li x10, 0x55\n"
        "li x11, 0x0f\n"
        :
        :
        : "x9", "x10", "x11", "memory"
    );


    /*
     * ========================================================
     * R-TYPE
     * ========================================================
     */

    /* ADD */
    asm volatile (
        "add x0,x10,x11\n"
        "add x1,x10,x11\n"
        "add x2,x10,x11\n"
        "add x3,x10,x11\n"
        "add x4,x10,x11\n"
        "add x5,x10,x11\n"
        "add x6,x10,x11\n"
        "add x7,x10,x11\n"
        "add x8,x10,x11\n"
        "add x9,x10,x11\n"
        "add x10,x10,x11\n"
        "add x11,x10,x11\n"
        "add x12,x10,x11\n"
        "add x13,x10,x11\n"
        "add x14,x10,x11\n"
        "add x15,x10,x11\n"
        "add x16,x10,x11\n"
        "add x17,x10,x11\n"
        "add x18,x10,x11\n"
        "add x19,x10,x11\n"
        "add x20,x10,x11\n"
        "add x21,x10,x11\n"
        "add x22,x10,x11\n"
        "add x23,x10,x11\n"
        "add x24,x10,x11\n"
        "add x25,x10,x11\n"
        "add x26,x10,x11\n"
        "add x27,x10,x11\n"
        "add x28,x10,x11\n"
        "add x29,x10,x11\n"
        "add x30,x10,x11\n"
        "add x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* SUB */
    asm volatile (
        "sub x0,x10,x11\n"
        "sub x1,x10,x11\n"
        "sub x2,x10,x11\n"
        "sub x3,x10,x11\n"
        "sub x4,x10,x11\n"
        "sub x5,x10,x11\n"
        "sub x6,x10,x11\n"
        "sub x7,x10,x11\n"
        "sub x8,x10,x11\n"
        "sub x9,x10,x11\n"
        "sub x10,x10,x11\n"
        "sub x11,x10,x11\n"
        "sub x12,x10,x11\n"
        "sub x13,x10,x11\n"
        "sub x14,x10,x11\n"
        "sub x15,x10,x11\n"
        "sub x16,x10,x11\n"
        "sub x17,x10,x11\n"
        "sub x18,x10,x11\n"
        "sub x19,x10,x11\n"
        "sub x20,x10,x11\n"
        "sub x21,x10,x11\n"
        "sub x22,x10,x11\n"
        "sub x23,x10,x11\n"
        "sub x24,x10,x11\n"
        "sub x25,x10,x11\n"
        "sub x26,x10,x11\n"
        "sub x27,x10,x11\n"
        "sub x28,x10,x11\n"
        "sub x29,x10,x11\n"
        "sub x30,x10,x11\n"
        "sub x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* SLL */
    asm volatile (
        "sll x0,x10,x11\n"
        "sll x1,x10,x11\n"
        "sll x2,x10,x11\n"
        "sll x3,x10,x11\n"
        "sll x4,x10,x11\n"
        "sll x5,x10,x11\n"
        "sll x6,x10,x11\n"
        "sll x7,x10,x11\n"
        "sll x8,x10,x11\n"
        "sll x9,x10,x11\n"
        "sll x10,x10,x11\n"
        "sll x11,x10,x11\n"
        "sll x12,x10,x11\n"
        "sll x13,x10,x11\n"
        "sll x14,x10,x11\n"
        "sll x15,x10,x11\n"
        "sll x16,x10,x11\n"
        "sll x17,x10,x11\n"
        "sll x18,x10,x11\n"
        "sll x19,x10,x11\n"
        "sll x20,x10,x11\n"
        "sll x21,x10,x11\n"
        "sll x22,x10,x11\n"
        "sll x23,x10,x11\n"
        "sll x24,x10,x11\n"
        "sll x25,x10,x11\n"
        "sll x26,x10,x11\n"
        "sll x27,x10,x11\n"
        "sll x28,x10,x11\n"
        "sll x29,x10,x11\n"
        "sll x30,x10,x11\n"
        "sll x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* SLT */
    asm volatile (
        "slt x0,x10,x11\n"
        "slt x1,x10,x11\n"
        "slt x2,x10,x11\n"
        "slt x3,x10,x11\n"
        "slt x4,x10,x11\n"
        "slt x5,x10,x11\n"
        "slt x6,x10,x11\n"
        "slt x7,x10,x11\n"
        "slt x8,x10,x11\n"
        "slt x9,x10,x11\n"
        "slt x10,x10,x11\n"
        "slt x11,x10,x11\n"
        "slt x12,x10,x11\n"
        "slt x13,x10,x11\n"
        "slt x14,x10,x11\n"
        "slt x15,x10,x11\n"
        "slt x16,x10,x11\n"
        "slt x17,x10,x11\n"
        "slt x18,x10,x11\n"
        "slt x19,x10,x11\n"
        "slt x20,x10,x11\n"
        "slt x21,x10,x11\n"
        "slt x22,x10,x11\n"
        "slt x23,x10,x11\n"
        "slt x24,x10,x11\n"
        "slt x25,x10,x11\n"
        "slt x26,x10,x11\n"
        "slt x27,x10,x11\n"
        "slt x28,x10,x11\n"
        "slt x29,x10,x11\n"
        "slt x30,x10,x11\n"
        "slt x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* SLTU */
    asm volatile (
        "sltu x0,x10,x11\n"
        "sltu x1,x10,x11\n"
        "sltu x2,x10,x11\n"
        "sltu x3,x10,x11\n"
        "sltu x4,x10,x11\n"
        "sltu x5,x10,x11\n"
        "sltu x6,x10,x11\n"
        "sltu x7,x10,x11\n"
        "sltu x8,x10,x11\n"
        "sltu x9,x10,x11\n"
        "sltu x10,x10,x11\n"
        "sltu x11,x10,x11\n"
        "sltu x12,x10,x11\n"
        "sltu x13,x10,x11\n"
        "sltu x14,x10,x11\n"
        "sltu x15,x10,x11\n"
        "sltu x16,x10,x11\n"
        "sltu x17,x10,x11\n"
        "sltu x18,x10,x11\n"
        "sltu x19,x10,x11\n"
        "sltu x20,x10,x11\n"
        "sltu x21,x10,x11\n"
        "sltu x22,x10,x11\n"
        "sltu x23,x10,x11\n"
        "sltu x24,x10,x11\n"
        "sltu x25,x10,x11\n"
        "sltu x26,x10,x11\n"
        "sltu x27,x10,x11\n"
        "sltu x28,x10,x11\n"
        "sltu x29,x10,x11\n"
        "sltu x30,x10,x11\n"
        "sltu x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* XOR */
    asm volatile (
        "xor x0,x10,x11\n"
        "xor x1,x10,x11\n"
        "xor x2,x10,x11\n"
        "xor x3,x10,x11\n"
        "xor x4,x10,x11\n"
        "xor x5,x10,x11\n"
        "xor x6,x10,x11\n"
        "xor x7,x10,x11\n"
        "xor x8,x10,x11\n"
        "xor x9,x10,x11\n"
        "xor x10,x10,x11\n"
        "xor x11,x10,x11\n"
        "xor x12,x10,x11\n"
        "xor x13,x10,x11\n"
        "xor x14,x10,x11\n"
        "xor x15,x10,x11\n"
        "xor x16,x10,x11\n"
        "xor x17,x10,x11\n"
        "xor x18,x10,x11\n"
        "xor x19,x10,x11\n"
        "xor x20,x10,x11\n"
        "xor x21,x10,x11\n"
        "xor x22,x10,x11\n"
        "xor x23,x10,x11\n"
        "xor x24,x10,x11\n"
        "xor x25,x10,x11\n"
        "xor x26,x10,x11\n"
        "xor x27,x10,x11\n"
        "xor x28,x10,x11\n"
        "xor x29,x10,x11\n"
        "xor x30,x10,x11\n"
        "xor x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* SRL */
    asm volatile (
        "srl x0,x10,x11\n"
        "srl x1,x10,x11\n"
        "srl x2,x10,x11\n"
        "srl x3,x10,x11\n"
        "srl x4,x10,x11\n"
        "srl x5,x10,x11\n"
        "srl x6,x10,x11\n"
        "srl x7,x10,x11\n"
        "srl x8,x10,x11\n"
        "srl x9,x10,x11\n"
        "srl x10,x10,x11\n"
        "srl x11,x10,x11\n"
        "srl x12,x10,x11\n"
        "srl x13,x10,x11\n"
        "srl x14,x10,x11\n"
        "srl x15,x10,x11\n"
        "srl x16,x10,x11\n"
        "srl x17,x10,x11\n"
        "srl x18,x10,x11\n"
        "srl x19,x10,x11\n"
        "srl x20,x10,x11\n"
        "srl x21,x10,x11\n"
        "srl x22,x10,x11\n"
        "srl x23,x10,x11\n"
        "srl x24,x10,x11\n"
        "srl x25,x10,x11\n"
        "srl x26,x10,x11\n"
        "srl x27,x10,x11\n"
        "srl x28,x10,x11\n"
        "srl x29,x10,x11\n"
        "srl x30,x10,x11\n"
        "srl x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* SRA */
    asm volatile (
        "li x10,-16\n"
        "li x11,1\n"

        "sra x0,x10,x11\n"
        "sra x1,x10,x11\n"
        "sra x2,x10,x11\n"
        "sra x3,x10,x11\n"
        "sra x4,x10,x11\n"
        "sra x5,x10,x11\n"
        "sra x6,x10,x11\n"
        "sra x7,x10,x11\n"
        "sra x8,x10,x11\n"
        "sra x9,x10,x11\n"
        "sra x10,x10,x11\n"
        "sra x11,x10,x11\n"
        "sra x12,x10,x11\n"
        "sra x13,x10,x11\n"
        "sra x14,x10,x11\n"
        "sra x15,x10,x11\n"
        "sra x16,x10,x11\n"
        "sra x17,x10,x11\n"
        "sra x18,x10,x11\n"
        "sra x19,x10,x11\n"
        "sra x20,x10,x11\n"
        "sra x21,x10,x11\n"
        "sra x22,x10,x11\n"
        "sra x23,x10,x11\n"
        "sra x24,x10,x11\n"
        "sra x25,x10,x11\n"
        "sra x26,x10,x11\n"
        "sra x27,x10,x11\n"
        "sra x28,x10,x11\n"
        "sra x29,x10,x11\n"
        "sra x30,x10,x11\n"
        "sra x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* OR */
    asm volatile (
        "or x0,x10,x11\n"
        "or x1,x10,x11\n"
        "or x2,x10,x11\n"
        "or x3,x10,x11\n"
        "or x4,x10,x11\n"
        "or x5,x10,x11\n"
        "or x6,x10,x11\n"
        "or x7,x10,x11\n"
        "or x8,x10,x11\n"
        "or x9,x10,x11\n"
        "or x10,x10,x11\n"
        "or x11,x10,x11\n"
        "or x12,x10,x11\n"
        "or x13,x10,x11\n"
        "or x14,x10,x11\n"
        "or x15,x10,x11\n"
        "or x16,x10,x11\n"
        "or x17,x10,x11\n"
        "or x18,x10,x11\n"
        "or x19,x10,x11\n"
        "or x20,x10,x11\n"
        "or x21,x10,x11\n"
        "or x22,x10,x11\n"
        "or x23,x10,x11\n"
        "or x24,x10,x11\n"
        "or x25,x10,x11\n"
        "or x26,x10,x11\n"
        "or x27,x10,x11\n"
        "or x28,x10,x11\n"
        "or x29,x10,x11\n"
        "or x30,x10,x11\n"
        "or x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /* AND */
    asm volatile (
        "and x0,x10,x11\n"
        "and x1,x10,x11\n"
        "and x2,x10,x11\n"
        "and x3,x10,x11\n"
        "and x4,x10,x11\n"
        "and x5,x10,x11\n"
        "and x6,x10,x11\n"
        "and x7,x10,x11\n"
        "and x8,x10,x11\n"
        "and x9,x10,x11\n"
        "and x10,x10,x11\n"
        "and x11,x10,x11\n"
        "and x12,x10,x11\n"
        "and x13,x10,x11\n"
        "and x14,x10,x11\n"
        "and x15,x10,x11\n"
        "and x16,x10,x11\n"
        "and x17,x10,x11\n"
        "and x18,x10,x11\n"
        "and x19,x10,x11\n"
        "and x20,x10,x11\n"
        "and x21,x10,x11\n"
        "and x22,x10,x11\n"
        "and x23,x10,x11\n"
        "and x24,x10,x11\n"
        "and x25,x10,x11\n"
        "and x26,x10,x11\n"
        "and x27,x10,x11\n"
        "and x28,x10,x11\n"
        "and x29,x10,x11\n"
        "and x30,x10,x11\n"
        "and x31,x10,x11\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /*
     * ========================================================
     * I-TYPE ALU
     * ========================================================
     */

#define DO_IMM(OP)                         \
    asm volatile (                         \
        OP " x0,x10,1\n"                   \
        OP " x1,x10,1\n"                   \
        OP " x2,x10,1\n"                   \
        OP " x3,x10,1\n"                   \
        OP " x4,x10,1\n"                   \
        OP " x5,x10,1\n"                   \
        OP " x6,x10,1\n"                   \
        OP " x7,x10,1\n"                   \
        OP " x8,x10,1\n"                   \
        OP " x9,x10,1\n"                   \
        OP " x10,x10,1\n"                 \
        OP " x11,x10,1\n"                 \
        OP " x12,x10,1\n"                 \
        OP " x13,x10,1\n"                 \
        OP " x14,x10,1\n"                 \
        OP " x15,x10,1\n"                 \
        OP " x16,x10,1\n"                 \
        OP " x17,x10,1\n"                 \
        OP " x18,x10,1\n"                 \
        OP " x19,x10,1\n"                 \
        OP " x20,x10,1\n"                 \
        OP " x21,x10,1\n"                 \
        OP " x22,x10,1\n"                 \
        OP " x23,x10,1\n"                 \
        OP " x24,x10,1\n"                 \
        OP " x25,x10,1\n"                 \
        OP " x26,x10,1\n"                 \
        OP " x27,x10,1\n"                 \
        OP " x28,x10,1\n"                 \
        OP " x29,x10,1\n"                 \
        OP " x30,x10,1\n"                 \
        OP " x31,x10,1\n"                 \
        : : : "memory"                     \
    );

    DO_IMM("addi");
    DO_IMM("slti");
    DO_IMM("sltiu");
    DO_IMM("xori");
    DO_IMM("ori");
    DO_IMM("andi");


    /*
     * Shift immediate
     */

    DO_IMM("slli");
    DO_IMM("srli");
    DO_IMM("srai");


    /*
     * ========================================================
     * LUI
     * ========================================================
     */

    asm volatile (
        "lui x0,0x12345\n"
        "lui x1,0x12345\n"
        "lui x2,0x12345\n"
        "lui x3,0x12345\n"
        "lui x4,0x12345\n"
        "lui x5,0x12345\n"
        "lui x6,0x12345\n"
        "lui x7,0x12345\n"
        "lui x8,0x12345\n"
        "lui x9,0x12345\n"
        "lui x10,0x12345\n"
        "lui x11,0x12345\n"
        "lui x12,0x12345\n"
        "lui x13,0x12345\n"
        "lui x14,0x12345\n"
        "lui x15,0x12345\n"
        "lui x16,0x12345\n"
        "lui x17,0x12345\n"
        "lui x18,0x12345\n"
        "lui x19,0x12345\n"
        "lui x20,0x12345\n"
        "lui x21,0x12345\n"
        "lui x22,0x12345\n"
        "lui x23,0x12345\n"
        "lui x24,0x12345\n"
        "lui x25,0x12345\n"
        "lui x26,0x12345\n"
        "lui x27,0x12345\n"
        "lui x28,0x12345\n"
        "lui x29,0x12345\n"
        "lui x30,0x12345\n"
        "lui x31,0x12345\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /*
     * ========================================================
     * AUIPC
     * ========================================================
     */

    asm volatile (
        "auipc x0,0\n"
        "auipc x1,0\n"
        "auipc x2,0\n"
        "auipc x3,0\n"
        "auipc x4,0\n"
        "auipc x5,0\n"
        "auipc x6,0\n"
        "auipc x7,0\n"
        "auipc x8,0\n"
        "auipc x9,0\n"
        "auipc x10,0\n"
        "auipc x11,0\n"
        "auipc x12,0\n"
        "auipc x13,0\n"
        "auipc x14,0\n"
        "auipc x15,0\n"
        "auipc x16,0\n"
        "auipc x17,0\n"
        "auipc x18,0\n"
        "auipc x19,0\n"
        "auipc x20,0\n"
        "auipc x21,0\n"
        "auipc x22,0\n"
        "auipc x23,0\n"
        "auipc x24,0\n"
        "auipc x25,0\n"
        "auipc x26,0\n"
        "auipc x27,0\n"
        "auipc x28,0\n"
        "auipc x29,0\n"
        "auipc x30,0\n"
        "auipc x31,0\n"
        :
        :
        : "memory"
    );

    RESTORE_SP();


    /*
     * ========================================================
     * END
     * ========================================================
     */

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}