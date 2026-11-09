#include "pragya_test.h"
#include <stdint.h>

volatile int mem[128];

volatile int a;
volatile int b;
volatile int c;
volatile int d;
volatile int sum;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int k=0;k<128;k++)
        mem[k]=k+1;

    sum=0;

    /*------------------------------------------
      Load -> Use -> Branch
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        a=mem[k];
        b=a+1;

        if(b>32)
            sum+=10;
        else
            sum+=1;
    }

    /*------------------------------------------
      Load -> ALU -> Branch
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        a=mem[k];
        b=a+2;
        c=b+3;

        if(c & 1)
            sum+=5;
        else
            sum-=2;
    }

    /*------------------------------------------
      Branch After Multiple Dependencies
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        a=mem[k];
        b=a+1;
        c=b+1;
        d=c+1;

        if(d>20)
            sum+=d;
        else
            sum-=d;
    }

    /*------------------------------------------
      Alternating Branch
    ------------------------------------------*/

    for(int k=0;k<100;k++)
    {
        a=mem[k&31];

        if(a & 1)
            sum+=a;
        else
            sum-=a;
    }

    /*------------------------------------------
      Verify
    ------------------------------------------*/

    if(sum==0)
        test_fail();

    test_pass();

    return 0;
}