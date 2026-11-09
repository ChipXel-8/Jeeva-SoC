#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 *             PRAGYA MTVEC TOGGLE TEST
 * ============================================================
 *
 * CSR:
 *      MTVEC = 0x305
 *
 * Supported machine-mode modes:
 *
 *      00 = Direct
 *      01 = Vectored
 *
 * This test is designed for:
 *
 *      RTL execution
 *          +
 *      Spike execution
 *          +
 *      architectural commit comparison
 *
 * IMPORTANT:
 *
 * Never write MTVEC values ending in:
 *
 *      2
 *      3
 *
 * because these select reserved modes on standard RISC-V.
 *
 * Therefore all values below end in:
 *
 *      0  -> Direct
 *      1  -> Vectored
 *
 * ============================================================
 */


/* ============================================================
 * WRITE MTVEC
 * ============================================================ */

static inline void write_mtvec(uint32_t value)
{
    asm volatile (
        "csrw 0x305, %0"
        :
        : "r"(value)
        : "memory"
    );
}


/* ============================================================
 * READ MTVEC
 * ============================================================ */

static inline uint32_t read_mtvec(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x305"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * CSRRS READ
 *
 * rs1 = x0
 *
 * Therefore this performs a read without modifying MTVEC.
 * ============================================================ */

static inline uint32_t mtvec_csrrs(void)
{
    uint32_t value;

    asm volatile (
        "csrrs %0, 0x305, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * CSRRC READ
 *
 * rs1 = x0
 * ============================================================ */

static inline uint32_t mtvec_csrrc(void)
{
    uint32_t value;

    asm volatile (
        "csrrc %0, 0x305, x0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * CSRRSI READ
 *
 * uimm = 0
 * ============================================================ */

static inline uint32_t mtvec_csrrsi(void)
{
    uint32_t value;

    asm volatile (
        "csrrsi %0, 0x305, 0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * CSRRCI READ
 *
 * uimm = 0
 * ============================================================ */

static inline uint32_t mtvec_csrrci(void)
{
    uint32_t value;

    asm volatile (
        "csrrci %0, 0x305, 0"
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


    /* ========================================================
     * INITIAL DIRECT MODE
     * ======================================================== */

    write_mtvec(0x00000000);
    value = read_mtvec();


    /* ========================================================
     * INITIAL VECTORED MODE
     * ======================================================== */

    write_mtvec(0x00000001);
    value = read_mtvec();


    /* ========================================================
     * LOW BASE BIT TOGGLING
     *
     * Base is MTVEC[31:2]
     *
     * ======================================================== */

    write_mtvec(0x00000004);
    value = read_mtvec();

    write_mtvec(0x00000005);
    value = read_mtvec();

    write_mtvec(0x00000008);
    value = read_mtvec();

    write_mtvec(0x00000009);
    value = read_mtvec();

    write_mtvec(0x00000010);
    value = read_mtvec();

    write_mtvec(0x00000011);
    value = read_mtvec();

    write_mtvec(0x00000020);
    value = read_mtvec();

    write_mtvec(0x00000021);
    value = read_mtvec();


    /* ========================================================
     * LOW BASE PATTERN
     * ======================================================== */

    write_mtvec(0x00000054);
    value = read_mtvec();

    write_mtvec(0x00000055);
    value = read_mtvec();

    write_mtvec(0x000000A8);
    value = read_mtvec();

    write_mtvec(0x000000A9);
    value = read_mtvec();

    write_mtvec(0x00000154);
    value = read_mtvec();

    write_mtvec(0x00000155);
    value = read_mtvec();


    /* ========================================================
     * 0xAAAAAAAA PATTERN
     *
     * IMPORTANT:
     *
     * 0xAAAAAAAA has MTVEC[1:0] = 10 -> RESERVED.
     *
     * Therefore use:
     *
     *      AAAAAAA8 -> mode 00
     *      AAAAAAA9 -> mode 01
     *
     * ======================================================== */

    write_mtvec(0xAAAAAAA8);
    value = read_mtvec();

    write_mtvec(0xAAAAAAA9);
    value = read_mtvec();


    /* ========================================================
     * 0x55555555 PATTERN
     * ======================================================== */

    write_mtvec(0x55555554);
    value = read_mtvec();

    write_mtvec(0x55555555);
    value = read_mtvec();


    /* ========================================================
     * 0xCCCCCCCC PATTERN
     * ======================================================== */

    write_mtvec(0xCCCCCCC8);
    value = read_mtvec();

    write_mtvec(0xCCCCCCC9);
    value = read_mtvec();


    /* ========================================================
     * 0x33333333 PATTERN
     * ======================================================== */

    write_mtvec(0x33333330);
    value = read_mtvec();

    write_mtvec(0x33333331);
    value = read_mtvec();


    /* ========================================================
     * HIGH BASE BIT TOGGLING
     * ======================================================== */

    write_mtvec(0x10000000);
    value = read_mtvec();

    write_mtvec(0x10000001);
    value = read_mtvec();

    write_mtvec(0x20000000);
    value = read_mtvec();

    write_mtvec(0x20000001);
    value = read_mtvec();

    write_mtvec(0x40000000);
    value = read_mtvec();

    write_mtvec(0x40000001);
    value = read_mtvec();

    write_mtvec(0x80000000);
    value = read_mtvec();

    write_mtvec(0x80000001);
    value = read_mtvec();


    /* ========================================================
     * MIXED BASE PATTERNS
     * ======================================================== */

    write_mtvec(0x10000010);
    value = read_mtvec();

    write_mtvec(0x10000011);
    value = read_mtvec();

    write_mtvec(0x20000020);
    value = read_mtvec();

    write_mtvec(0x20000021);
    value = read_mtvec();

    write_mtvec(0x40000040);
    value = read_mtvec();

    write_mtvec(0x40000041);
    value = read_mtvec();

    write_mtvec(0x80000080);
    value = read_mtvec();

    write_mtvec(0x80000081);
    value = read_mtvec();


    /* ========================================================
     * ALTERNATING BASE PATTERNS
     * ======================================================== */

    write_mtvec(0xAAAAAAAA);
    /*
     * DO NOT DO THIS.
     *
     * This would select reserved mode 10.
     *
     * Instead use:
     */

    write_mtvec(0xAAAAAAA8);
    value = read_mtvec();

    write_mtvec(0x55555554);
    value = read_mtvec();

    write_mtvec(0xAAAAAAA9);
    value = read_mtvec();

    write_mtvec(0x55555555);
    value = read_mtvec();


    /* ========================================================
     * CSRRS
     * ======================================================== */

    write_mtvec(0xAAAAAAA8);

    value = mtvec_csrrs();


    /* ========================================================
     * CSRRC
     * ======================================================== */

    value = mtvec_csrrc();


    /* ========================================================
     * CSRRSI
     * ======================================================== */

    value = mtvec_csrrsi();


    /* ========================================================
     * CSRRCI
     * ======================================================== */

    value = mtvec_csrrci();


    /* ========================================================
     * MODE TOGGLE
     * ======================================================== */

    write_mtvec(0x80000000);
    value = read_mtvec();

    write_mtvec(0x80000001);
    value = read_mtvec();

    write_mtvec(0x40000000);
    value = read_mtvec();

    write_mtvec(0x40000001);
    value = read_mtvec();

    write_mtvec(0x00000000);
    value = read_mtvec();

    write_mtvec(0x00000001);
    value = read_mtvec();


    /* ========================================================
     * FINAL LEGAL VALUE
     * ======================================================== */

    write_mtvec(0x55555555);
    value = read_mtvec();


    /* ========================================================
     * PREVENT OPTIMIZATION
     * ======================================================== */

    (void)value;


    /* ========================================================
     * PASS
     * ======================================================== */

    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}