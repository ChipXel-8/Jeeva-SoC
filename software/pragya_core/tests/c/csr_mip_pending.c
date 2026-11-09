#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * MIP PENDING CROSS COVERAGE TEST
 *
 * Covers all 8 combinations:
 *
 * MSIP MTIP MEIP
 *  0    0    0
 *  0    0    1
 *  0    1    0
 *  0    1    1
 *  1    0    0
 *  1    0    1
 *  1    1    0
 *  1    1    1
 *
 * ============================================================
 */

static inline void set_mip(uint32_t value)
{
    asm volatile (
        "csrrw x0, 0x344, %0"
        :
        : "r"(value)
        : "memory"
    );
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
    volatile uint32_t value = 0;

    /*
     * 000
     * MSIP=0 MTIP=0 MEIP=0
     */
    set_mip(0x00000000);
    delay();

    /*
     * 001
     * MSIP=0 MTIP=0 MEIP=1
     */
    set_mip(0x00000800);
    delay();

    /*
     * 010
     * MSIP=0 MTIP=1 MEIP=0
     */
    set_mip(0x00000080);
    delay();

    /*
     * 011
     * MSIP=0 MTIP=1 MEIP=1
     */
    set_mip(0x00000880);
    delay();

    /*
     * 100
     * MSIP=1 MTIP=0 MEIP=0
     */
    set_mip(0x00000008);
    delay();

    /*
     * 101
     * MSIP=1 MTIP=0 MEIP=1
     */
    set_mip(0x00000808);
    delay();

    /*
     * 110
     * MSIP=1 MTIP=1 MEIP=0
     */
    set_mip(0x00000088);
    delay();

    /*
     * 111
     * MSIP=1 MTIP=1 MEIP=1
     */
    set_mip(0x00000888);
    delay();

    /*
     * Clear
     */
    set_mip(0x00000000);
    delay();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}
