#include "pragya_test.h"
#include <stdint.h>

#define MEM_SIZE 128

volatile uint8_t mem[MEM_SIZE];

volatile uint8_t  b;
volatile uint16_t h;
volatile uint32_t w;

int main(void)
{
    /*--------------------------------------------------
      Initialize Memory
    --------------------------------------------------*/

    for(int i=0;i<MEM_SIZE;i++)
        mem[i]=0;

    /*--------------------------------------------------
      First Byte
    --------------------------------------------------*/

    mem[0]=0x11;

    if(mem[0]!=0x11)
        test_fail();

    /*--------------------------------------------------
      Last Byte
    --------------------------------------------------*/

    mem[127]=0xAA;

    if(mem[127]!=0xAA)
        test_fail();

    /*--------------------------------------------------
      First Halfword
    --------------------------------------------------*/

    *(volatile uint16_t *)&mem[2]=0x1234;

    h=*(volatile uint16_t *)&mem[2];

    if(h!=0x1234)
        test_fail();

    /*--------------------------------------------------
      Last Halfword
    --------------------------------------------------*/

    *(volatile uint16_t *)&mem[124]=0x5678;

    h=*(volatile uint16_t *)&mem[124];

    if(h!=0x5678)
        test_fail();

    /*--------------------------------------------------
      First Word
    --------------------------------------------------*/

    *(volatile uint32_t *)&mem[8]=0xCAFEBABE;

    w=*(volatile uint32_t *)&mem[8];

    if(w!=0xCAFEBABE)
        test_fail();

    /*--------------------------------------------------
      Last Word
    --------------------------------------------------*/

    *(volatile uint32_t *)&mem[120]=0x12345678;

    w=*(volatile uint32_t *)&mem[120];

    if(w!=0x12345678)
        test_fail();

    /*--------------------------------------------------
      Sequential Access
    --------------------------------------------------*/

    for(int i=0;i<32;i++)
        mem[i]=i;

    for(int i=0;i<32;i++)
    {
        if(mem[i]!=i)
            test_fail();
    }

    /*--------------------------------------------------
      Reverse Access
    --------------------------------------------------*/

    for(int i=31;i>=0;i--)
    {
        if(mem[i]!=i)
            test_fail();
    }

    /*--------------------------------------------------
      Word Boundary Stress
    --------------------------------------------------*/

    for(int i=0;i<16;i++)
    {
        *(volatile uint32_t *)&mem[i*4]=0x1000+i;
    }

    for(int i=0;i<16;i++)
    {
        w=*(volatile uint32_t *)&mem[i*4];

        if(w!=(0x1000+i))
            test_fail();
    }

    test_pass();

    return 0;
}