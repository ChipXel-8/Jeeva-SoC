#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * SOFTWARE INTERRUPT - VECTORED MODE COVERAGE TEST
 *
 * Purpose:
 *   Hit:
 *
 *       software interrupt
 *       MTVEC.MODE = 01
 *
 * Coverage target:
 *
 *       software × vectored
 *
 * MCAUSE = 0x80000003
 * MIE.MSIE = bit 3
 * MSTATUS.MIE = bit 3
 * ============================================================
 */

static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile("csrr %0, mstatus"
                 : "=r"(value));

    return value;
}

static inline void write_mstatus(uint32_t value)
{
    asm volatile("csrw mstatus, %0"
                 :
                 : "r"(value)
                 : "memory");
}

static inline uint32_t read_mie(void)
{
    uint32_t value;

    asm volatile("csrr %0, mie"
                 : "=r"(value));

    return value;
}

static inline void write_mie(uint32_t value)
{
    asm volatile("csrw mie, %0"
                 :
                 : "r"(value)
                 : "memory");
}

static inline uint32_t read_mtvec(void)
{
    uint32_t value;

    asm volatile("csrr %0, mtvec"
                 : "=r"(value));

    return value;
}

static inline void write_mtvec(uint32_t value)
{
    asm volatile("csrw mtvec, %0"
                 :
                 : "r"(value)
                 : "memory");
}


int main(void)
{
    uint32_t mstatus;
    uint32_t mie;
    uint32_t mtvec;

    volatile uint32_t *irq_ready =
        (volatile uint32_t *)0x80007FF0;

    volatile uint32_t *result =
        (volatile uint32_t *)0x80007FF4;


    /*
     * --------------------------------------------------------
     * Configure MTVEC = VECTORED MODE
     *
     * Preserve the existing trap base.
     * Only change MODE bits [1:0] to 01.
     * --------------------------------------------------------
     */

    mtvec = read_mtvec();

    mtvec = (mtvec & ~0x3u) | 0x1u;

    write_mtvec(mtvec);

    mtvec = read_mtvec();

    if ((mtvec & 0x3u) != 0x1u)
    {
        test_fail();
    }


    /*
     * --------------------------------------------------------
     * Enable global interrupts
     * --------------------------------------------------------
     */

    mstatus = read_mstatus();

    mstatus |= (1u << 3);

    write_mstatus(mstatus);


    /*
     * --------------------------------------------------------
     * Enable software interrupt
     *
     * MIE.MSIE = bit 3
     * --------------------------------------------------------
     */

    mie = read_mie();

    mie |= (1u << 3);

    write_mie(mie);


    /*
     * Verify enables.
     */

    mstatus = read_mstatus();
    mie     = read_mie();

    if ((mstatus & (1u << 3)) == 0)
        test_fail();

    if ((mie & (1u << 3)) == 0)
        test_fail();


    /*
     * Clear result.
     */

    *result = 0;


    /*
     * Tell TB to generate software IRQ.
     */

    *irq_ready = 1;


    /*
     * --------------------------------------------------------
     * Give TB time to assert interrupt.
     * --------------------------------------------------------
     */

    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");


    /*
     * --------------------------------------------------------
     * Execution after MRET.
     * --------------------------------------------------------
     */

    *result = 0x53575601;


    if (*result != 0x53575601)
    {
        test_fail();
    }


    /*
     * PASS
     */

    *irq_ready = 2;

    while (1)
    {
        asm volatile("nop");
    }

    return 0;
}
