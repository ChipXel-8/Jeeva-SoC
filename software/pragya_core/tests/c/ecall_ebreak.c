#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA ECALL / EBREAK / MRET COVERAGE TEST
 *
 * Covers:
 *
 *      ECALL from M-mode
 *      EBREAK
 *      MRET
 *
 * Expected:
 *
 *      ECALL  -> MCAUSE = 11
 *      EBREAK -> MCAUSE = 3
 *
 * MRET is executed by the trap handler.
 *
 * ============================================================
 */


/* ============================================================
 * CSR ACCESS
 * ============================================================ */

static inline uint32_t read_mcause(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x342"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t read_mepc(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x341"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


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
 * TRAP HANDLER
 *
 * ECALL / EBREAK
 *      ↓
 * trap handler
 *      ↓
 * advance MEPC by 4
 *      ↓
 * MRET
 *
 * ============================================================
 */

void pragya_trap_handler(void)
    __attribute__((naked, aligned(4)));

void pragya_trap_handler(void)
{
    asm volatile (
        "csrr t0, 0x341\n"
        "addi t0, t0, 4\n"
        "csrw 0x341, t0\n"
        "mret\n"
    );
}


/* ============================================================
 * INSTALL TRAP HANDLER
 * ============================================================ */

static void install_trap_handler(void)
{
    uint32_t handler_address;

    handler_address =
        (uint32_t)(uintptr_t)&pragya_trap_handler;

    handler_address &= ~0x3U;

    write_mtvec(handler_address);

    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * ECALL TEST
 * ============================================================ */

static void test_ecall(void)
{
    /*
     * ECALL from M-mode
     *
     * Encoding:
     *
     *     0x00000073
     *
     * Expected:
     *
     *     MCAUSE = 11
     */

    asm volatile (
        ".word 0x00000073"
        :
        :
        : "memory"
    );

    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * EBREAK TEST
 * ============================================================ */

static void test_ebreak(void)
{
    /*
     * EBREAK
     *
     * Encoding:
     *
     *     0x00100073
     *
     * Expected:
     *
     *     MCAUSE = 3
     */

    asm volatile (
        ".word 0x00100073"
        :
        :
        : "memory"
    );

    asm volatile (
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
    volatile uint32_t value;


    /*
     * ========================================================
     * INSTALL TRAP HANDLER
     * ========================================================
     */

    install_trap_handler();


    /*
     * ========================================================
     * ECALL
     * ========================================================
     */

    test_ecall();


    /*
     * ========================================================
     * EBREAK
     * ========================================================
     */

    test_ebreak();


    /*
     * ========================================================
     * READ CSR
     * ========================================================
     */

    value = read_mcause();
    value = read_mepc();

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