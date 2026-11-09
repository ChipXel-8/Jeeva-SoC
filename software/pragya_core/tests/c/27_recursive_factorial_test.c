#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t result[9];

/* Recursive factorial */
uint32_t factorial(uint32_t n)
{
    if(n <= 1)
        return 1;

    return n * factorial(n - 1);
}

int main(void)
{
    uint32_t i;

    /* Calculate factorials */
    for(i = 0; i <= 8; i++)
    {
        result[i] = factorial(i);
    }

    /* Verify results */

    if(result[0] != 1)
        test_fail();

    if(result[1] != 1)
        test_fail();

    if(result[2] != 2)
        test_fail();

    if(result[3] != 6)
        test_fail();

    if(result[4] != 24)
        test_fail();

    if(result[5] != 120)
        test_fail();

    if(result[6] != 720)
        test_fail();

    if(result[7] != 5040)
        test_fail();

    if(result[8] != 40320)
        test_fail();

    /* Additional checks */

    if(result[8] <= result[7])
        test_fail();

    if(result[6] != 6 * result[5])
        test_fail();

    test_pass();

    return 0;
}