#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    volatile uint32_t *p =
        (volatile uint32_t *)0x80008040;

    /*
     * ============================================================
     * PIPELINE STALL TEST
     * ============================================================
     */

    p[0] = 0xAAAAAAAA;
    p[1] = 0x55555555;
    p[2] = 0xFFFFFFFF;
    p[3] = 0x00000000;


    /*
     * Load followed immediately by dependent operation.
     */
    asm volatile(
        "li x5, 0x80008040\n"
        "lw x6, 0(x5)\n"
        "add x7, x6, x6\n"
        "xor x8, x7, x6\n"
        :
        :
        : "memory"
    );


    /*
     * Another delayed load.
     */
    asm volatile(
        "li x5, 0x80008044\n"
        "lw x6, 0(x5)\n"
        "add x7, x6, x6\n"
        "sub x8, x7, x6\n"
        :
        :
        : "memory"
    );


    /*
     * More memory dependencies.
     */
    asm volatile(
        "li x5, 0x80008048\n"
        "lw x6, 0(x5)\n"
        "add x7, x6, x6\n"
        "and x8, x7, x6\n"

        "li x5, 0x8000804C\n"
        "lw x9, 0(x5)\n"
        "or x10, x9, x7\n"
        :
        :
        : "memory"
    );


    value = p[0];

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}