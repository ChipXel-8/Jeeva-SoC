#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * CSR READ-ONLY CROSS OPERATION COVERAGE TEST
 *
 * Purpose:
 *   Cover missing cross_csr_operation bins for:
 *
 *       cycle
 *       instret
 *       cycleh
 *       instreth
 *       mvendorid
 *       marchid
 *       mimpid
 *       mhartid
 *
 * Operations:
 *
 *       CSRRS   = 010
 *       CSRRC   = 011
 *       CSRRSI  = 110
 *       CSRRCI  = 111
 *
 * For read-only CSRs:
 *
 *   CSRRS  with rs1=x0  -> READ
 *   CSRRC  with rs1=x0  -> READ
 *   CSRRSI with uimm=0  -> READ
 *   CSRRCI with uimm=0  -> READ
 *
 * CSRRW / CSRRWI are NOT used on read-only CSRs because
 * they attempt to write the CSR.
 *
 * ============================================================
 */


/* ============================================================
 * CYCLE - 0xC00
 * ============================================================ */

static inline uint32_t cycle_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xC00, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t cycle_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xC00, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t cycle_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xC00, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t cycle_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xC00, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * INSTRET - 0xC02
 * ============================================================ */

static inline uint32_t instret_csrrs(void)
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


static inline uint32_t instret_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xC02, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t instret_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xC02, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t instret_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xC02, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * CYCLEH - 0xC80
 * ============================================================ */

static inline uint32_t cycleh_csrrs(void)
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


static inline uint32_t cycleh_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xC80, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t cycleh_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xC80, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t cycleh_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xC80, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * INSTRETH - 0xC82
 * ============================================================ */

static inline uint32_t instreth_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xC82, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t instreth_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xC82, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t instreth_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xC82, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t instreth_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xC82, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * MVENDORID - 0xF11
 * ============================================================ */

static inline uint32_t mvendorid_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xF11, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mvendorid_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xF11, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mvendorid_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xF11, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mvendorid_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xF11, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * MARCHID - 0xF12
 * ============================================================ */

static inline uint32_t marchid_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xF12, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t marchid_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xF12, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t marchid_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xF12, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t marchid_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xF12, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * MIMPID - 0xF13
 * ============================================================ */

static inline uint32_t mimpid_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xF13, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mimpid_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xF13, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mimpid_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xF13, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mimpid_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xF13, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * MHARTID - 0xF14
 * ============================================================ */

static inline uint32_t mhartid_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0xF14, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mhartid_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0xF14, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mhartid_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0xF14, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t mhartid_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0xF14, 0"
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
    volatile uint32_t value = 0;


    /*
     * ========================================================
     * CYCLE
     * ========================================================
     */

    value = cycle_csrrs();
    value = cycle_csrrc();

    value = cycle_csrrsi();
    value = cycle_csrrci();


    /*
     * ========================================================
     * INSTRET
     * ========================================================
     */

    value = instret_csrrs();
    value = instret_csrrc();

    value = instret_csrrsi();
    value = instret_csrrci();


    /*
     * ========================================================
     * CYCLEH
     * ========================================================
     */

    value = cycleh_csrrs();
    value = cycleh_csrrc();

    value = cycleh_csrrsi();
    value = cycleh_csrrci();


    /*
     * ========================================================
     * INSTRETH
     * ========================================================
     */

    value = instreth_csrrs();
    value = instreth_csrrc();

    value = instreth_csrrsi();
    value = instreth_csrrci();


    /*
     * ========================================================
     * MVENDORID
     * ========================================================
     */

    value = mvendorid_csrrs();
    value = mvendorid_csrrc();

    value = mvendorid_csrrsi();
    value = mvendorid_csrrci();


    /*
     * ========================================================
     * MARCHID
     * ========================================================
     */

    value = marchid_csrrs();
    value = marchid_csrrc();

    value = marchid_csrrsi();
    value = marchid_csrrci();


    /*
     * ========================================================
     * MIMPID
     * ========================================================
     */

    value = mimpid_csrrs();
    value = mimpid_csrrc();

    value = mimpid_csrrsi();
    value = mimpid_csrrci();


    /*
     * ========================================================
     * MHARTID
     * ========================================================
     */

    value = mhartid_csrrs();
    value = mhartid_csrrc();

    value = mhartid_csrrsi();
    value = mhartid_csrrci();


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