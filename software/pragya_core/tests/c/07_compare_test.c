#include "pragya_test.h"
#include <stdint.h>

volatile int32_t  s1, s2;
volatile uint32_t u1, u2;
volatile int result;

int main(void)
{
    result = 0;

    /*--------------------------------------------------
      Signed Comparisons (SLT / SLTI)
    --------------------------------------------------*/

    s1 = -10;
    s2 = 20;

    if(s1 < s2)
        result++;
    else
        test_fail();

    if(s2 > s1)
        result++;
    else
        test_fail();

    if(s1 <= -10)
        result++;
    else
        test_fail();

    if(s2 >= 20)
        result++;
    else
        test_fail();

    /*--------------------------------------------------
      Equality
    --------------------------------------------------*/

    if(s1 != s2)
        result++;
    else
        test_fail();

    if(s1 == -10)
        result++;
    else
        test_fail();

    /*--------------------------------------------------
      Unsigned Comparisons (SLTU / SLTIU)
    --------------------------------------------------*/

    u1 = 5;
    u2 = 10;

    if(u1 < u2)
        result++;
    else
        test_fail();

    if(u2 > u1)
        result++;
    else
        test_fail();

    if(u2 >= 10)
        result++;
    else
        test_fail();

    if(u1 <= 5)
        result++;
    else
        test_fail();

    /*--------------------------------------------------
      Compare Against Zero
    --------------------------------------------------*/

    s1 = 0;

    if(s1 == 0)
        result++;
    else
        test_fail();

    if(!(s1 < 0))
        result++;
    else
        test_fail();

    /*--------------------------------------------------
      Large Numbers
    --------------------------------------------------*/

    s1 = 2147483647;
    s2 = -2147483647 - 1;

    if(s1 > s2)
        result++;
    else
        test_fail();

    u1 = 0xFFFFFFFF;
    u2 = 0x7FFFFFFF;

    if(u1 > u2)
        result++;
    else
        test_fail();

    /*--------------------------------------------------
      Verify Count
    --------------------------------------------------*/

    if(result != 14)
        test_fail();

    test_pass();

    return 0;
}