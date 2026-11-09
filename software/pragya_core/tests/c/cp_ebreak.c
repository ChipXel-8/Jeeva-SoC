#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA EXCEPTION COVERAGE TEST
 *
 * Target:
 *
 *   Cause 0  : Instruction-address-misaligned
 *   Cause 3  : Breakpoint
 *   Cause 11 : ECALL from M-mode
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
 * CSR ACCESS
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
 * On exception:
 *
 *       MEPC   = address of faulting instruction
 *       MCAUSE = exception cause
 *
 * We advance MEPC by 4 and execute MRET.
 *
 * This allows the program to continue after:
 *
 *       EBREAK
 *       ECALL
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
         * Skip the faulting 32-bit instruction
         */
        "addi t0, t0, 4\n"

        /*
         * Write updated MEPC
         */
        "csrw 0x341, t0\n"

        /*
         * Return from machine trap
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
     * Direct mode:
     *
     * MTVEC[1:0] = 00
     */

    handler_address &= ~0x3U;

    csr_write_mtvec(handler_address);

    /*
     * Disable interrupts.
     *
     * We are testing exceptions only.
     */

    csr_write_mstatus(0x00000000);

    delay();
}


/* ============================================================
 * TEST 1
 *
 * BREAKPOINT
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
 * Coverage:
 *
 *       cp_exception_cause.breakpoint
 *
 * ============================================================
 */

static void test_breakpoint(void)
{
    /*
     * Make sure interrupts are disabled.
     */

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
     * Trap handler should return here.
     */

    delay();
}


/* ============================================================
 * TEST 2
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
 *       x0 + 2 = address 0x00000002
 *
 * Since instruction addresses must be 4-byte aligned,
 * this should generate:
 *
 *       MCAUSE = 0
 *
 * Coverage:
 *
 *       cp_exception_cause.instruction_misaligned
 *
 * ============================================================
 */

static void test_instruction_misaligned(void)
{
    /*
     * Make sure interrupts are disabled.
     */

    csr_write_mstatus(0x00000000);

    delay();


    /*
     * EXACT MACHINE INSTRUCTION:
     *
     *       JALR x0, 2(x0)
     *
     * Target = 0x00000002
     *
     * 0x00000002 is not 4-byte aligned.
     */

    asm volatile (
        ".word 0x00200067"
        :
        :
        : "memory"
    );


    /*
     * Trap handler should return here.
     */

    delay();
}


/* ============================================================
 * TEST 3
 *
 * ECALL FROM MACHINE MODE
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
 * Coverage:
 *
 *       cp_exception_cause.ecall_machine
 *
 * ============================================================
 */

static void test_ecall(void)
{
    /*
     * Make sure interrupts are disabled.
     */

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
     * Trap handler should return here.
     */

    delay();
}


/* ============================================================
 * OPTIONAL CHECK
 *
 * These values are only read after the tests.
 *
 * ============================================================
 */

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
     * Install our trap handler.
     * ========================================================
     */

    install_trap_handler();


    /*
     * ========================================================
     * STEP 2
     *
     * BREAKPOINT EXCEPTION
     *
     * Expected:
     *
     *       MCAUSE = 3
     * ========================================================
     */

    test_breakpoint();


    /*
     * ========================================================
     * STEP 3
     *
     * INSTRUCTION-ADDRESS-MISALIGNED EXCEPTION
     *
     * Expected:
     *
     *       MCAUSE = 0
     * ========================================================
     */

    test_instruction_misaligned();


    /*
     * ========================================================
     * STEP 4
     *
     * ECALL FROM M-MODE
     *
     * Expected:
     *
     *       MCAUSE = 11
     * ========================================================
     */

    test_ecall();


    /*
     * ========================================================
     * STEP 5
     *
     * Read final exception information.
     * ========================================================
     */

    value = read_exception_csrs();


    /*
     * Prevent compiler optimization.
     */

    (void)value;


    /*
     * ========================================================
     * PASS
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