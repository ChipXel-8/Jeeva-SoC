#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t a, b, c;

    /*
     * ============================================================
     * INSTRUCTION MEMORY ADDRESS / DATA TOGGLE TEST
     * ============================================================
     */

    /* Immediate instructions */
    a = 0x00000000;
    b = 0xFFFFFFFF;

    a = a + 1;
    b = b - 1;

    /* Logic instructions */
    c = a & b;
    c = a | b;
    c = a ^ b;

    /* Shift instructions */
    c = a << 1;
    c = a << 7;
    c = a << 15;
    c = a << 31;

    c = b >> 1;
    c = b >> 7;
    c = b >> 15;
    c = b >> 31;

    /* Arithmetic */
    c = a + b;
    c = a - b;

    /* Comparisons */
    c = (a < b);
    c = ((int32_t)a < (int32_t)b);

    /*
     * Branches
     */
    if (a == a)
        c = 0x11111111;

    if (a != b)
        c = 0x22222222;

    if (a < b)
        c = 0x33333333;

    if (a >= b)
        c = 0x44444444;

    /*
     * Loop creates many sequential instruction fetches.
     */
    for (int i = 0; i < 32; i++) {
        c ^= (uint32_t)i;
        c += 0x11111111;
    }

    /*
     * Prevent optimization.
     */
    sink = c;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}