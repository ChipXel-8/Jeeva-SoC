#include "pragya_test.h"
#include <stdint.h>

volatile int8_t   sbuf[8];
volatile int16_t  hbuf[8];

volatile int8_t   lb;
volatile uint8_t  lbu;
volatile int16_t  lh;
volatile uint16_t lhu;

int main(void)
{
    /*------------------------------------------
      Initialize Byte Memory
    ------------------------------------------*/

    sbuf[0] = 0x7F;              // +127
    sbuf[1] = (int8_t)0x80;      // -128
    sbuf[2] = (int8_t)0xFF;      // -1
    sbuf[3] = 0x00;

    /*------------------------------------------
      LB (Signed)
    ------------------------------------------*/

    lb = sbuf[0];

    if(lb != 127)
        test_fail();

    lb = sbuf[1];

    if(lb != -128)
        test_fail();

    lb = sbuf[2];

    if(lb != -1)
        test_fail();

    /*------------------------------------------
      LBU (Unsigned)
    ------------------------------------------*/

    lbu = (uint8_t)sbuf[0];

    if(lbu != 127)
        test_fail();

    lbu = (uint8_t)sbuf[1];

    if(lbu != 128)
        test_fail();

    lbu = (uint8_t)sbuf[2];

    if(lbu != 255)
        test_fail();

    /*------------------------------------------
      Initialize Halfword Memory
    ------------------------------------------*/

    hbuf[0] = 0x7FFF;                 // +32767
    hbuf[1] = (int16_t)0x8000;        // -32768
    hbuf[2] = (int16_t)0xFFFF;        // -1
    hbuf[3] = 0;

    /*------------------------------------------
      LH (Signed)
    ------------------------------------------*/

    lh = hbuf[0];

    if(lh != 32767)
        test_fail();

    lh = hbuf[1];

    if(lh != -32768)
        test_fail();

    lh = hbuf[2];

    if(lh != -1)
        test_fail();

    /*------------------------------------------
      LHU (Unsigned)
    ------------------------------------------*/

    lhu = (uint16_t)hbuf[0];

    if(lhu != 32767)
        test_fail();

    lhu = (uint16_t)hbuf[1];

    if(lhu != 32768)
        test_fail();

    lhu = (uint16_t)hbuf[2];

    if(lhu != 65535)
        test_fail();

    /*------------------------------------------
      Additional Checks
    ------------------------------------------*/

    if((int32_t)lb != -1)
        test_fail();

    if((uint32_t)lbu != 255)
        test_fail();

    if((int32_t)lh != -1)
        test_fail();

    if((uint32_t)lhu != 65535)
        test_fail();

    test_pass();

    return 0;
}