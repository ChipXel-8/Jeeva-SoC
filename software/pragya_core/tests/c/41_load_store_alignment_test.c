#include "pragya_test.h"
#include <stdint.h>

volatile uint8_t mem[256];

volatile uint8_t  b;
volatile uint16_t h;
volatile uint32_t w;

volatile int i;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(i=0;i<256;i++)
        mem[i]=0;

    /*------------------------------------------
      Byte Alignment
    ------------------------------------------*/

    mem[0]=0x11;
    mem[1]=0x22;
    mem[2]=0x33;
    mem[3]=0x44;

    if(mem[0]!=0x11) test_fail();
    if(mem[1]!=0x22) test_fail();
    if(mem[2]!=0x33) test_fail();
    if(mem[3]!=0x44) test_fail();

    /*------------------------------------------
      Halfword Alignment
    ------------------------------------------*/

    *((volatile uint16_t*)&mem[4])=0x1234;
    *((volatile uint16_t*)&mem[6])=0x5678;

    h=*((volatile uint16_t*)&mem[4]);
    if(h!=0x1234)
        test_fail();

    h=*((volatile uint16_t*)&mem[6]);
    if(h!=0x5678)
        test_fail();

    /*------------------------------------------
      Word Alignment
    ------------------------------------------*/

    *((volatile uint32_t*)&mem[8])=0x89ABCDEF;
    *((volatile uint32_t*)&mem[12])=0x12345678;

    w=*((volatile uint32_t*)&mem[8]);
    if(w!=0x89ABCDEF)
        test_fail();

    w=*((volatile uint32_t*)&mem[12]);
    if(w!=0x12345678)
        test_fail();

    /*------------------------------------------
      Store -> Immediate Load
    ------------------------------------------*/

    *((volatile uint32_t*)&mem[32])=0xAAAAAAAA;

    w=*((volatile uint32_t*)&mem[32]);

    if(w!=0xAAAAAAAA)
        test_fail();

    /*------------------------------------------
      Consecutive Stores
    ------------------------------------------*/

    for(i=0;i<16;i++)
        *((volatile uint32_t*)&mem[64+i*4])=i*111;

    for(i=0;i<16;i++)
    {
        w=*((volatile uint32_t*)&mem[64+i*4]);

        if(w!=(uint32_t)(i*111))
            test_fail();
    }

    /*------------------------------------------
      Address Calculation
    ------------------------------------------*/

    for(i=0;i<32;i++)
        mem[128+i]=i;

    for(i=0;i<32;i++)
    {
        b=mem[128+i];

        if(b!=(uint8_t)i)
            test_fail();
    }

    /*------------------------------------------
      Reverse Access
    ------------------------------------------*/

    for(i=31;i>=0;i--)
    {
        b=mem[128+i];

        if(b!=(uint8_t)i)
            test_fail();
    }

    /*------------------------------------------
      Mixed Access Sizes
    ------------------------------------------*/

    mem[200]=0xAA;

    *((volatile uint16_t*)&mem[202])=0xBBBB;

    *((volatile uint32_t*)&mem[208])=0xCCCCDDDD;

    if(mem[200]!=0xAA)
        test_fail();

    if(*((volatile uint16_t*)&mem[202])!=0xBBBB)
        test_fail();

    if(*((volatile uint32_t*)&mem[208])!=0xCCCCDDDD)
        test_fail();

    test_pass();

    return 0;
}
