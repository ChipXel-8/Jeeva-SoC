#include "pragya_test.h"
#include <stdint.h>

volatile int mem[256];

volatile int a;
volatile int b;
volatile int c;
volatile int d;
volatile int e;
volatile int sum;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int k=0;k<256;k++)
        mem[k]=k;

    sum=0;

    /*------------------------------------------
      Load -> Use -> Branch
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        a=mem[k];
        b=a+1;

        if(b>32)
            sum+=b;
        else
            sum-=b;
    }

    /*------------------------------------------
      Store -> Load -> Dependency
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        mem[k]=k*3;

        a=mem[k];
        b=a+1;
        c=b+2;
        d=c+3;

        if(d!=(k*3+6))
            test_fail();
    }

    /*------------------------------------------
      Continuous RAW Chain
    ------------------------------------------*/

    a=1;

    for(int k=0;k<64;k++)
    {
        b=a+k;
        c=b+1;
        d=c+1;
        e=d+1;

        a=e;
    }

    /*------------------------------------------
      Alternating Branch
    ------------------------------------------*/

    for(int k=0;k<128;k++)
    {
        a=mem[k];

        if(a & 1)
            sum+=a;
        else
            sum-=a;
    }

    /*------------------------------------------
      Nested Branch
    ------------------------------------------*/

    for(int i=0;i<16;i++)
    {
        for(int j=0;j<16;j++)
        {
            a=i+j;

            if(a<5)
                sum+=1;
            else if(a<15)
                sum+=2;
            else
                sum+=3;
        }
    }

    /*------------------------------------------
      Loop + Load + Branch
    ------------------------------------------*/

    for(int k=0;k<100;k++)
    {
        a=mem[k];

        if(a==50)
            break;

        b=a+1;
        c=b+1;
    }

    /*------------------------------------------
      Forward + Stall Mix
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        a=mem[k];
        b=a+1;
        c=b+2;
        d=c+3;

        mem[k+128]=d;

        e=mem[k+128];

        if(e&1)
            sum+=e;
        else
            sum-=e;
    }

    /*------------------------------------------
      Long Loop
    ------------------------------------------*/

    a=1;

    for(int k=0;k<200;k++)
    {
        a=a+k;
        a=a^k;
        a=a+1;

        if(a&4)
            a=a+3;
        else
            a=a-2;
    }

    /*------------------------------------------
      Final Verification
    ------------------------------------------*/

    if(a==0)
        test_fail();

    if(sum==0)
        test_fail();

    test_pass();

    return 0;
}