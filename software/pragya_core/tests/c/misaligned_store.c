#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t result;

int main(void)
{
    /*
     * MISALIGNED SW
     *
     * Address = 0x80008001
     * SW requires address[1:0] == 00
     *
     * Therefore:
     * misaligned_store_in = 1
     */
    asm volatile(
        "li x5, 0xA5A5A5A5\n"
        "li x6, 0x80008001\n"
        "sw x5, 0(x6)\n"
        :
        :
        : "memory"
    );

    /*
     * Also exercise a normal aligned store.
     */
    asm volatile(
        "li x6, 0x80008020\n"
        "sw x5, 0(x6)\n"
        :
        :
        : "memory"
    );

    result = 0xA5A5A5A5;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}