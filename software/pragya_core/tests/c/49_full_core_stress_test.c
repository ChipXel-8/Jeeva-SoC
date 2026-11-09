#include "pragya_test.h"
#include <stdint.h>

volatile int mem[256];

volatile int a,b,c,d,e,f,g,h,i,j,k,sum;

static int mul_add(int x,int y)
{
    return (x*y)+x-y;
}

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int x=0;x<256;x++)
        mem[x]=x;

    /*------------------------------------------
      CSR Read
    ------------------------------------------*/

    asm volatile("csrr %0,mstatus":"=r"(a));
    asm volatile("csrr %0,mie":"=r"(b));

    if((a|b)==0xFFFFFFFF)
        test_fail();

    /*------------------------------------------
      Full ALU Chain
    ------------------------------------------*/

    a=15;
    b=7;

    c=a+b;
    d=c-b;
    e=d*b;
    f=e/3;
    g=f%11;
    h=g<<3;
    i=h>>2;
    j=i^0x1234;
    k=j|0x55AA;

    if(k==0)
        test_fail();

    /*------------------------------------------
      Load Store Hazard
    ------------------------------------------*/

    for(int x=0;x<64;x++)
    {
        mem[x]=x*9;

        a=mem[x];
        b=a+1;
        c=b+2;

        mem[x]=c;
    }

    /*------------------------------------------
      Verify Memory
    ------------------------------------------*/

    for(int x=0;x<64;x++)
    {
        if(mem[x]!=(x*9+3))
            test_fail();
    }

    /*------------------------------------------
      Nested Branches
    ------------------------------------------*/

    sum=0;

    for(int x=0;x<20;x++)
    {
        for(int y=0;y<20;y++)
        {
            if(x>y)
                sum++;

            else if(x<y)
                sum+=2;

            else
                sum+=3;
        }
    }

    if(sum==0)
        test_fail();

    /*------------------------------------------
      RV32M Stress
    ------------------------------------------*/

    a=1;

    for(int x=1;x<=20;x++)
    {
        a*=x;
        a/=x;
        a+=x;
        a%=97;
    }

    if(a==0)
        test_fail();

    /*------------------------------------------
      Forwarding Chain
    ------------------------------------------*/

    a=1;

    for(int x=0;x<100;x++)
    {
        b=a+x;
        c=b+1;
        d=c+2;
        e=d+3;
        f=e+4;
        g=f+5;

        a=g;
    }

    if(a==0)
        test_fail();

    /*------------------------------------------
      Function Calls
    ------------------------------------------*/

    for(int x=1;x<20;x++)
    {
        sum+=mul_add(x,x+1);
    }

    if(sum==0)
        test_fail();

    /*------------------------------------------
      Memory Burst
    ------------------------------------------*/

    for(int x=0;x<128;x++)
        mem[x]=x*x;

    for(int x=0;x<128;x++)
    {
        if(mem[x]!=(x*x))
            test_fail();
    }

    /*------------------------------------------
      Mixed Operations
    ------------------------------------------*/

    a=100;

    for(int x=0;x<50;x++)
    {
        a=a+x;
        a=a^x;
        a=a|0x1234;
        a=a&0x7FFFFFFF;
        a=a<<1;
        a=a>>1;
    }

    if(a==0)
        test_fail();

    test_pass();

    return 0;
}
