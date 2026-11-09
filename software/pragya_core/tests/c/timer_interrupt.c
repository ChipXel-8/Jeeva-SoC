#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA TIMER INTERRUPT + MRET + RESUME TEST
 *
 * Test flow:
 *
 *   1. Enable MSTATUS.MIE
 *   2. Enable MIE.MTIE
 *   3. Tell TB that software is ready
 *   4. Execute normal instructions
 *   5. TB asserts timer interrupt
 *   6. Core saves MEPC
 *   7. Core jumps to MTVEC
 *   8. trap.S reads MCause/MEPC/MTVAL
 *   9. trap.S executes MRET
 *  10. Core returns to MEPC
 *  11. Normal execution continues
 *  12. Test writes PASS value
 *
 * Timer interrupt cause:
 *
 *     MCAUSE = 0x80000007
 *
 *     bit 31 = 1  -> interrupt
 *     cause 7   -> Machine Timer Interrupt
 * ============================================================
 */


/* ------------------------------------------------------------
 * CSR: MSTATUS
 * ------------------------------------------------------------ */

static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mstatus"
        : "=r"(value)
    );

    return value;
}


static inline void write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw mstatus, %0"
        :
        : "r"(value)
        : "memory"
    );
}


/* ------------------------------------------------------------
 * CSR: MIE
 * ------------------------------------------------------------ */

static inline uint32_t read_mie(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mie"
        : "=r"(value)
    );

    return value;
}


static inline void write_mie(uint32_t value)
{
    asm volatile (
        "csrw mie, %0"
        :
        : "r"(value)
        : "memory"
    );
}


/* ------------------------------------------------------------
 * MAIN
 * ------------------------------------------------------------ */

int main(void)
{
    uint32_t mstatus;
    uint32_t mie;

    /*
     * --------------------------------------------------------
     * Signature / TB communication locations
     * --------------------------------------------------------
     */

    volatile uint32_t *irq_ready =
        (volatile uint32_t *)0x80007FF0;

    volatile uint32_t *resume_result =
        (volatile uint32_t *)0x80007FF4;


    /*
     * --------------------------------------------------------
     * STEP 1:
     * Enable global machine interrupts.
     *
     * MSTATUS.MIE = bit 3
     * --------------------------------------------------------
     */

    mstatus = read_mstatus();

    mstatus |= (1u << 3);

    write_mstatus(mstatus);


    /*
     * --------------------------------------------------------
     * STEP 2:
     * Enable machine timer interrupt.
     *
     * MIE.MTIE = bit 7
     * --------------------------------------------------------
     */

    mie = read_mie();

    mie |= (1u << 7);

    write_mie(mie);


    /*
     * --------------------------------------------------------
     * STEP 3:
     * Verify MSTATUS.MIE
     * --------------------------------------------------------
     */

    mstatus = read_mstatus();

    if ((mstatus & (1u << 3)) == 0)
    {
        test_fail();
    }


    /*
     * --------------------------------------------------------
     * STEP 4:
     * Verify MIE.MTIE
     * --------------------------------------------------------
     */

    mie = read_mie();

    if ((mie & (1u << 7)) == 0)
    {
        test_fail();
    }


    /*
     * --------------------------------------------------------
     * STEP 5:
     *
     * Clear result location.
     * --------------------------------------------------------
     */

    *resume_result = 0;


    /*
     * --------------------------------------------------------
     * STEP 6:
     *
     * Tell testbench:
     *
     * "Interrupts are enabled.
     *  Now inject timer interrupt."
     *
     * TB watches 0x80007FF0.
     * --------------------------------------------------------
     */

    *irq_ready = 1;


    /*
     * --------------------------------------------------------
     * STEP 7:
     *
     * NORMAL EXECUTION BEFORE INTERRUPT
     *
     * These instructions are intentionally here so that the
     * interrupt occurs while the program is executing normally.
     * --------------------------------------------------------
     */

    volatile uint32_t value = 0;

    value = 0x11111111;
    value = value + 1;

    value = 0x22222222;
    value = value + 2;

    value = 0x33333333;
    value = value + 3;


    /*
     * --------------------------------------------------------
     * STEP 8:
     *
     * The TB should assert the timer interrupt around here.
     *
     * The core should:
     *
     *       MEPC = current PC
     *       MCAUSE = 0x80000007
     *       PC = MTVEC
     *
     * Then trap.S executes:
     *
     *       csrr t0, mcause
     *       csrr t1, mepc
     *       csrr t2, mtval
     *       ...
     *       mret
     *
     * --------------------------------------------------------
     */

    asm volatile ("nop");
    asm volatile ("nop");
    asm volatile ("nop");
    asm volatile ("nop");


    /*
     * --------------------------------------------------------
     * STEP 9:
     *
     * IMPORTANT:
     *
     * These instructions MUST execute after MRET.
     *
     * If MRET works correctly, execution returns to MEPC and
     * eventually reaches this code.
     * --------------------------------------------------------
     */

    value = value + 0x10;
    value = value + 0x20;
    value = value + 0x30;


    /*
     * --------------------------------------------------------
     * STEP 10:
     *
     * Write a distinctive PASS value.
     *
     * This proves that normal execution continued after MRET.
     * --------------------------------------------------------
     */

    *resume_result = 0x44444444;


    /*
     * --------------------------------------------------------
     * STEP 11:
     *
     * Final PASS indication.
     * --------------------------------------------------------
     */

    *irq_ready = 2;


    /*
     * Keep processor here.
     */

    while (1)
    {
        asm volatile ("nop");
    }


    return 0;
}
