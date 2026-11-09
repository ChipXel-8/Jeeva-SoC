#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    volatile uint32_t *mem =
        (volatile uint32_t *)0x80008020;

    uint32_t a;
    uint32_t b;
    uint32_t c;

    /*
     * ============================================================
     * OBI DATA REQUEST TEST
     * ============================================================
     */

    /* Store */
    mem[0] = 0xAAAAAAAA;

    /* Load */
    a = mem[0];

    /* Store */
    mem[1] = 0x55555555;

    /* Load */
    b = mem[1];

    /* Store */
    mem[2] = 0xFFFFFFFF;

    /* Load */
    c = mem[2];

    /*
     * More separated memory transactions
     */
    mem[4] = 0x12345678;
    sink = mem[4];

    mem[8] = 0x87654321;
    sink = mem[8];

    mem[12] = 0x00000000;
    sink = mem[12];

    /*
     * Different data patterns
     */
    mem[16] = 0x00000001;
    sink = mem[16];

    mem[20] = 0x80000000;
    sink = mem[20];

    mem[24] = 0x7FFFFFFF;
    sink = mem[24];

    /*
     * Keep results alive
     */
    sink = a ^ b ^ c;

    /*
     * Required pass condition:
     *
     * TOHOST = 1
     *
     * This generates the store that your Makefile/Spike flow
     * expects at 0x80008000.
     */
    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}