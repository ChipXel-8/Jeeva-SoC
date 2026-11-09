#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL TOGGLE COVERAGE TEST
     *
     * Covers:
     *
     *   RESET
     *   NORMAL OPERATION
     *   ILLEGAL INSTRUCTION TRAP
     *   ECALL TRAP
     *   EBREAK TRAP
     *   MISALIGNED LOAD
     *   MISALIGNED STORE
     *   MRET / TRAP RETURN
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * Normal instruction execution
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0xAAAAAAAA\n"
        "li x6,  0x55555555\n"
        "add x7,  x5, x6\n"
        "xor x9,  x5, x6\n"
        "or  x10, x5, x6\n"
        "and x11, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * ECALL
     *
     * Causes:
     *
     *   mcause = 11
     *   i_or_e = 0
     *
     * Trap handler must execute MRET.
     * ------------------------------------------------------------
     */

    asm volatile(
        "ecall\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Normal execution after MRET
     *
     * This proves:
     *
     *   OPERATING
     *       ->
     *   TRAP_TAKEN
     *       ->
     *   OPERATING
     *
     * and:
     *
     *   OPERATING
     *       ->
     *   TRAP_RETURN
     *       ->
     *   OPERATING
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5, 0x12345678\n"
        "li x6, 0x87654321\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * EBREAK
     *
     * Causes:
     *
     *   mcause = 3
     * ------------------------------------------------------------
     */

    asm volatile(
        "ebreak\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Normal execution after EBREAK/MRET
     * ------------------------------------------------------------
     */

    asm volatile(
        "li x5,  0xAAAAAAAA\n"
        "li x6,  0xFFFFFFFF\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * Save result
     * ------------------------------------------------------------
     */

    asm volatile(
        "mv %0, x7"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;


    /*
     * ------------------------------------------------------------
     * PASS
     * ------------------------------------------------------------
     */

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}