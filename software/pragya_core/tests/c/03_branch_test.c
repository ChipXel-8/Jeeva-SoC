#include "pragya_test.h"
#include <stdint.h>

volatile int32_t a, b;
volatile uint32_t ua, ub;
volatile int result;

int main(void)
{
    a = 10;
    b = 20;

    ua = 10;
    ub = 20;

    result = 0;

    /*-----------------------------------------
      BEQ
    -----------------------------------------*/

    if(a == 10)
        result++;

    if(result != 1)
        test_fail();

    /*-----------------------------------------
      BNE
    -----------------------------------------*/

    if(a != b)
        result++;

    if(result != 2)
        test_fail();

    /*-----------------------------------------
      BLT
    -----------------------------------------*/

    if(a < b)
        result++;

    if(result != 3)
        test_fail();

    /*-----------------------------------------
      BGE
    -----------------------------------------*/

    if(b >= a)
        result++;

    if(result != 4)
        test_fail();

    /*-----------------------------------------
      BLTU
    -----------------------------------------*/

    if(ua < ub)
        result++;

    if(result != 5)
        test_fail();

    /*-----------------------------------------
      BGEU
    -----------------------------------------*/

    if(ub >= ua)
        result++;

    if(result != 6)
        test_fail();

    /*-----------------------------------------
      Negative comparisons
    -----------------------------------------*/

    if(a == b)
        test_fail();

    if(b < a)
        test_fail();

    if(ua > ub)
        test_fail();

    /*-----------------------------------------
      Loop (extra branch coverage)
    -----------------------------------------*/

    int sum = 0;

    for(int i = 0; i < 10; i++)
        sum += i;

    if(sum != 45)
        test_fail();

    test_pass();

    return 0;
}