#include "pragya_test.h"
#include <stdint.h>

volatile int a,b,c,d,e,f,g,h,i,j;

int main(void)
{
    a = 10;

    /*------------------------------------------
      Forward A
    ------------------------------------------*/

    b = a + 5;

    if(b != 15)
        test_fail();

    c = b + 10;

    if(c != 25)
        test_fail();

    d = c + 20;

    if(d != 45)
        test_fail();

    /*------------------------------------------
      Forward B
    ------------------------------------------*/

    e = d - a;

    if(e != 35)
        test_fail();

    f = e ^ b;

    if(f != (35 ^ 15))
        test_fail();

    g = f | c;

    if(g != ((35 ^ 15) | 25))
        test_fail();

    h = g & d;

    if(h != (((35 ^ 15) | 25) & 45))
        test_fail();

    /*------------------------------------------
      Shift Dependency
    ------------------------------------------*/

    i = h << 2;

    if(i != (h << 2))
        test_fail();

    j = i >> 1;

    if(j != (i >> 1))
        test_fail();

    /*------------------------------------------
      Long Dependency Chain
    ------------------------------------------*/

    a = 1;

    a = a + 1;
    a = a + 2;
    a = a + 3;
    a = a + 4;
    a = a + 5;
    a = a + 6;
    a = a + 7;
    a = a + 8;
    a = a + 9;

    if(a != 46)
        test_fail();

    /*------------------------------------------
      Mixed Dependencies
    ------------------------------------------*/

    b = a * 2;

    c = b / 2;

    d = c % 5;

    e = d + 100;

    if(e != ((46 * 2) / 2 % 5 + 100))
        test_fail();

    test_pass();

    return 0;
}