#include "pragya_test.h"
#include <stdint.h>

volatile int a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p;
volatile int result;

int main(void)
{
    /*------------------------------------------
      Long RAW Dependency Chain
    ------------------------------------------*/

    a = 10;
    b = a + 1;
    c = b + 2;
    d = c + 3;
    e = d + 4;
    f = e + 5;
    g = f + 6;
    h = g + 7;
    i = h + 8;
    j = i + 9;
    k = j + 10;
    l = k + 11;
    m = l + 12;
    n = m + 13;
    o = n + 14;
    p = o + 15;

    if(p != 130)
        test_fail();

    /*------------------------------------------
      ALU Forwarding Chain
    ------------------------------------------*/

    a = 100;

    b = a + 5;
    c = b - 3;
    d = c ^ 0x55;
    e = d | 0xAA;
    f = e & 0xFF;
    g = f << 2;
    h = g >> 1;
    i = h + 7;
    j = i - 2;

    if(j != (((((((((100+5)-3)^0x55)|0xAA)&0xFF)<<2)>>1)+7)-2))
        test_fail();

    /*------------------------------------------
      Mixed Arithmetic Dependency
    ------------------------------------------*/

    a = 7;

    b = a * 5;
    c = b + 9;
    d = c / 4;
    e = d % 3;
    f = e + 11;
    g = f * 8;
    h = g - 13;

    if(h != ((((((7*5)+9)/4)%3)+11)*8)-13)
        test_fail();

    /*------------------------------------------
      Immediate RAW Dependencies
    ------------------------------------------*/

    result = 1;

    for(int x=0;x<32;x++)
    {
        result = result + x;
        result = result ^ x;
        result = result + 3;
        result = result - 1;
    }

    if(result==0)
        test_fail();

    test_pass();

    return 0;
}
