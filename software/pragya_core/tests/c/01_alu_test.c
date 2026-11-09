#include "pragya_test.h"
#include <stdint.h>

int main(void)
{
    volatile int a = 10;
    volatile int b = 20;
    volatile int result;

    /* ADD */
    result = a + b;
    if(result != 30)
        test_fail();

    /* SUB */
    result = b - a;
    if(result != 10)
        test_fail();

    /* AND */
    result = a & b;
    if(result != (10 & 20))
        test_fail();

    /* OR */
    result = a | b;
    if(result != (10 | 20))
        test_fail();

    /* XOR */
    result = a ^ b;
    if(result != 30)
        test_fail();

    /* SLL */
    result = 1 << 5;
    if(result != 32)
        test_fail();

    /* SRL */
    result = 32 >> 2;
    if(result != 8)
        test_fail();

    /* SRA */
    result = (-16) >> 2;
    if(result != -4)
        test_fail();

    /* SLT */
    result = (5 < 10);
    if(result != 1)
        test_fail();

    result = (10 < 5);
    if(result != 0)
        test_fail();

    /* SLTU */
    {
        volatile unsigned int ua = 1;
        volatile unsigned int ub = 2;

        result = (ua < ub);
        if(result != 1)
            test_fail();
    }

    /* ADDI */
    result = a + 15;
    if(result != 25)
        test_fail();

    /* ANDI */
    result = a & 7;
    if(result != (10 & 7))
        test_fail();

    /* ORI */
    result = a | 3;
    if(result != (10 | 3))
        test_fail();

    /* XORI */
    result = a ^ 15;
    if(result != 5)
        test_fail();

    /* SLLI */
    result = 3 << 4;
    if(result != 48)
        test_fail();

    /* SRLI */
    result = 64 >> 3;
    if(result != 8)
        test_fail();

    /* SRAI */
    result = (-32) >> 3;
    if(result != -4)
        test_fail();

    /* SLTI */
    result = (8 < 20);
    if(result != 1)
        test_fail();

    /* SLTIU */
    {
        volatile unsigned int ux = 8;
        result = (ux < 20U);
        if(result != 1)
            test_fail();
    }

    test_pass();
    return 0;
}
