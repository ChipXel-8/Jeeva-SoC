#include "pragya_test.h"
#include <stdint.h>

volatile int32_t a, b;
volatile int32_t result;

int main(void)
{
    /*-----------------------------------------
      Positive / Positive
    -----------------------------------------*/

    a = 100;
    b = 5;

    result = a / b;

    if(result != 20)
        test_fail();

    /*-----------------------------------------
      Positive / Negative
    -----------------------------------------*/

    a = 100;
    b = -5;

    result = a / b;

    if(result != -20)
        test_fail();

    /*-----------------------------------------
      Negative / Positive
    -----------------------------------------*/

    a = -100;
    b = 5;

    result = a / b;

    if(result != -20)
        test_fail();

    /*-----------------------------------------
      Negative / Negative
    -----------------------------------------*/

    a = -100;
    b = -5;

    result = a / b;

    if(result != 20)
        test_fail();

    /*-----------------------------------------
      Divide by One
    -----------------------------------------*/

    a = 12345;
    b = 1;

    result = a / b;

    if(result != 12345)
        test_fail();

    /*-----------------------------------------
      Divide by Minus One
    -----------------------------------------*/

    a = 12345;
    b = -1;

    result = a / b;

    if(result != -12345)
        test_fail();

    /*-----------------------------------------
      Zero Dividend
    -----------------------------------------*/

    a = 0;
    b = 99;

    result = a / b;

    if(result != 0)
        test_fail();

    /*-----------------------------------------
      Large Numbers
    -----------------------------------------*/

    a = 2147483647;
    b = 1024;

    result = a / b;

    if(result != 2097151)
        test_fail();

    /*-----------------------------------------
      Chained Divide
    -----------------------------------------*/

    result = 1024;

    result /= 2;
    result /= 2;
    result /= 2;
    result /= 2;

    if(result != 64)
        test_fail();

    test_pass();

    return 0;
}