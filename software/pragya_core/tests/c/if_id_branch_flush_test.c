#include "pragya_test.h"
#include <stdint.h>

volatile int mem[128];

volatile int a;
volatile int b;
volatile int sum;

int main(void)
{
    /*------------------------------------------
      Initialization
    ------------------------------------------*/

    for(int k=0;k<128;k++)
        mem[k]=k;

    sum=0;

    /*------------------------------------------
      Taken Branch - Forward
    ------------------------------------------*/

    for(int k=0;k<50;k++)
    {
        if(k<25)
        {
            sum += k;
        }
        else
        {
            sum += 100;
        }
    }

    /*------------------------------------------
      Taken Branch - Backward Loop
    ------------------------------------------*/

    for(int k=0;k<32;k++)
    {
        if(k==16)
            sum += 10;

        else
            sum += 1;
    }

    /*------------------------------------------
      Alternating Taken / Not Taken
    ------------------------------------------*/

    for(int k=0;k<64;k++)
    {
        if(k & 1)
            sum += 3;
        else
            sum -= 1;
    }

    /*------------------------------------------
      Branch With Data Dependency
    ------------------------------------------*/

    a=10;

    for(int k=0;k<32;k++)
    {
        b=a+k;

        if(b>20)
            a=b+1;
        else
            a=b-1;
    }

    /*------------------------------------------
      Nested Taken Branches
    ------------------------------------------*/

    for(int i=0;i<16;i++)
    {
        for(int j=0;j<16;j++)
        {
            if(i==j)
                sum+=1;
            else if(i>j)
                sum+=2;
            else
                sum+=3;
        }
    }

    /*------------------------------------------
      Branch Around Instructions
    ------------------------------------------*/

    for(int k=0;k<20;k++)
    {
        if(k==5)
        {
            a=0x11111111;
        }
        else
        {
            a=0x22222222;
        }
    }

    /*------------------------------------------
      Verify
    ------------------------------------------*/

    if(a==0)
        test_fail();

    if(sum==0)
        test_fail();

    test_pass();

    return 0;
}