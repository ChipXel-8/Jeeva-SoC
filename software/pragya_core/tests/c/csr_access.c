#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * MIE ENABLE CROSS COVERAGE
 *
 * Missing bins:
 *
 *   MSIE MTIE MEIE
 *    0    1    1   -> 0x00000880
 *    1    1    1   -> 0x00000888
 *
 * MIE bit positions:
 *
 *   MIE[3]  = MSIE
 *   MIE[7]  = MTIE
 *   MIE[11] = MEIE
 * ============================================================
 */

static inline void mie_write(uint32_t value)
{
    asm volatile (
        "csrrw x0, 0x304, %0"
        :
        : "r"(value)
        : "memory"
    );
}

static inline uint32_t mie_read(void)
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

static inline void delay(void)
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
    volatile uint32_t value;

    /*
     * ========================================================
     * BIN 1 : 011
     *
     * MSIE = 0
     * MTIE = 1
     * MEIE = 1
     *
     * bit 7  = 1
     * bit 11 = 1
     *
     * MIE = 0x00000880
     * ========================================================
     */

    mie_write(0x00000880);
    delay();

    value = mie_read();

    /*
     * ========================================================
     * BIN 2 : 111
     *
     * MSIE = 1
     * MTIE = 1
     * MEIE = 1
     *
     * bit 3  = 1
     * bit 7  = 1
     * bit 11 = 1
     *
     * MIE = 0x00000888
     * ========================================================
     */

    mie_write(0x00000888);
    delay();

    value = mie_read();

    /*
     * Clear MIE after coverage.
     */
    mie_write(0x00000000);
    delay();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}
