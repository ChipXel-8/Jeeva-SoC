#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    volatile uint8_t  *p8  =
        (volatile uint8_t *)0x80008100;

    volatile uint16_t *p16 =
        (volatile uint16_t *)0x80008110;

    volatile uint32_t *p32 =
        (volatile uint32_t *)0x80008120;

    uint32_t value;

    /*
     * ============================================================
     * LSU / DATA INTERFACE TOGGLE TEST
     * ============================================================
     */

    /* BYTE */
    p8[0] = 0x00;
    p8[1] = 0xff;
    p8[2] = 0xaa;
    p8[3] = 0x55;

    value = p8[0];
    value = p8[1];
    value = p8[2];
    value = p8[3];

    /* HALFWORD */
    p16[0] = 0x0000;
    p16[1] = 0xffff;
    p16[2] = 0xaaaa;
    p16[3] = 0x5555;

    value = p16[0];
    value = p16[1];
    value = p16[2];
    value = p16[3];

    /* WORD */
    p32[0] = 0x00000000;
    p32[1] = 0xffffffff;
    p32[2] = 0xaaaaaaaa;
    p32[3] = 0x55555555;
    p32[4] = 0x12345678;
    p32[5] = 0x87654321;

    value = p32[0];
    value = p32[1];
    value = p32[2];
    value = p32[3];
    value = p32[4];
    value = p32[5];

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}