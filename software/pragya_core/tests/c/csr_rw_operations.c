#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * CSR CROSS OPERATION COVERAGE TEST
 *
 * Purpose:
 *   Cover legal CSR address x CSR operation combinations.
 *
 * Operations:
 *
 *   001 = CSRRW
 *   010 = CSRRS
 *   011 = CSRRC
 *   101 = CSRRWI
 *   110 = CSRRSI
 *   111 = CSRRCI
 *
 * IMPORTANT:
 *
 *   Read-only CSRs:
 *       cycle
 *       instret
 *       cycleh
 *       instreth
 *       mvendorid
 *       marchid
 *       mimpid
 *       mhartid
 *
 *   These are tested using READ operations only.
 *
 *   Writable CSRs are tested with all six CSR operations.
 *
 * ============================================================
 */


/* ============================================================
 * READ-ONLY CSR READ
 * ============================================================ */

#define DEFINE_CSR_READ(NAME, CSR_ADDR)                         \
static inline uint32_t NAME##_read(void)                        \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrr %0, " CSR_ADDR                                    \
        : "=r"(result)                                           \
        :                                                        \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}


/* ============================================================
 * ALL SIX CSR OPERATIONS
 *
 * Used only for writable CSRs.
 * ============================================================ */

#define DEFINE_CSR_TESTS(NAME, CSR_ADDR)                        \
                                                                \
static inline uint32_t NAME##_csrrw(uint32_t value)             \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrrw %0, " CSR_ADDR ", %1"                            \
        : "=r"(result)                                           \
        : "r"(value)                                             \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}                                                               \
                                                                \
static inline uint32_t NAME##_csrrs(uint32_t value)             \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrrs %0, " CSR_ADDR ", %1"                            \
        : "=r"(result)                                           \
        : "r"(value)                                             \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}                                                               \
                                                                \
static inline uint32_t NAME##_csrrc(uint32_t value)             \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrrc %0, " CSR_ADDR ", %1"                            \
        : "=r"(result)                                           \
        : "r"(value)                                             \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}                                                               \
                                                                \
static inline uint32_t NAME##_csrrwi(void)                      \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrrwi %0, " CSR_ADDR ", 0"                            \
        : "=r"(result)                                           \
        :                                                        \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}                                                               \
                                                                \
static inline uint32_t NAME##_csrrsi(void)                      \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrrsi %0, " CSR_ADDR ", 0"                            \
        : "=r"(result)                                           \
        :                                                        \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}                                                               \
                                                                \
static inline uint32_t NAME##_csrrci(void)                      \
{                                                               \
    uint32_t result;                                            \
    asm volatile (                                               \
        "csrrci %0, " CSR_ADDR ", 0"                            \
        : "=r"(result)                                           \
        :                                                        \
        : "memory"                                               \
    );                                                          \
    return result;                                               \
}


/* ============================================================
 * READ-ONLY CSR DEFINITIONS
 * ============================================================ */

DEFINE_CSR_READ(cycle,      "0xC00")
DEFINE_CSR_READ(instret,    "0xC02")
DEFINE_CSR_READ(cycleh,     "0xC80")
DEFINE_CSR_READ(instreth,   "0xC82")

DEFINE_CSR_READ(mvendorid,  "0xF11")
DEFINE_CSR_READ(marchid,    "0xF12")
DEFINE_CSR_READ(mimpid,     "0xF13")
DEFINE_CSR_READ(mhartid,    "0xF14")


/* ============================================================
 * WRITABLE CSR DEFINITIONS
 * ============================================================ */

/* Machine trap setup */
DEFINE_CSR_TESTS(mstatus,    "0x300")
DEFINE_CSR_TESTS(mie,        "0x304")
DEFINE_CSR_TESTS(misa,       "0x301")
DEFINE_CSR_TESTS(mtvec,      "0x305")

/* Machine trap handling */
DEFINE_CSR_TESTS(mscratch,   "0x340")
DEFINE_CSR_TESTS(mepc,       "0x341")
DEFINE_CSR_TESTS(mcause,     "0x342")
DEFINE_CSR_TESTS(mtval,      "0x343")
DEFINE_CSR_TESTS(mip,        "0x344")

/* Machine counters */
DEFINE_CSR_TESTS(mcycle,     "0xB00")
DEFINE_CSR_TESTS(minstret,   "0xB02")
DEFINE_CSR_TESTS(mcycleh,    "0xB80")
DEFINE_CSR_TESTS(minstreth,  "0xB82")


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t value = 0;


    /*
     * ========================================================
     * READ-ONLY CSRs
     *
     * These are READ only.
     *
     * Do NOT use CSRRW/CSRRS/CSRRC with rs1 != x0.
     * ========================================================
     */

    value = cycle_read();
    value = instret_read();
    value = cycleh_read();
    value = instreth_read();

    value = mvendorid_read();
    value = marchid_read();
    value = mimpid_read();
    value = mhartid_read();


    /*
     * ========================================================
     * MSTATUS - 0x300
     * ========================================================
     */

    value = mstatus_csrrw(0x00000000);
    value = mstatus_csrrs(0x00000000);
    value = mstatus_csrrc(0x00000000);

    value = mstatus_csrrwi();
    value = mstatus_csrrsi();
    value = mstatus_csrrci();


    /*
     * ========================================================
     * MIE - 0x304
     * ========================================================
     */

    value = mie_csrrw(0x00000000);
    value = mie_csrrs(0x00000000);
    value = mie_csrrc(0x00000000);

    value = mie_csrrwi();
    value = mie_csrrsi();
    value = mie_csrrci();


    /*
     * ========================================================
     * MISA - 0x301
     * ========================================================
     */

    value = misa_csrrw(0x40000000);
    value = misa_csrrs(0x00000000);
    value = misa_csrrc(0x00000000);

    value = misa_csrrwi();
    value = misa_csrrsi();
    value = misa_csrrci();


    /*
     * ========================================================
     * MTVEC - 0x305
     *
     * Save original value first.
     * ========================================================
     */

    value = mtvec_csrrs(0);
    value = mtvec_csrrw(0x80000000);

    value = mtvec_csrrs(0);
    value = mtvec_csrrc(0);

    value = mtvec_csrrwi();
    value = mtvec_csrrsi();
    value = mtvec_csrrci();

    /*
     * Restore a valid trap vector.
     */
    value = mtvec_csrrw(0x80000000);


    /*
     * ========================================================
     * MSCRATCH - 0x340
     * ========================================================
     */

    value = mscratch_csrrw(0x12345678);
    value = mscratch_csrrs(0);
    value = mscratch_csrrc(0);

    value = mscratch_csrrwi();
    value = mscratch_csrrsi();
    value = mscratch_csrrci();


    /*
     * ========================================================
     * MEPC - 0x341
     * ========================================================
     */

    value = mepc_csrrw(0x80000100);
    value = mepc_csrrs(0);
    value = mepc_csrrc(0);

    value = mepc_csrrwi();
    value = mepc_csrrsi();
    value = mepc_csrrci();


    /*
     * ========================================================
     * MCAUSE - 0x342
     * ========================================================
     */

    value = mcause_csrrw(0);
    value = mcause_csrrs(0);
    value = mcause_csrrc(0);

    value = mcause_csrrwi();
    value = mcause_csrrsi();
    value = mcause_csrrci();


    /*
     * ========================================================
     * MTVAL - 0x343
     * ========================================================
     */

    value = mtval_csrrw(0x12345678);
    value = mtval_csrrs(0);
    value = mtval_csrrc(0);

    value = mtval_csrrwi();
    value = mtval_csrrsi();
    value = mtval_csrrci();


    /*
     * ========================================================
     * MIP - 0x344
     * ========================================================
     */

    value = mip_csrrw(0);
    value = mip_csrrs(0);
    value = mip_csrrc(0);

    value = mip_csrrwi();
    value = mip_csrrsi();
    value = mip_csrrci();


    /*
     * ========================================================
     * MCYCLE - 0xB00
     * ========================================================
     */

    value = mcycle_csrrw(0);
    value = mcycle_csrrs(0);
    value = mcycle_csrrc(0);

    value = mcycle_csrrwi();
    value = mcycle_csrrsi();
    value = mcycle_csrrci();


    /*
     * ========================================================
     * MINSTRET - 0xB02
     * ========================================================
     */

    value = minstret_csrrw(0);
    value = minstret_csrrs(0);
    value = minstret_csrrc(0);

    value = minstret_csrrwi();
    value = minstret_csrrsi();
    value = minstret_csrrci();


    /*
     * ========================================================
     * MCYCLEH - 0xB80
     * ========================================================
     */

    value = mcycleh_csrrw(0);
    value = mcycleh_csrrs(0);
    value = mcycleh_csrrc(0);

    value = mcycleh_csrrwi();
    value = mcycleh_csrrsi();
    value = mcycleh_csrrci();


    /*
     * ========================================================
     * MINSTRETH - 0xB82
     * ========================================================
     */

    value = minstreth_csrrw(0);
    value = minstreth_csrrs(0);
    value = minstreth_csrrc(0);

    value = minstreth_csrrwi();
    value = minstreth_csrrsi();
    value = minstreth_csrrci();


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