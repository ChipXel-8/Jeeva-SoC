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
        /*
         * MEPC contains address of EBREAK.
         */
        "csrr t0, 0x341\n"

        /*
         * Skip EBREAK.
         */
        "addi t0, t0, 4\n"

        /*
         * Update MEPC.
         */
        "csrw 0x341, t0\n"

        /*
         * This causes:
         *
         * STATE_OPERATING
         *       |
         *       v
         * STATE_TRAP_TAKEN
         *       |
         *       v
         * STATE_TRAP_RETURN
         */
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
     * Generate breakpoint exception.
     */
    asm volatile (
        ".word 0x00100073"
        :
        :
        : "memory"
    );

    /*
     * The trap handler executes MRET.
     *
     * FSM reaches:
     *
     * STATE_TRAP_RETURN
     *
     * Testbench will assert reset at that point.
     */

    delay();

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}