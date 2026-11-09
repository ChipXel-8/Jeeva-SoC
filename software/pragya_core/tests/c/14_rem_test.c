#include "pragya_test.h"
#include <stdint.h>

volatile int32_t  s1, s2;
volatile uint32_t u1, u2;
volatile int32_t  rem_result;
volatile uint32_t remu_result;

int main(void)
{
    /*-----------------------------------------
      REM : Positive % Positive
    -----------------------------------------*/

    s1 = 25;
    s2 = 7;

    rem_result = s1 % s2;

    if(rem_result != 4)
        test_fail();

    /*-----------------------------------------
      REM : Negative % Positive
    -----------------------------------------*/

    s1 = -25;
    s2 = 7;

    rem_result = s1 % s2;

    if(rem_result != -4)
        test_fail();

    /*-----------------------------------------
      REM : Positive % Negative
    -----------------------------------------*/

    s1 = 25;
    s2 = -7;

    rem_result = s1 % s2;

    if(rem_result != 4)
        test_fail();

    /*-----------------------------------------
      REM : Negative % Negative
    -----------------------------------------*/

    s1 = -25;
    s2 = -7;

    rem_result = s1 % s2;

    if(rem_result != -4)
        test_fail();

    /*-----------------------------------------
      REM : Exact Division
    -----------------------------------------*/

    s1 = 40;
    s2 = 5;

    rem_result = s1 % s2;

    if(rem_result != 0)
        test_fail();

    /*-----------------------------------------
      REMU
    -----------------------------------------*/

    u1 = 100;
    u2 = 30;

    asm volatile(
        "remu %0, %1, %2"
        : "=r"(remu_result)
        : "r"(u1), "r"(u2)
    );

    if(remu_result != 10)
        test_fail();

    /*-----------------------------------------
      Large Unsigned
    -----------------------------------------*/

    u1 = 0xFFFFFFFF;
    u2 = 256;

    asm volatile(
        "remu %0, %1, %2"
        : "=r"(remu_result)
        : "r"(u1), "r"(u2)
    );

    if(remu_result != 255)
        test_fail();

    /*-----------------------------------------
      Loop
    -----------------------------------------*/

    for(int i=1;i<=10;i++)
    {
        if((100%i)!=(100%i))
            test_fail();
    }

    test_pass();

    return 0;
}