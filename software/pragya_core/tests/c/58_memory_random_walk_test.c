#include "pragya_test.h"
#include <stdint.h>

volatile int mem[256];

volatile int a,b,c,d,e,f;
volatile int index;
volatile int sum;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int i=0;i<256;i++)
        mem[i]=i*13+7;

    /*------------------------------------------
      Sequential Read
    ------------------------------------------*/

    sum=0;

    for(int i=0;i<256;i++)
        sum+=mem[i];

    if(sum==0)
        test_fail();

    /*------------------------------------------
      Sequential Write
    ------------------------------------------*/

    for(int i=0;i<256;i++)
        mem[i]=i;

    for(int i=0;i<256;i++)
    {
        if(mem[i]!=i)
            test_fail();
    }

    /*------------------------------------------
      Random Walk
    ------------------------------------------*/

    index=17;

    for(int i=0;i<200;i++)
    {
        index=(index*37+13)&255;

        a=mem[index];
        b=a+5;
        mem[index]=b;
        c=mem[index];

        if(c!=b)
            test_fail();
    }

    /*------------------------------------------
      Store-Load Hazard
    ------------------------------------------*/

    for(int i=0;i<100;i++)
    {
        mem[i]=i*5;

        a=mem[i];

        if(a!=i*5)
            test_fail();
    }

    /*------------------------------------------
      Load-Use Hazard
    ------------------------------------------*/

    for(int i=0;i<100;i++)
    {
        a=mem[i];
        b=a+1;
        c=b+2;
        d=c+3;

        if(d!=(mem[i]+6))
            test_fail();
    }

    /*------------------------------------------
      Reverse Walk
    ------------------------------------------*/

    for(int i=255;i>=0;i--)
    {
        mem[i]+=1;
    }

    /*------------------------------------------
      Mixed Read/Write
    ------------------------------------------*/

    index=91;

    for(int i=0;i<300;i++)
    {
        index=(index*29+17)&255;

        mem[index]+=i;

        a=mem[index];
        b=a^0x55AA55AA;
        c=b+7;
        mem[index]=c;
    }

    /*------------------------------------------
      Continuous RAW
    ------------------------------------------*/

    a=mem[0];

    for(int i=0;i<50;i++)
    {
        a=a+i;
        mem[i]=a;
        a=mem[i];
    }

    if(a==0)
        test_fail();

    test_pass();

    return 0;
}
