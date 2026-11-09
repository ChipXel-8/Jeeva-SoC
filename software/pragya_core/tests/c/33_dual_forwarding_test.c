#include "pragya_test.h"
#include <stdint.h>

volatile int a,b,c,d,e,f,g,h,i,j,k,l;
volatile int mem[16];

int main(void)
{
    /*------------------------------------------
      Dual Forwarding (Both operands forwarded)
    ------------------------------------------*/

    a = 10;
    b = 20;

    c = a + b;          // 30
    d = c + c;          // forward A+B
    e = d + c;          // forward both
    f = e + d;          // forward both
    g = f + e;
    h = g + f;
    i = h + g;
    j = i + h;
    k = j + i;
    l = k + j;

    if(l != 2670)
        test_fail();

    /*------------------------------------------
      Mixed ALU Forwarding
    ------------------------------------------*/

    a = 100;
    b = 7;

    c = a - b;
    d = c * b;
    e = d / b;
    f = e % 9;
    g = f ^ e;
    h = g | d;
    i = h & 0xFF;

    if(i != (((((((100-7)*7)/7)%9)^((100-7)*7/7))|((100-7)*7))&0xFF))
        test_fail();

    /*------------------------------------------
      Store -> Load -> Forward
    ------------------------------------------*/

    mem[5] = 123;

    a = mem[5];
    b = a + 1;
    c = b + a;
    d = c + b;

    if(d != 371)
        test_fail();

    /*------------------------------------------
      Long Dependency Chain
    ------------------------------------------*/

    a = 1;

    for(int x=0;x<40;x++)
    {
        b = a + x;
        c = b + 1;
        d = c + 2;
        e = d + 3;
        f = e + 4;
        a = f;
    }

    if(a==0)
        test_fail();

    /*------------------------------------------
      Simultaneous Source Forwarding
    ------------------------------------------*/

    a = 3;
    b = 4;

    c = a * b;
    d = c + a;
    e = c + d;
    f = d + e;
    g = e + f;
    h = f + g;
    i = g + h;
    j = h + i;

    if(j != 534)
        test_fail();

    test_pass();
    return 0;
}
