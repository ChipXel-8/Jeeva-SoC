#include "pragya_test.h"
#include <stdint.h>

volatile uint8_t  mem8[128];
volatile uint16_t mem16[64];
volatile uint32_t mem32[32];

volatile int a,b,c,d,e,f,g,h;

int main(void)
{
    /*------------------------------------------
      BYTE STORE / LOAD
    ------------------------------------------*/

    mem8[0] = 0x12;
    mem8[1] = 0x34;
    mem8[2] = 0x80;
    mem8[3] = 0xFF;

    a = mem8[0];
    b = mem8[1];
    c = (int8_t)mem8[2];
    d = (int8_t)mem8[3];

    if(a != 0x12) test_fail();
    if(b != 0x34) test_fail();
    if(c != -128) test_fail();
    if(d != -1) test_fail();

    /*------------------------------------------
      HALFWORD STORE / LOAD
    ------------------------------------------*/

    mem16[0] = 0x1234;
    mem16[1] = 0x8000;
    mem16[2] = 0xFFFF;

    a = mem16[0];
    b = (int16_t)mem16[1];
    c = (int16_t)mem16[2];

    if(a != 0x1234) test_fail();
    if(b != -32768) test_fail();
    if(c != -1) test_fail();

    /*------------------------------------------
      WORD STORE / LOAD
    ------------------------------------------*/

    mem32[0] = 0x12345678;
    mem32[1] = 0x87654321;
    mem32[2] = 0xFFFFFFFF;

    if(mem32[0] != 0x12345678)
        test_fail();

    if(mem32[1] != 0x87654321)
        test_fail();

    if(mem32[2] != 0xFFFFFFFF)
        test_fail();

    /*------------------------------------------
      Sequential Store / Load
    ------------------------------------------*/

    for(int i=0;i<32;i++)
        mem32[i]=i*17;

    for(int i=0;i<32;i++)
    {
        if(mem32[i] != i*17)
            test_fail();
    }

    /*------------------------------------------
      Store Forwarding
    ------------------------------------------*/

    mem32[5]=5555;

    a = mem32[5];
    b = a+10;
    c = b+20;

    if(c != 5585)
        test_fail();

    /*------------------------------------------
      Byte Boundary
    ------------------------------------------*/

    mem8[31]=99;

    if(mem8[31]!=99)
        test_fail();

    /*------------------------------------------
      Halfword Boundary
    ------------------------------------------*/

    mem16[31]=7777;

    if(mem16[31]!=7777)
        test_fail();

    /*------------------------------------------
      Word Boundary
    ------------------------------------------*/

    mem32[31]=0xDEADBEEF;

    if(mem32[31]!=0xDEADBEEF)
        test_fail();

    /*------------------------------------------
      Mixed Memory Operations
    ------------------------------------------*/

    mem8[10]=11;
    mem16[10]=2222;
    mem32[10]=333333;

    a = mem8[10];
    b = mem16[10];
    c = mem32[10];

    if(a!=11) test_fail();
    if(b!=2222) test_fail();
    if(c!=333333) test_fail();

    /*------------------------------------------
      Load Dependency
    ------------------------------------------*/

    a = mem32[8];
    b = a+1;
    c = b+2;
    d = c+3;
    e = d+4;

    if(e != (mem32[8]+10))
        test_fail();

    test_pass();

    return 0;
}
