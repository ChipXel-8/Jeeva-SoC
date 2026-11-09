#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * MACHINE CONTROL - MRET / TRAP RETURN TEST
     *
     * Covers:
     *
     *   mret_detected
     *   STATE_TRAP_RETURN
     *   pc_src_out = PC_EPC
     *   mie_set_out
     *
     * ============================================================
     */

    /*
     * Normal execution
     */
    asm volatile(
        "li x5, 0x11111111\n"
        "li x6, 0x22222222\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    /*
     * ECALL causes:
     *
     *   OPERATING
     *       ->
     *   TRAP_TAKEN
     *
     * Trap handler executes MRET:
     *
     *   TRAP_RETURN
     *       ->
     *   OPERATING
     */
    asm volatile(
        "ecall\n"
        :
        :
        : "memory"
    );

    /*
     * Instructions after MRET
     */
    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "xor x7, x5, x6\n"
        :
        :
        : "memory"
    );

    asm volatile(
        "mv %0, x7"
        : "=r"(value)
        :
        : "memory"
    );

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}