#include "pragya_test.h"
#include <stdint.h>

static inline void csr_write_mtvec(uint32_t value)
{
    asm volatile (
        "csrw 0x305, %0"
        :
        : "r"(value)
        : "memory"
    );
}

static inline void csr_write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw 0x300, %0"
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
        :
        :
        : "memory"
    );
}


/*
 * Trap handler
 */
void trap_handler(void)
    __attribute__((naked, aligned(4)));

void trap_handler(void)
{
    asm volatile (
        "csrr t0, 0x341\n"
        "addi t0, t0, 4\n"
        "csrw 0x341, t0\n"
        "mret\n"
    );
}


int main(void)
{
    uint32_t handler;

    handler = (uint32_t)(uintptr_t)&trap_handler;
    handler &= ~0x3U;

    csr_write_mtvec(handler);

    /*
     * Disable interrupts.
     */
    csr_write_mstatus(0);

    delay();

    /*
     * Generate EBREAK.
     *
     * This causes:
     *
     * STATE_OPERATING
     *       |
     *       v
     * STATE_TRAP_TAKEN
     */
    asm volatile (
        ".word 0x00100073"
        :
        :
        : "memory"
    );

    /*
     * Normally trap handler would execute here.
     *
     * But the testbench will reset the DUT
     * while STATE_TRAP_TAKEN is active.
     */

    delay();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}