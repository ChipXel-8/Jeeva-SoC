#include "pragya_test.h"
#include <stdint.h>

volatile int a;
volatile int b;
volatile int c;

int main(void)
{
    /*------------------------------------------
      Basic arithmetic
    ------------------------------------------*/

    a = 10;
    b = 20;

    c = a + b;

    if(c != 30)
        test_fail();

    /*------------------------------------------
      Operations with zero
    ------------------------------------------*/

    c = a + 0;

    if(c != 10)
        test_fail();

    c = 0 + b;

    if(c != 20)
        test_fail();

    c = a - 0;

    if(c != 10)
        test_fail();

    c = 0 - a;

    if(c != -10)
        test_fail();

    /*------------------------------------------
      Logical operations with zero
    ------------------------------------------*/

    c = a & 0;

    if(c != 0)
        test_fail();

    c = a | 0;

    if(c != a)
        test_fail();

    c = a ^ 0;

    if(c != a)
        test_fail();

    /*------------------------------------------
      Shift by zero
    ------------------------------------------*/

    c = a << 0;

    if(c != a)
        test_fail();

    c = a >> 0;

    if(c != a)
        test_fail();

    /*------------------------------------------
      Compare with zero
    ------------------------------------------*/

    if(a == 0)
        test_fail();

    if(!(a != 0))
        test_fail();

    c = 0;

    if(c != 0)
        test_fail();

    /*------------------------------------------
      Zero assignment
    ------------------------------------------*/

    a = 0;

    if(a != 0)
        test_fail();

    /*------------------------------------------
      Loop starting from zero
    ------------------------------------------*/

    c = 0;

    for(int i = 0; i < 10; i++)
        c += i;

    if(c != 45)
        test_fail();

    test_pass();

    return 0;
}