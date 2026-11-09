#include "pragya_test.h"
#include <stdint.h>

volatile int mem[128];

volatile int a,b,c,d,e,f,g,h,i,j;
volatile int sum;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int k=0;k<128;k++)
        mem[k]=k;

    /*------------------------------------------
      Continuous Load-Use Hazards
    ------------------------------------------*/

    for(int k=0;k<20;k++)
    {
        a=mem[k];
        b=a+1;
        c=b+2;
        d=c+3;

        if(d!=(k+6))
            test_fail();
    }

    /*------------------------------------------
      Store -> Load Hazard
    ------------------------------------------*/

    for(int k=0;k<20;k++)
    {
        mem[k]=k*10;

        a=mem[k];

        if(a!=(k*10))
            test_fail();
    }

    /*------------------------------------------
      RAW Dependency Chain
    ------------------------------------------*/

    a=1;

    for(int k=0;k<50;k++)
    {
        b=a+k;
        c=b+1;
        d=c+2;
        e=d+3;
        f=e+4;

        a=f;
    }

    if(a==0)
        test_fail();

    /*------------------------------------------
      Branch Flush (Taken)
    ------------------------------------------*/

    sum=0;

    for(int k=0;k<50;k++)
    {
        if(k<25)
            sum+=k;
        else
            sum-=k;
    }

    if(sum!=-625)
        test_fail();

    /*------------------------------------------
      Branch Flush (Alternating)
    ------------------------------------------*/

    sum=0;

    for(int k=0;k<40;k++)
    {
        if(k&1)
            sum+=3;
        else
            sum-=2;
    }

    if(sum!=20)
        test_fail();

    /*------------------------------------------
      Nested Branches
    ------------------------------------------*/

    sum=0;

    for(int i=0;i<8;i++)
    {
        for(int j=0;j<8;j++)
        {
            if(i>j)
                sum++;

            else if(i<j)
                sum+=2;

            else
                sum+=3;
        }
    }

    if(sum!=100)
        test_fail();

    /*------------------------------------------
      Continuous Memory Hazards
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        mem[k]=k+100;

        a=mem[k];
        b=a+1;

        mem[k+32]=b;

        c=mem[k+32];

        if(c!=(k+101))
            test_fail();
    }

    /*------------------------------------------
      Forward + Stall Mix
    ------------------------------------------*/

    a=5;

    for(int k=0;k<60;k++)
    {
        a=a+1;
        b=a+2;
        c=b+3;
        d=c+4;

        mem[k]=d;

        e=mem[k];

        a=e;
    }

    if(a==0)
        test_fail();

    /*------------------------------------------
      Pipeline Stress
    ------------------------------------------*/

    a=1;

    for(int k=0;k<100;k++)
    {
        a=a+k;
        a=a^k;
        a=a+3;
        a=a-2;
        a=a<<1;
        a=a>>1;
    }

    if(a==0)
        test_fail();

    /*------------------------------------------
      Memory Burst
    ------------------------------------------*/

    for(int k=0;k<64;k++)
        mem[k]=k*5;

    for(int k=0;k<64;k++)
    {
        if(mem[k]!=(k*5))
            test_fail();
    }

    test_pass();

    return 0;
}
