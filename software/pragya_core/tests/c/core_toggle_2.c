#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    /*
     * ============================================================
     * ALU TOGGLE TEST
     * ============================================================
     */

    asm volatile(
        "li x5, 0x00000000\n"
        "li x6, 0xffffffff\n"

        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "and x9, x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        "li x5, 0xaaaaaaaa\n"
        "li x6, 0x55555555\n"

        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "and x9, x5, x6\n"
        "or  x10, x5, x6\n"
        "xor x11, x5, x6\n"

        "li x5, 0x80000000\n"
        "li x6, 0x00000001\n"

        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"

        :
        :
        : "memory"
    );

    value = 0xdeadbeef;
    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}