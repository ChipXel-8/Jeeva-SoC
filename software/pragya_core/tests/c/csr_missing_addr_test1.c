#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * CSR MISSING ADDRESS TEST
 *
 * Purpose:
 *   Cover the currently missing CSR address bins:
 *
 *       MTVAL     = 0x343
 *       MINSTRET  = 0xB02
 *       INSTRET   = 0xC02
 *       CYCLEH    = 0xC80
 *
 * All accesses are READ operations.
 *
 * IMPORTANT:
 *   This test is intended to run on BOTH:
 *
 *       1. Pragya RTL
 *       2. Spike
 *
 * Therefore no invalid CSR access is used.
 * ============================================================
 */


/* ============================================================
 * Read MTVAL - CSR 0x343
 * ============================================================ */

static inline uint32_t read_mtval(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x343"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * Read MINSTRET - CSR 0xB02
 * ============================================================ */

static inline uint32_t read_minstret(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0xB02"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * Read INSTRET - CSR 0xC02
 * ============================================================ */

static inline uint32_t read_instret(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0xC02"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * Read CYCLEH - CSR 0xC80
 * ============================================================ */

static inline uint32_t read_cycleh(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0xC80"
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
    volatile uint32_t mtval_value;
    volatile uint32_t minstret_value;
    volatile uint32_t instret_value;
    volatile uint32_t cycleh_value;

    /*
     * --------------------------------------------------------
     * CSR 0x343 : MTVAL
     * --------------------------------------------------------
     */
    mtval_value = read_mtval();

    /*
     * --------------------------------------------------------
     * CSR 0xB02 : MINSTRET
     * --------------------------------------------------------
     */
    minstret_value = read_minstret();

    /*
     * --------------------------------------------------------
     * CSR 0xC02 : INSTRET
     * --------------------------------------------------------
     */
    instret_value = read_instret();

    /*
     * --------------------------------------------------------
     * CSR 0xC80 : CYCLEH
     * --------------------------------------------------------
     */
    cycleh_value = read_cycleh();

    /*
     * Prevent compiler from optimizing the values away.
     *
     * The variables are volatile, so the CSR reads must remain.
     */
    (void)mtval_value;
    (void)minstret_value;
    (void)instret_value;
    (void)cycleh_value;

    /*
     * --------------------------------------------------------
     * PASS
     * --------------------------------------------------------
     */
    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}