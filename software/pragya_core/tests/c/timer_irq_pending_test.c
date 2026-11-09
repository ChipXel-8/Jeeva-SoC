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
     * Global interrupts OFF
     */
    mstatus = read_mstatus();
    mstatus &= ~(1u << 3);
    write_mstatus(mstatus);

    /*
     * Timer interrupt enable ON
     */
    mie = read_mie();
    mie |= (1u << 7);
    write_mie(mie);

    /*
     * Verify MIE = 0
     */
    mstatus = read_mstatus();

    if (mstatus & (1u << 3))
        test_fail();

    /*
     * Verify MTIE = 1
     */
    mie = read_mie();

    if ((mie & (1u << 7)) == 0)
        test_fail();

    /*
     * Tell TB:
     * generate timer IRQ/pending condition now.
     */
    *irq_ready = 2;

    /*
     * Interrupt MUST NOT be taken because
     * MSTATUS.MIE = 0.
     */
    for (volatile int i = 0; i < 100; i++)
        asm volatile ("nop");

    /*
     * If execution reaches here, global interrupt
     * masking worked.
     */
    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}
