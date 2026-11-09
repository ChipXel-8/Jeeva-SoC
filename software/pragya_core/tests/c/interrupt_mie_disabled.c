#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA INTERRUPT GLOBAL MIE DISABLE TEST
 *
 * Purpose:
 *   Cover:
 *
 *       MSTATUS.MIE = 0
 *
 * This test does NOT expect an interrupt.
 * It verifies that global interrupt enable can be disabled.
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

int main(void)
{
    uint32_t mstatus;

    /*
     * Read current MSTATUS
     */
    mstatus = read_mstatus();

    /*
     * Clear MSTATUS.MIE
     */
    mstatus &= ~(1u << 3);

    write_mstatus(mstatus);

    /*
     * Read back
     */
    mstatus = read_mstatus();

    /*
     * Verify MIE = 0
     */
    if (mstatus & (1u << 3))
    {
        test_fail();
    }

    /*
     * Leave the core running with interrupts disabled.
     */
    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}