#include "pragya_test.h"
#include <stdint.h>

volatile int mem[128];

volatile int a;
volatile int b;
volatile int c;
volatile int d;
volatile int e;
volatile int f;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int k=0;k<128;k++)
        mem[k]=k+100;

    /*------------------------------------------
      Continuous Load-Use Hazard
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        a=mem[k];
        b=a+1;

        c=b+1;
        d=c+1;
        e=d+1;
        f=e+1;

        if(f!=(k+105))
            test_fail();
    }

    /*------------------------------------------
      Immediate Load -> Use
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        a=mem[k];
        b=a;

        if(b!=(k+100))
            test_fail();
    }

    /*------------------------------------------
      Load Followed By Multiple Uses
    ------------------------------------------*/

    for(int k=0;k<20;k++)
    {
        a=mem[k];

        b=a+10;
        c=a+20;
        d=a+30;
        e=a+40;

        if(b!=(k+110))
            test_fail();

        if(c!=(k+120))
            test_fail();

        if(d!=(k+130))
            test_fail();

        if(e!=(k+140))
            test_fail();
    }

    /*------------------------------------------
      Load -> ALU -> ALU Chain
    ------------------------------------------*/

    for(int k=0;k<20;k++)
    {
        a=mem[k];
        b=a+1;
        c=b+2;
        d=c+3;
        e=d+4;

        if(e!=(k+110))
            test_fail();
    }

    /*------------------------------------------
      Verify
    ------------------------------------------*/

    if(e==0)
        test_fail();

    test_pass();

    return 0;
}