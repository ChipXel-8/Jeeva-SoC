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

    volatile uint32_t *irq_ready =
        (volatile uint32_t *)0x80007FF0;

    /*
     * Disable global interrupts
     * MSTATUS.MIE = 0
     */
    mstatus = read_mstatus();
    mstatus &= ~(1u << 3);
    write_mstatus(mstatus);

    /*
     * Disable timer interrupt
     * MIE.MTIE = 0
     */
    mie = read_mie();
    mie &= ~(1u << 7);
    write_mie(mie);

    /*
     * Verify MSTATUS.MIE = 0
     */
    mstatus = read_mstatus();

    if (mstatus & (1u << 3))
        test_fail();

    /*
     * Verify MIE.MTIE = 0
     */
    mie = read_mie();

    if (mie & (1u << 7))
        test_fail();

    /*
     * Tell TB to assert TIMER IRQ.
     *
     * At this point:
     *
     * timer = active   -> 1
     * MTIE  = disabled  -> 0
     * MIE   = disabled  -> 0
     *
     * Required cross:
     *
     * <active,disabled,disabled>
     */
    *irq_ready = 4;

    /*
     * Interrupt must NOT be taken.
     */
    for (volatile int i = 0; i < 100; i++)
        asm volatile ("nop");

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}