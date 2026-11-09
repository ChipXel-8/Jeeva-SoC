#include "pragya_test.h"
#include <stdint.h>

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
     * Enable global machine interrupts.
     *
     * MSTATUS.MIE = 1
     * ========================================================
     */

    mstatus = read_mstatus();

    mstatus |= (1u << 3);

    write_mstatus(mstatus);


    /*
     * ========================================================
     * STEP 2:
     * Disable machine timer interrupt.
     *
     * MIE.MTIE = 0
     * ========================================================
     */

    mie = read_mie();

    mie &= ~(1u << 7);

    write_mie(mie);


    /*
     * ========================================================
     * STEP 3:
     * Verify global MIE = 1
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
     * Verify MTIE = 0
     * ========================================================
     */

    mie = read_mie();

    if (mie & (1u << 7))
    {
        test_fail();
    }


    /*
     * ========================================================
     * STEP 5:
     *
     * Tell TB to assert timer IRQ.
     *
     * Expected:
     *
     * irq_timer = 1
     * MIE.MTIE  = 0
     * MSTATUS.MIE = 1
     *
     * Therefore the timer interrupt must NOT be taken.
     * ========================================================
     */

    *irq_ready = 3;


    /*
     * ========================================================
     * STEP 6:
     *
     * Give TB time to assert timer interrupt.
     * ========================================================
     */

    for (volatile int i = 0; i < 100; i++)
    {
        asm volatile ("nop");
    }


    /*
     * ========================================================
     * STEP 7:
     *
     * If execution reaches here, MTIE correctly blocked
     * the timer interrupt.
     * ========================================================
     */

    test_pass();


    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}