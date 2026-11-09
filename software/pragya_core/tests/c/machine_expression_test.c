#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * MACHINE CONTROL EXPRESSION COVERAGE TEST
 *
 * Covers:
 *
 * Line 102:
 *   is_system
 *   FUNCT7_zero
 *   rs2_addr_zero
 *   rs1_addr_zero
 *   FUNCT3_zero
 *   rd_zero
 *
 * Line 103:
 *   is_system
 *   FUNCT7_zero
 *   rs2_addr_ebreak
 *   rs1_addr_zero
 *   FUNCT3_zero
 *   rd_zero
 *
 * The raw SYSTEM instructions below are intentionally malformed
 * SYSTEM instructions. They are expected to generate illegal
 * instruction exceptions.
 * ============================================================
 */

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


/*
 * Trap handler
 *
 * Skip the illegal instruction and return.
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


static inline void execute_test_instruction(uint32_t instr)
{
    asm volatile (
        ".word 0x00000013\n"
        ".word 0x00000013\n"
        :
        :
        : "memory"
    );

    /*
     * The instruction itself is inserted below
     * by the individual test cases.
     */

    (void)instr;
}


int main(void)
{
    uint32_t handler;

    handler = (uint32_t)(uintptr_t)&trap_handler;
    handler &= ~0x3U;

    csr_write_mtvec(handler);

    /*
     * Disable global interrupts.
     */
    csr_write_mstatus(0);


    /*
     * ========================================================
     * LINE 102
     *
     * Base condition:
     *
     * is_system      = 1
     * rs2_addr_zero  = 1
     *
     * We deliberately make the other terms ZERO.
     * ========================================================
     */


    /*
     * 1. FUNCT7_zero = 0
     *
     * funct7 = 0000001
     * rs2    = 00000
     * rs1    = 00000
     * funct3 = 000
     * rd     = 00000
     *
     * Encoding = 0x02000073
     */
    asm volatile (
        ".word 0x02000073"
        :
        :
        : "memory"
    );


    /*
     * 2. rs1_addr_zero = 0
     *
     * funct7 = 0000000
     * rs2    = 00000
     * rs1    = 00001
     * funct3 = 000
     * rd     = 00000
     *
     * Encoding = 0x00008073
     */
    asm volatile (
        ".word 0x00008073"
        :
        :
        : "memory"
    );


    /*
     * 3. FUNCT3_zero = 0
     *
     * funct7 = 0000000
     * rs2    = 00000
     * rs1    = 00000
     * funct3 = 001
     * rd     = 00000
     *
     * Encoding = 0x00001073
     */
    asm volatile (
        ".word 0x00001073"
        :
        :
        : "memory"
    );


    /*
     * 4. rd_zero = 0
     *
     * funct7 = 0000000
     * rs2    = 00000
     * rs1    = 00000
     * funct3 = 000
     * rd     = 00001
     *
     * Encoding = 0x000000F3
     */
    asm volatile (
        ".word 0x000000F3"
        :
        :
        : "memory"
    );


    /*
     * ========================================================
     * LINE 103
     *
     * Base condition:
     *
     * is_system       = 1
     * rs2_addr_ebreak = 1
     *
     * EBREAK has:
     *
     * funct7 = 0
     * rs2    = 1
     * rs1    = 0
     * funct3 = 0
     * rd     = 0
     *
     * ========================================================
     */


    /*
     * 5. FUNCT7_zero = 0
     *
     * funct7 = 0000001
     * rs2    = 00001
     * rs1    = 00000
     * funct3 = 000
     * rd     = 00000
     *
     * Encoding = 0x02100073
     */
    asm volatile (
        ".word 0x02100073"
        :
        :
        : "memory"
    );


    /*
     * 6. rs1_addr_zero = 0
     *
     * funct7 = 0000000
     * rs2    = 00001
     * rs1    = 00001
     * funct3 = 000
     * rd     = 00000
     *
     * Encoding = 0x00108073
     */
    asm volatile (
        ".word 0x00108073"
        :
        :
        : "memory"
    );


    /*
     * 7. FUNCT3_zero = 0
     *
     * funct7 = 0000000
     * rs2    = 00001
     * rs1    = 00000
     * funct3 = 001
     * rd     = 00000
     *
     * Encoding = 0x00101073
     */
    asm volatile (
        ".word 0x00101073"
        :
        :
        : "memory"
    );


    /*
     * 8. rd_zero = 0
     *
     * funct7 = 0000000
     * rs2    = 00001
     * rs1    = 00000
     * funct3 = 000
     * rd     = 00001
     *
     * Encoding = 0x001000F3
     */
    asm volatile (
        ".word 0x001000F3"
        :
        :
        : "memory"
    );


    /*
     * Give trap handler time to return.
     */
    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );


    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}