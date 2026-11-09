#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA MACHINE EXTERNAL INTERRUPT TEST
 *
 * MSTATUS.MIE = bit 3
 * MIE.MEIE    = bit 11
 *
 * Expected MCAUSE:
 *
 *     0x8000000B
 *
 * bit 31 = 1 -> interrupt
 * cause 11   -> Machine External Interrupt
 * ============================================================
 */


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


int main(void)
{
    uint32_t mstatus;
    uint32_t mie;

    volatile uint32_t *irq_ready =
        (volatile uint32_t *)0x80007FF0;


    /*
     * ========================================================
     * STEP 1:
     * Enable global machine interrupts
     * ========================================================
     */

    mstatus = read_mstatus();

    mstatus |= (1u << 3);

    write_mstatus(mstatus);


    /*
     * ========================================================
     * STEP 2:
     * Enable Machine External Interrupt
     *
     * MIE.MEIE = bit 11
     * ========================================================
     */

    mie = read_mie();

    mie |= (1u << 11);

    write_mie(mie);


    /*
     * ========================================================
     * STEP 3:
     * Verify MSTATUS.MIE
     * ========================================================
     */

    mstatus = read_mstatus();

    if ((mstatus & (1u << 3)) == 0)
    {
        test_fail();
    }


    /*
     * ========================================================
     * STEP 4:
     * Verify MIE.MEIE
     * ========================================================
     */

    mie = read_mie();

    if ((mie & (1u << 11)) == 0)
    {
        test_fail();
    }


    /*
     * ========================================================
     * STEP 5:
     * Tell TB that interrupt setup is complete
     * ========================================================
     */

    *irq_ready = 1;


    /*
     * ========================================================
     * STEP 6:
     * Instructions executed while waiting for interrupt
     * ========================================================
     */

    volatile uint32_t before_trap = 0x11111111;

    before_trap += 1;
    before_trap += 1;


    /*
     * ========================================================
     * STEP 7:
     *
     * These instructions MUST execute after MRET.
     * ========================================================
     */

    volatile uint32_t after_trap = 0x22222222;

    after_trap += 1;
    after_trap += 1;


    /*
     * ========================================================
     * STEP 8:
     * Verify execution after returning from trap
     * ========================================================
     */

    if (after_trap != 0x22222224)
    {
        test_fail();
    }


    /*
     * ========================================================
     * TEST PASS
     * ========================================================
     */

    test_pass();


    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}
