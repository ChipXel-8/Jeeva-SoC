#include "pragya_test.h"
#include <stdint.h>

volatile int r0,r1,r2,r3,r4,r5,r6,r7,r8,r9;
volatile int r10,r11,r12,r13,r14,r15;
volatile int result;

int main(void)
{
    r0  = 1;
    r1  = 2;
    r2  = 3;
    r3  = 4;
    r4  = 5;
    r5  = 6;
    r6  = 7;
    r7  = 8;
    r8  = 9;
    r9  = 10;
    r10 = 11;
    r11 = 12;
    r12 = 13;
    r13 = 14;
    r14 = 15;
    r15 = 16;

    /* Arithmetic */

    result =
        r0+r1+r2+r3+
        r4+r5+r6+r7+
        r8+r9+r10+r11+
        r12+r13+r14+r15;

    if(result != 136)
        test_fail();

    /* Logical */

    result = r0&r1;
    result |= r2;
    result ^= r3;

    if(result != (((1&2)|3)^4))
        test_fail();

    /* Shifts */

    result = r5<<2;

    if(result != 24)
        test_fail();

    result >>=2;

    if(result != 6)
        test_fail();

    /* Multiply */

    result = r8*r9;

    if(result != 90)
        test_fail();

    /* Divide */

    result = r15/r3;

    if(result != 4)
        test_fail();

    /* Modulo */

    result = r15%r3;

    if(result != 0)
        test_fail();

    /* Comparisons */

    if(r15<=r14)
        test_fail();

    if(r0>=r1)
        test_fail();

    /* Long dependency chain */

    result =
        r0+r1;
    result+=r2;
    result+=r3;
    result+=r4;
    result+=r5;
    result+=r6;
    result+=r7;
    result+=r8;
    result+=r9;
    result+=r10;
    result+=r11;
    result+=r12;
    result+=r13;
    result+=r14;
    result+=r15;

    if(result!=136)
        test_fail();

    test_pass();

    return 0;
}