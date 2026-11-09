#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * RV32I INSTRUCTION × FORMAT COVERAGE TEST
 * ============================================================
 *
 * LEGAL CROSS BINS:
 *
 * R-TYPE : 10
 * I-TYPE : 15
 * S-TYPE : 3
 * B-TYPE : 6
 * U-TYPE : 2
 * J-TYPE : 1
 *
 * TOTAL   : 37 LEGAL BINS
 *
 * RV32I ONLY
 *
 * No RV32M
 * No SYSTEM
 * No CSR
 * No FENCE
 * ============================================================
 */


/* ============================================================
 * Memory used by load/store instructions
 * ============================================================ */

volatile uint8_t  mem8[16]  __attribute__((aligned(4)));
volatile uint16_t mem16[8]  __attribute__((aligned(4)));
volatile uint32_t mem32[8]  __attribute__((aligned(4)));


/* ============================================================
 * Main test
 * ============================================================ */

int main(void)
{

    /*==========================================================
      U-TYPE
      ==========================================================

      LUI
      AUIPC

      Legal bins:

          LUI   × U_TYPE
          AUIPC × U_TYPE

      2 bins
    ==========================================================*/

    asm volatile (

        "lui   t0, 0x12345\n"

        "auipc t1, 0\n"

        :
        :
        : "t0", "t1"
    );


    /*==========================================================
      R-TYPE
      ==========================================================

      ADD
      SUB
      SLL
      SLT
      SLTU
      XOR
      SRL
      SRA
      OR
      AND

      10 bins
    ==========================================================*/

    asm volatile (

        "addi  t0, zero, 20\n"
        "addi  t1, zero, 5\n"

        /* ADD × R_TYPE */
        "add   t2, t0, t1\n"

        /* SUB × R_TYPE */
        "sub   t2, t0, t1\n"

        /* SLL × R_TYPE */
        "sll   t2, t0, t1\n"

        /* SLT × R_TYPE */
        "slt   t2, t0, t1\n"

        /* SLTU × R_TYPE */
        "sltu  t2, t0, t1\n"

        /* XOR × R_TYPE */
        "xor   t2, t0, t1\n"

        /* SRL × R_TYPE */
        "srl   t2, t0, t1\n"

        /* SRA × R_TYPE */
        "sra   t2, t0, t1\n"

        /* OR × R_TYPE */
        "or    t2, t0, t1\n"

        /* AND × R_TYPE */
        "and   t2, t0, t1\n"

        :
        :
        : "t0", "t1", "t2"
    );


    /*==========================================================
      I-TYPE ALU
      ==========================================================

      ADDI
      SLTI
      SLTIU
      XORI
      ORI
      ANDI
      SLLI
      SRLI
      SRAI

      9 bins
    ==========================================================*/

    asm volatile (

        /* ADDI × I_TYPE */
        "addi  t0, zero, 10\n"

        /* SLTI × I_TYPE */
        "slti  t1, t0, 20\n"

        /* SLTIU × I_TYPE */
        "sltiu t1, t0, 20\n"

        /* XORI × I_TYPE */
        "xori  t1, t0, 0x0f\n"

        /* ORI × I_TYPE */
        "ori   t1, t0, 0x0f\n"

        /* ANDI × I_TYPE */
        "andi  t1, t0, 0x0f\n"

        /* SLLI × I_TYPE */
        "slli  t1, t0, 2\n"

        /* SRLI × I_TYPE */
        "srli  t1, t0, 1\n"

        /* SRAI × I_TYPE */
        "srai  t1, t0, 1\n"

        :
        :
        : "t0", "t1"
    );


    /*==========================================================
      LOAD I-TYPE
      ==========================================================

      LB
      LH
      LW
      LBU
      LHU

      5 bins
    ==========================================================*/

    /*----------------------------------------------------------
      Initialize memory
    ----------------------------------------------------------*/

    mem8[0] = 0x80;
    mem8[1] = 0x7f;
    mem8[2] = 0x34;
    mem8[3] = 0x12;

    mem16[0] = 0x1234;
    mem16[1] = 0x5678;

    mem32[0] = 0x12345678;


    /*----------------------------------------------------------
      Execute all five load instructions
    ----------------------------------------------------------*/

    asm volatile (

        /* LB × I_TYPE */
        "lb    t0, 0(%0)\n"

        /* LH × I_TYPE */
        "lh    t1, 0(%1)\n"

        /* LW × I_TYPE */
        "lw    t2, 0(%2)\n"

        /* LBU × I_TYPE */
        "lbu   t0, 0(%0)\n"

        /* LHU × I_TYPE */
        "lhu   t1, 0(%1)\n"

        :
        : "r"(mem8),
          "r"(mem16),
          "r"(mem32)
        : "t0", "t1", "t2", "memory"
    );


    /*==========================================================
      JALR I-TYPE
      ==========================================================

      JALR × I_TYPE

      1 bin
    ==========================================================*/

    asm volatile (

        /*
         * Load address of target.
         *
         * The important instruction here is JALR itself.
         */
        "la    t0, jalr_target\n"

        /* JALR × I_TYPE */
        "jalr  t1, 0(t0)\n"

        /*
         * Target of JALR
         */
        "jalr_target:\n"

        "addi  t2, zero, 1\n"

        :
        :
        : "t0", "t1", "t2"
    );


    /*==========================================================
      S-TYPE
      ==========================================================

      SB
      SH
      SW

      3 bins
    ==========================================================*/

    asm volatile (

        /* SB × S_TYPE */
        "sb    t0, 0(%0)\n"

        /* SH × S_TYPE */
        "sh    t1, 0(%1)\n"

        /* SW × S_TYPE */
        "sw    t2, 0(%2)\n"

        :
        : "r"(mem8),
          "r"(mem16),
          "r"(mem32)
        : "memory"
    );


    /*==========================================================
      B-TYPE
      ==========================================================

      BEQ
      BNE
      BLT
      BGE
      BLTU
      BGEU

      6 bins

      We execute every branch instruction.

      The actual taken/not-taken condition is not important
      for cross_instr_format. The important point is that
      the branch instruction retires/executed.
    ==========================================================*/

    asm volatile (

        "addi  t0, zero, 10\n"
        "addi  t1, zero, 20\n"


        /*------------------------------------------------------
          BEQ × B_TYPE
          10 != 20 -> not taken
        ------------------------------------------------------*/

        "beq   t0, t1, beq_target\n"

        "addi  t2, zero, 1\n"

        "beq_target:\n"


        /*------------------------------------------------------
          BNE × B_TYPE
          10 != 20 -> taken
        ------------------------------------------------------*/

        "bne   t0, t1, bne_target\n"

        "addi  t2, zero, 2\n"

        "bne_target:\n"


        /*------------------------------------------------------
          BLT × B_TYPE
          10 < 20 -> taken
        ------------------------------------------------------*/

        "blt   t0, t1, blt_target\n"

        "addi  t2, zero, 3\n"

        "blt_target:\n"


        /*------------------------------------------------------
          BGE × B_TYPE
          20 >= 10 -> taken
        ------------------------------------------------------*/

        "bge   t1, t0, bge_target\n"

        "addi  t2, zero, 4\n"

        "bge_target:\n"


        /*------------------------------------------------------
          BLTU × B_TYPE
          10 < 20 unsigned -> taken
        ------------------------------------------------------*/

        "bltu  t0, t1, bltu_target\n"

        "addi  t2, zero, 5\n"

        "bltu_target:\n"


        /*------------------------------------------------------
          BGEU × B_TYPE
          20 >= 10 unsigned -> taken
        ------------------------------------------------------*/

        "bgeu  t1, t0, bgeu_target\n"

        "addi  t2, zero, 6\n"

        "bgeu_target:\n"

        :
        :
        : "t0", "t1", "t2"
    );


    /*==========================================================
      J-TYPE
      ==========================================================

      JAL

      1 bin
    ==========================================================*/

    asm volatile (

        /*
         * JAL × J_TYPE
         *
         * rd = x0 because we don't need the return address.
         */
        "jal   zero, jal_target\n"

        /*
         * This instruction should be skipped by JAL.
         */
        "addi  t0, zero, 0\n"

        "jal_target:\n"

        "addi  t1, zero, 1\n"

        :
        :
        : "t0", "t1"
    );


    /*==========================================================
      FINAL CHECK
      ==========================================================*/

    test_pass();

    return 0;
}