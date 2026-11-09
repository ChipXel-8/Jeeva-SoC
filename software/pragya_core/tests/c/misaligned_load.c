#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t result;

int main(void)
{
    volatile uint32_t *base =
        (volatile uint32_t *)0x80008000;

    /*
     * Create known memory contents.
     */
    asm volatile(
        "li x5, 0x11223344\n"
        "li x6, 0x80008000\n"
        "sw x5, 0(x6)\n"
        :
        :
        : "memory"
    );

    /*
     * MISALIGNED LW
     *
     * Address = 0x80008001
     * LW requires address[1:0] == 00
     *
     * Therefore:
     * misaligned_load_in = 1
     */
    asm volatile(
        "li x6, 0x80008001\n"
        "lw x7, 0(x6)\n"
        :
        :
        : "memory"
    );

    result = *base;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}