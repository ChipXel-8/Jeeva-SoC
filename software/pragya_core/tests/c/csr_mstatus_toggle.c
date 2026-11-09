#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * MSTATUS TOGGLE TEST
 *
 * CSR:
 *      mstatus = 0x300
 *
 * Purpose:
 *      Toggle writable mstatus bits.
 *
 * Pattern:
 *      0xAAAAAAAA
 *      0x55555555
 *
 * Operation:
 *      CSRW
 *      CSRR
 *
 * RTL log can be compared directly with Spike.
 *
 * ============================================================
 */

static inline void write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw 0x300, %0"
        :
        : "r"(value)
        : "memory"
    );
}


static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x300"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t value;


    /*
     * ========================================================
     * WRITE PATTERN 1
     * ========================================================
     */

    write_mstatus(0xAAAAAAAA);

    value = read_mstatus();


    /*
     * ========================================================
     * WRITE PATTERN 2
     * ========================================================
     */

    write_mstatus(0x55555555);

    value = read_mstatus();


    /*
     * ========================================================
     * WRITE ALL ZERO
     * ========================================================
     */

    write_mstatus(0x00000000);

    value = read_mstatus();


    /*
     * ========================================================
     * WRITE ALL ONE
     * ========================================================
     */

    write_mstatus(0xFFFFFFFF);

    value = read_mstatus();


    (void)value;

    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}