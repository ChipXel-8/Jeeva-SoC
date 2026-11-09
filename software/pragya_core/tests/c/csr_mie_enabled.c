#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * MIE ENABLE CROSS COVERAGE TEST
 *
 * Purpose:
 *   Cover the two missing combinations in:
 *
 *       cp_mie_msie x cp_mie_mtie x cp_mie_meie
 *
 * MIE bits:
 *
 *   MIE[3]  = MSIE
 *   MIE[7]  = MTIE
 *   MIE[11] = MEIE
 *
 *
 * Missing bins:
 *
 *   1. MSIE=1, MTIE=0, MEIE=1
 *      MIE = 0x00000808
 *
 *   2. MSIE=1, MTIE=1, MEIE=0
 *      MIE = 0x00000088
 *
 * ============================================================
 */


/* ============================================================
 * MIE WRITE
 * ============================================================ */

static inline uint32_t mie_write(uint32_t value)
{
    uint32_t result;

    asm volatile (
        "csrrw %0, 0x304, %1"
        : "=r"(result)
        : "r"(value)
        : "memory"
    );

    return result;
}


/* ============================================================
 * MIE READ
 * ============================================================ */

static inline uint32_t mie_read(void)
{
    uint32_t result;

    asm volatile (
        "csrrs %0, 0x304, x0"
        : "=r"(result)
        :
        : "memory"
    );

    return result;
}


/* ============================================================
 * SMALL DELAY
 *
 * Gives the CSR write time to propagate before sampling
 * the MIE value through the following CSR access.
 * ============================================================ */

static inline void csr_delay(void)
{
    asm volatile (
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


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t value = 0;


    /*
     * ========================================================
     * MISSING BIN 1
     *
     * MSIE = 1
     * MTIE = 0
     * MEIE = 1
     *
     * MIE[3]  = 1
     * MIE[7]  = 0
     * MIE[11] = 1
     *
     * MIE = 0x00000808
     * ========================================================
     */

    value = mie_write(0x00000808);

    csr_delay();

    value = mie_read();

    if (value != 0x00000808)
    {
        test_fail();
    }


    /*
     * Second access with the same configuration.
     *
     * This gives the coverage collector another sampling
     * opportunity with:
     *
     * MSIE=1 MTIE=0 MEIE=1
     * ========================================================
     */

    csr_delay();

    value = mie_read();

    if (value != 0x00000808)
    {
        test_fail();
    }


    /*
     * ========================================================
     * MISSING BIN 2
     *
     * MSIE = 1
     * MTIE = 1
     * MEIE = 0
     *
     * MIE[3]  = 1
     * MIE[7]  = 1
     * MIE[11] = 0
     *
     * MIE = 0x00000088
     * ========================================================
     */

    value = mie_write(0x00000088);

    csr_delay();

    value = mie_read();

    if (value != 0x00000088)
    {
        test_fail();
    }


    /*
     * Second access with the same configuration.
     * ========================================================
     */

    csr_delay();

    value = mie_read();

    if (value != 0x00000088)
    {
        test_fail();
    }


    /*
     * ========================================================
     * RESTORE MIE
     *
     * Disable all machine interrupts before finishing.
     * ========================================================
     */

    value = mie_write(0x00000000);

    csr_delay();

    value = mie_read();


    /*
     * ========================================================
     * PREVENT OPTIMIZATION
     * ========================================================
     */

    (void)value;


    /*
     * ========================================================
     * PASS
     * ========================================================
     */

    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}
