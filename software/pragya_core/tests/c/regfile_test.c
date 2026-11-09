#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * REGFILE CONDITION COVERAGE TEST
     *
     * Coverage target:
     *
     *     reg_write_in && (rd_addrs_in != 5'b00000)
     *
     * Required combinations:
     *
     *     reg_write_in = 0
     *     rd_addrs_in  = 0
     *
     *     reg_write_in = 0
     *     rd_addrs_in  = non-zero
     *
     *     reg_write_in = 1
     *     rd_addrs_in  = 0       <-- IMPORTANT UNCOVERED CASE
     *
     *     reg_write_in = 1
     *     rd_addrs_in  = non-zero
     *
     * ============================================================
     */


    /*
     * ------------------------------------------------------------
     * 1. REG_WRITE = 1, RD != X0
     *
     * ADDI x5, x0, 0x55
     *
     * rd = x5
     * reg_write = 1
     * (rd != 0) = 1
     *
     * This exercises the TRUE path:
     *
     *     reg_write_in && (rd_addrs_in != 0)
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x05500293\n"     // addi x5, x0, 0x55
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * 2. REG_WRITE = 1, RD = X0
     *
     * ADDI x0, x0, 1
     *
     * rd = x0
     * reg_write = 1
     * (rd != 0) = 0
     *
     * THIS IS THE IMPORTANT UNCOVERED CONDITION.
     *
     * The decoder sees this as a valid OP-IMM instruction and
     * therefore reg_write_out = 1, but rd_addrs_out = 0.
     *
     * Hence:
     *
     *     reg_write_in = 1
     *     (rd_addrs_in != 0) = 0
     *
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x00100013\n"     // addi x0, x0, 1
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * 3. Another normal register write
     *
     * ADDI x6, x0, 0x66
     *
     * rd = x6
     * reg_write = 1
     * (rd != 0) = 1
     *
     * ------------------------------------------------------------
     */

    asm volatile(
        ".word 0x06600313\n"     // addi x6, x0, 0x66
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * 4. Read X0
     *
     * Exercises:
     *
     *     if (rs_1_addrs_in == 5'd0)
     *
     * ------------------------------------------------------------
     */

    asm volatile(
        "add x7, x0, x0\n"
        :
        :
        : "memory"
    );


    /*
     * ------------------------------------------------------------
     * 5. Read X0 as rs2
     *
     * Exercises:
     *
     *     if (rs_2_addrs_in == 5'd0)
     *
     * ------------------------------------------------------------
     */

    asm volatile(
        "add x8, x5, x0\n"
        :
        :
        : "memory"
    );


    value = 0x12345678;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}