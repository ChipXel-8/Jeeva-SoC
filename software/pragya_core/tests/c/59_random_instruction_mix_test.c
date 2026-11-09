#include "pragya_test.h"
#include <stdint.h>

volatile int mem[256];

volatile int a,b,c,d,e,f,g,h,i,j;
volatile unsigned ua,ub;
volatile int sum;

int main(void)
{
    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    for(int k=0;k<256;k++)
        mem[k]=k*7+3;

    a=5;
    b=11;
    c=17;
    d=23;
    e=31;

    /*------------------------------------------
      Random Instruction Mix
    ------------------------------------------*/

    for(int k=0;k<200;k++)
    {
        a=a+b;
        b=b^c;
        c=c|d;
        d=d&e;
        e=e+a;

        a=a<<1;
        b=(unsigned)b>>2;
        c=c>>1;

        d=d+k;
        e=e-k;

        f=a*b;
        g=f/3;
        h=g%7;

        i=mem[(k*13)&255];
        j=i+h;

        mem[(k*17)&255]=j;

        if(k&1)
            a+=j;
        else
            b-=j;

        if(a>b)
            c++;
        else
            d++;

        ua=(unsigned)a;
        ub=(unsigned)b;

        if(ua<ub)
            e++;
        else
            e--;

        a=mem[(k*19)&255];
        b=a+1;
        c=b+2;
        d=c+3;
    }

    /*------------------------------------------
      Memory Verification
    ------------------------------------------*/

    sum=0;

    for(int k=0;k<256;k++)
        sum+=mem[k];

    if(sum==0)
        test_fail();

    /*------------------------------------------
      Register Dependency
    ------------------------------------------*/

    a=1;

    for(int k=0;k<100;k++)
    {
        a=a+k;
        a=a*2;
        a=a/2;
        a=a%1000;
        a=a^k;
    }

    if(a==0)
        test_fail();

    test_pass();

    return 0;
}
