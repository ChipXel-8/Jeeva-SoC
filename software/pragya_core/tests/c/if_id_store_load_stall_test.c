#include "pragya_test.h"
#include <stdint.h>

volatile int mem[128];

volatile int a;
volatile int b;
volatile int c;
volatile int d;

int main(void)
{
    /*------------------------------------------
      Initialize
    ------------------------------------------*/

    for(int k=0;k<128;k++)
        mem[k]=0;

    /*------------------------------------------
      Store -> Load
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        mem[k]=k+100;

        a=mem[k];
        b=a+1;
        c=b+1;

        if(c!=(k+102))
            test_fail();
    }

    /*------------------------------------------
      Store -> Load -> Use
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        mem[k]=0x1000+k;

        a=mem[k];
        b=a+1;
        c=b+2;
        d=c+3;

        if(d!=(0x1006+k))
            test_fail();
    }

    /*------------------------------------------
      Repeated Store / Load
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        mem[k]=k*10;
        a=mem[k];

        if(a!=(k*10))
            test_fail();
    }

    /*------------------------------------------
      Verify
    ------------------------------------------*/

    if(d==0)
        test_fail();

    test_pass();

    return 0;
}