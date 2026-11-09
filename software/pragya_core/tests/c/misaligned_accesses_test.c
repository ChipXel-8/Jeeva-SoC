#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA RV32I EXCEPTION TEST
 *
 * Exceptions tested:
 *
 *   Cause 0  : Instruction address misaligned
 *   Cause 2  : Illegal instruction
 *   Cause 3  : Breakpoint (EBREAK)
 *   Cause 11 : Environment call from M-mode (ECALL)
 *
 * NOT TESTED:
 *
 *   Cause 4 : Load address misaligned
 *   Cause 6 : Store/AMO address misaligned
 *
 * These are intentionally not tested because misaligned
 * load/store support is being removed.
 * ============================================================
 */


/* ============================================================
 * CSR READ FUNCTIONS
 * ============================================================ */

static inline uint32_t read_mcause(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mcause"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t read_mtval(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mtval"
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
        "csrr %0, mepc"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


/* ============================================================
 * EXCEPTION TEST 1
 *
 * ECALL
 *
 * Expected:
 *
 *   mcause = 0x0000000B
 *   mtval  = 0x00000000
 *
 * ============================================================ */

static int test_ecall(void)
{
    uint32_t cause;
    uint32_t tval;

    asm volatile (
        "ecall"
        :
        :
        : "memory"
    );

    cause = read_mcause();
    tval  = read_mtval();

    if (cause != 0x0000000B)
        return 0;

    if (tval != 0x00000000)
        return 0;

    return 1;
}


/* ============================================================
 * EXCEPTION TEST 2
 *
 * EBREAK
 *
 * Expected:
 *
 *   mcause = 0x00000003
 *   mtval  = address of EBREAK instruction
 *
 * We only check mcause here because the exact PC depends
 * on the linker/compiler placement.
 *
 * ============================================================ */

static int test_ebreak(void)
{
    uint32_t cause;

    asm volatile (
        "ebreak"
        :
        :
        : "memory"
    );

    cause = read_mcause();

    if (cause != 0x00000003)
        return 0;

    return 1;
}


/* ============================================================
 * EXCEPTION TEST 3
 *
 * ILLEGAL INSTRUCTION
 *
 * 0xFFFFFFFF is not a valid RV32I/RV32M instruction.
 *
 * Expected:
 *
 *   mcause = 0x00000002
 *   mtval  = 0xFFFFFFFF
 *
 * ============================================================ */

static int test_illegal_instruction(void)
{
    uint32_t cause;
    uint32_t tval;

    asm volatile (
        ".word 0xFFFFFFFF"
        :
        :
        : "memory"
    );

    cause = read_mcause();
    tval  = read_mtval();

    if (cause != 0x00000002)
        return 0;

    if (tval != 0xFFFFFFFF)
        return 0;

    return 1;
}


/* ============================================================
 * EXCEPTION TEST 4
 *
 * INSTRUCTION ADDRESS MISALIGNED
 *
 * We deliberately create a JALR target whose address is not
 * 4-byte aligned.
 *
 * Target = 0x00000102
 *
 * target[1:0] = 2'b10
 *
 * Your current PC unit detects:
 *
 *   branch_taken_in &&
 *   (pc_target[1:0] != 2'b00)
 *
 * Expected:
 *
 *   mcause = 0x00000000
 *   mtval  = misaligned target address
 *
 * ============================================================ */

static int test_instruction_misaligned(void)
{
    uint32_t cause;
    uint32_t tval;

    /*
     * x5 = 0x00000102
     *
     * jalr x0, 0(x5)
     *
     * The target address is 0x102, which is not
     * 4-byte aligned.
     */

    asm volatile (
        "li x5, 0x102\n"
        "jalr x0, 0(x5)\n"
        :
        :
        : "memory"
    );

    cause = read_mcause();
    tval  = read_mtval();

    if (cause != 0x00000000)
        return 0;

    /*
     * Your machine_control uses:
     *
     * trap_value_reg <= mem_addr_in;
     *
     * for misaligned instruction.
     *
     * mem_addr_in is i_adder_out.
     */
    if (tval != 0x00000102)
        return 0;

    return 1;
}


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t result = 0;

    /*
     * --------------------------------------------------------
     * TEST 1 : ECALL
     * --------------------------------------------------------
     */

    result = test_ecall();

    if (result == 0)
        test_fail();


    /*
     * --------------------------------------------------------
     * TEST 2 : EBREAK
     * --------------------------------------------------------
     */

    result = test_ebreak();

    if (result == 0)
        test_fail();


    /*
     * --------------------------------------------------------
     * TEST 3 : ILLEGAL INSTRUCTION
     * --------------------------------------------------------
     */

    result = test_illegal_instruction();

    if (result == 0)
        test_fail();


    /*
     * --------------------------------------------------------
     * TEST 4 : INSTRUCTION ADDRESS MISALIGNED
     * --------------------------------------------------------
     */

    result = test_instruction_misaligned();

    if (result == 0)
        test_fail();


    /*
     * --------------------------------------------------------
     * ALL EXCEPTION TESTS PASSED
     * --------------------------------------------------------
     */

    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}
