#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile ("csrr %0, mstatus" : "=r"(value));

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

    asm volatile ("csrr %0, mie" : "=r"(value));

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

    /* Disable global interrupts */
    mstatus = read_mstatus();
    mstatus &= ~(1u << 3);
    write_mstatus(mstatus);

    /* Enable machine timer interrupt */
    mie = read_mie();
    mie |= (1u << 7);
    write_mie(mie);

    /* Verify MIE = 0 */
    mstatus = read_mstatus();

    if (mstatus & (1u << 3))
        test_fail();

    /* Verify MTIE = 1 */
    mie = read_mie();

    if ((mie & (1u << 7)) == 0)
        test_fail();

    /*
     * Tell TB:
     * software is ready for timer interrupt.
     */
    volatile uint32_t *irq_ready =
        (volatile uint32_t *)0x80007FF0;

    *irq_ready = 2;

    /*
     * Wait.
     *
     * Since MSTATUS.MIE = 0,
     * timer interrupt must NOT enter trap.
     */
    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}
