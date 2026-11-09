#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * CSR ADDRESS COVERAGE TEST
 *
 * Cover:
 *   MTVAL     = 0x343
 *   MINSTRET  = 0xB02
 *   INSTRET   = 0xC02
 *   CYCLEH    = 0xC80
 *
 * Access type:
 *   CSRRS with rs1 = x0
 *
 * CSRRS rd, csr, x0 performs a CSR read without modifying
 * the CSR value.
 * ============================================================
 */


/* ============================================================
 * Read MTVAL - 0x343
 * ============================================================ */

static inline uint32_t csr_read_mtval(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0x343, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * Read MINSTRET - 0xB02
 * ============================================================ */

static inline uint32_t csr_read_minstret(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xB02, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * Read INSTRET - 0xC02
 * ============================================================ */

static inline uint32_t csr_read_instret(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xC02, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * Read CYCLEH - 0xC80
 * ============================================================ */

static inline uint32_t csr_read_cycleh(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xC80, x0"
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
     * MTVAL
     */
    mtval_value = csr_read_mtval();

    /*
     * MINSTRET
     */
    minstret_value = csr_read_minstret();

    /*
     * INSTRET
     */
    instret_value = csr_read_instret();

    /*
     * CYCLEH
     */
    cycleh_value = csr_read_cycleh();

    /*
     * Prevent optimization
     */
    (void)mtval_value;
    (void)minstret_value;
    (void)instret_value;
    (void)cycleh_value;

    /*
     * PASS
     */
    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}
