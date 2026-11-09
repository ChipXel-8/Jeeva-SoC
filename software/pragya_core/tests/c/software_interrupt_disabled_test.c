#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * SOFTWARE INTERRUPT - MSIE DISABLED TEST
 *
 * Coverage target:
 *
 * Line 107:
 *
 *     msie_in & s_irq_in
 *
 * Required combination:
 *
 *     msie_in = 0
 *     s_irq_in = 1
 *
 * mie.MSIE = bit 3
 * ============================================================
 */

#define CSR_MIE      0x304
#define CSR_MSTATUS  0x300


static inline void csr_write_mie(uint32_t value)
{
    asm volatile (
        "csrw 0x304, %0"
        :
        : "r"(value)
        : "memory"
    );
}


static inline uint32_t csr_read_mie(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x304"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline void csr_write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw 0x300, %0"
        :
        : "r"(value)
        : "memory"
    );
}


static void delay(void)
{
    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


int main(void)
{
    uint32_t mie_value;


    /*
     * Disable global machine interrupts.
     */
    csr_write_mstatus(0x00000000);


    /*
     * Explicitly clear MSIE.
     *
     * mie[3] = MSIE
     */
    mie_value = csr_read_mie();

    mie_value &= ~(1U << 3);

    csr_write_mie(mie_value);


    /*
     * Wait while software interrupt source is asserted.
     *
     * IMPORTANT:
     *
     * s_irq_in must become 1 from your existing
     * software-interrupt stimulus.
     */
    for (volatile uint32_t i = 0; i < 200; i++)
    {
        delay();
    }


    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );


    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}