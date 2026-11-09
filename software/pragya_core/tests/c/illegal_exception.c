#include "pragya_test.h"
#include <stdint.h>


/*
 * ============================================================
 * PRAGYA ILLEGAL INSTRUCTION EXCEPTION TEST
 *
 * Purpose:
 *
 *      Generate one illegal instruction exception.
 *
 * Expected:
 *
 *      MCAUSE = 2
 *      MTVAL  = 0xFFFFFFFF
 *      MEPC   = address of illegal instruction
 *
 *      trap.S handles the exception and executes MRET.
 *
 * After MRET:
 *
 *      execution continues after the illegal instruction.
 *
 * ============================================================
 */


/* ============================================================
 * CSR READ FUNCTIONS
 * ============================================================ */

static inline uint32_t read_mcause(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mcause"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t read_mepc(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mepc"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t read_mtval(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mtval"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * ILLEGAL INSTRUCTION TEST
 * ============================================================ */

static void test_illegal_instruction(void)
{
    /*
     * --------------------------------------------------------
     * Generate illegal instruction.
     *
     * 0xFFFFFFFF is not a valid RV32I/RV32M instruction.
     *
     * Expected:
     *
     *      MCAUSE = 2
     *      MTVAL  = 0xFFFFFFFF
     *
     * --------------------------------------------------------
     */

    asm volatile (
        ".word 0xFFFFFFFF"
        :
        :
        : "memory"
    );


    /*
     * --------------------------------------------------------
     * These instructions must execute AFTER MRET.
     * --------------------------------------------------------
     */

    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t cause;
    volatile uint32_t epc;
    volatile uint32_t tval;


    /*
     * ========================================================
     * ILLEGAL INSTRUCTION
     * ========================================================
     */

    test_illegal_instruction();


    /*
     * ========================================================
     * READ TRAP CSRs
     *
     * These execute after the trap has returned.
     * ========================================================
     */

    cause = read_mcause();
    epc   = read_mepc();
    tval  = read_mtval();


    /*
     * Prevent compiler optimization.
     */

    (void)cause;
    (void)epc;
    (void)tval;


    /*
     * ========================================================
     * PASS
     * ========================================================
     */

    test_pass();


    /*
     * ========================================================
     * STOP
     * ========================================================
     */

    while (1)
    {
        asm volatile ("nop");
    }


    return 0;
}
