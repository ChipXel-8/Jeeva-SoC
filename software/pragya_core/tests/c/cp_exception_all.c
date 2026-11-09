#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA EXCEPTION COVERAGE TEST
 *
 * This single test targets:
 *
 *   1. ECALL
 *      MCAUSE = 11
 *
 *   2. EBREAK
 *      MCAUSE = 3
 *
 *   3. Instruction-address-misaligned
 *      MCAUSE = 0
 *
 *   4. MRET
 *      Executed from trap handler
 *
 *   5. MTVAL = non-zero
 *      Expected from instruction-address-misaligned exception
 *
 * ============================================================
 */


/* ============================================================
 * CSR ADDRESSES
 * ============================================================ */

#define CSR_MSTATUS   0x300
#define CSR_MTVEC     0x305
#define CSR_MEPC      0x341
#define CSR_MCAUSE    0x342
#define CSR_MTVAL     0x343


/* ============================================================
 * CSR READ
 * ============================================================ */

static inline uint32_t csr_read_mcause(void)
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


static inline uint32_t csr_read_mepc(void)
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


static inline uint32_t csr_read_mtval(void)
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
 * CSR WRITE
 * ============================================================ */

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


/* ============================================================
 * SMALL DELAY
 * ============================================================ */

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


/* ============================================================
 * MACHINE MODE TRAP HANDLER
 *
 * For every exception:
 *
 *       MEPC   = faulting instruction address
 *       MCAUSE = exception cause
 *       MTVAL  = exception-specific value
 *
 * We advance MEPC by 4 so that the faulting instruction
 * is skipped.
 *
 * Then MRET returns to normal program execution.
 *
 * ============================================================
 */

void pragya_trap_handler(void)
    __attribute__((naked, aligned(4)));

void pragya_trap_handler(void)
{
    asm volatile (
        /*
         * Read MEPC
         */
        "csrr t0, 0x341\n"

        /*
         * Skip faulting 32-bit instruction
         */
        "addi t0, t0, 4\n"

        /*
         * Write updated MEPC
         */
        "csrw 0x341, t0\n"

        /*
         * Return from machine trap
         *
         * This instruction is important for:
         *
         *       cp_mret
         *
         */
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

    /*
     * Direct mode
     *
     * MTVEC[1:0] = 00
     */

    handler_address &= ~0x3U;

    csr_write_mtvec(handler_address);

    /*
     * Disable interrupts.
     *
     * We are testing exceptions.
     */

    csr_write_mstatus(0x00000000);

    delay();
}


/* ============================================================
 * TEST 1
 *
 * ECALL
 *
 * Instruction:
 *
 *       ECALL
 *
 * Encoding:
 *
 *       0x00000073
 *
 * Expected:
 *
 *       MCAUSE = 11
 *
 * This covers:
 *
 *       cp_ecall
 *
 * ============================================================
 */

static void test_ecall(void)
{
    csr_write_mstatus(0x00000000);

    delay();


    /*
     * EXACT ECALL INSTRUCTION
     */

    asm volatile (
        ".word 0x00000073"
        :
        :
        : "memory"
    );


    /*
     * Trap handler executes MRET
     * and returns here.
     */

    delay();
}


/* ============================================================
 * TEST 2
 *
 * EBREAK
 *
 * Instruction:
 *
 *       EBREAK
 *
 * Encoding:
 *
 *       0x00100073
 *
 * Expected:
 *
 *       MCAUSE = 3
 *
 * This covers:
 *
 *       cp_ebreak
 *
 * ============================================================
 */

static void test_ebreak(void)
{
    csr_write_mstatus(0x00000000);

    delay();


    /*
     * EXACT EBREAK INSTRUCTION
     */

    asm volatile (
        ".word 0x00100073"
        :
        :
        : "memory"
    );


    /*
     * Trap handler executes MRET.
     */

    delay();
}


/* ============================================================
 * TEST 3
 *
 * INSTRUCTION-ADDRESS-MISALIGNED
 *
 * Instruction:
 *
 *       JALR x0, 2(x0)
 *
 * Encoding:
 *
 *       0x00200067
 *
 * Calculation:
 *
 *       x0 + 2 = 0x00000002
 *
 * Since instruction address 0x2 is not 4-byte aligned,
 * this generates:
 *
 *       MCAUSE = 0
 *
 * MTVAL should contain:
 *
 *       0x00000002
 *
 * Therefore this test targets:
 *
 *       cp_exception_cause
 *       cp_mtval
 *
 * ============================================================
 */

static void test_instruction_misaligned(void)
{
    csr_write_mstatus(0x00000000);

    delay();


    /*
     * EXACT MACHINE INSTRUCTION:
     *
     *       JALR x0, 2(x0)
     *
     * Target address:
     *
     *       0 + 2 = 2
     *
     * Address 2 is not 4-byte aligned.
     */

    asm volatile (
        ".word 0x00200067"
        :
        :
        : "memory"
    );


    /*
     * Trap handler executes MRET
     * and skips this instruction.
     */

    delay();
}


/* ============================================================
 * READ EXCEPTION INFORMATION
 * ============================================================ */

static uint32_t read_exception_csrs(void)
{
    uint32_t value;

    value = csr_read_mcause();
    value = csr_read_mepc();
    value = csr_read_mtval();

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
     * STEP 1
     *
     * Install trap handler.
     * ========================================================
     */

    install_trap_handler();


    /*
     * ========================================================
     * STEP 2
     *
     * ECALL
     *
     * Expected:
     *
     *       MCAUSE = 11
     * ========================================================
     */

    test_ecall();


    /*
     * ========================================================
     * STEP 3
     *
     * EBREAK
     *
     * Expected:
     *
     *       MCAUSE = 3
     * ========================================================
     */

    test_ebreak();


    /*
     * ========================================================
     * STEP 4
     *
     * INSTRUCTION-ADDRESS-MISALIGNED
     *
     * Expected:
     *
     *       MCAUSE = 0
     *       MTVAL  = 0x00000002
     * ========================================================
     */

    test_instruction_misaligned();


    /*
     * ========================================================
     * STEP 5
     *
     * Read final exception CSRs.
     * ========================================================
     */

    value = read_exception_csrs();


    /*
     * Prevent compiler optimization.
     */

    (void)value;


    /*
     * ========================================================
     * TEST PASS
     * ========================================================
     */

    test_pass();


    /*
     * Never return.
     */

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}