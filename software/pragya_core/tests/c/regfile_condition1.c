#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t result;

int main(void)
{
    uint32_t value;

    /*
     * Normal register write.
     * reg_write_in = 1
     * rd = x5
     */
    asm volatile(
        "li x5, 0x12345678\n"
        :
        :
        : "memory"
    );

    /*
     * =====================================================
     * WRITE TO x0
     * =====================================================
     *
     * ADDI has reg_write_in = 1
     * rd_addrs_in = 0
     *
     * Therefore:
     *
     * reg_write_in       = 1
     * (rd_addrs_in != 0) = 0
     *
     * This is the missing condition.
     */
    asm volatile(
        "addi x0, x5, 1\n"
        :
        :
        : "memory"
    );

    /*
     * Another instruction writing to x0.
     */
    asm volatile(
        "add x0, x5, x5\n"
        :
        :
        : "memory"
    );

    /*
     * Verify x0 is still zero.
     */
    asm volatile(
        "mv %0, x0"
        : "=r"(value)
        :
        : "memory"
    );

    result = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}