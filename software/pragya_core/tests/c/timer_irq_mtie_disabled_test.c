#include "pragya_test.h"
#include <stdint.h>

/*
 * TIMER IRQ ACTIVE
 *
 * MSTATUS.MIE = 1
 * MIE.MTIE    = 0
 *
 * Timer interrupt must NOT be taken.
 *
 * Coverage target:
 *
 *     <active,disabled,enabled>
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
     * --------------------------------------------------------
     * Enable global machine interrupts
     *
     * MSTATUS.MIE = 1
     * --------------------------------------------------------
     */

    mstatus = read_mstatus();

    mstatus |= (1u << 3);

    write_mstatus(mstatus);


    /*
     * --------------------------------------------------------
     * Disable machine timer interrupt
     *
     * MIE.MTIE = 0
     * --------------------------------------------------------
     */

    mie = read_mie();

    mie &= ~(1u << 7);

    write_mie(mie);


    /*
     * --------------------------------------------------------
     * Verify MSTATUS.MIE = 1
     * --------------------------------------------------------
     */

    mstatus = read_mstatus();

    if ((mstatus & (1u << 3)) == 0)
    {
        test_fail();
    }


    /*
     * --------------------------------------------------------
     * Verify MIE.MTIE = 0
     * --------------------------------------------------------
     */

    mie = read_mie();

    if (mie & (1u << 7))
    {
        test_fail();
    }


    /*
     * --------------------------------------------------------
     * Tell TB:
     *
     * Program is ready.
     *
     * Use value 3 to distinguish this test from the
     * existing timer_irq_pending_test which uses value 2.
     * --------------------------------------------------------
     */

    *irq_ready = 3;


    /*
     * --------------------------------------------------------
     * Continue normal execution.
     *
     * TB will assert TIMER IRQ while:
     *
     *     MSTATUS.MIE = 1
     *     MIE.MTIE    = 0
     *
     * Therefore interrupt MUST NOT be taken.
     * --------------------------------------------------------
     */

    for (volatile int i = 0; i < 100; i++)
    {
        asm volatile ("nop");
    }


    /*
     * TB performs the final PASS/finish.
     */

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}