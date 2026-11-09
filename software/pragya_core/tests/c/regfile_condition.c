#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t a;

    /*
     * Force register-file condition:
     *
     * reg_write_in = 1
     * rd_addrs_in  = 0
     *
     * ADDI x0, x0, immediate
     */
    asm volatile(
        "addi x0, x0, 0x123\n"
        "addi x0, x0, -1\n"
        "add  x0, x0, x0\n"
        "sub  x0, x0, x0\n"
        "and  x0, x0, x0\n"
        "or   x0, x0, x0\n"
        "xor  x0, x0, x0\n"
        :
        :
        : "memory"
    );

    /*
     * Also exercise normal register writes so that
     * reg_write_in = 1 and rd != 0 remains covered.
     */
    asm volatile(
        "li x5, 0x123\n"
        "li x6, 0x456\n"
        "add x7, x5, x6\n"
        :
        :
        : "memory"
    );

    a = 0x12345678;
    sink = a;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}