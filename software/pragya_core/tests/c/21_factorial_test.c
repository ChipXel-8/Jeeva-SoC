#include "pragya_test.h"
#include <stdint.h>

/*
 * Directed Factorial Verification Test
 * Covers:
 *  - Multiplication
 *  - Loop execution
 *  - Branches
 *  - Memory stores
 *  - Comparisons
 */

volatile uint32_t fact_result[8];

int main(void)
{
    uint32_t fact = 1;
    uint32_t i;

    /* Calculate factorials 1! to 8! */
    for(i = 1; i <= 8; i++)
    {
        fact = fact * i;
        fact_result[i - 1] = fact;
    }

    /* Verify every factorial value */

    if(fact_result[0] != 1)
        test_fail();

    if(fact_result[1] != 2)
        test_fail();

    if(fact_result[2] != 6)
        test_fail();

    if(fact_result[3] != 24)
        test_fail();

    if(fact_result[4] != 120)
        test_fail();

    if(fact_result[5] != 720)
        test_fail();

    if(fact_result[6] != 5040)
        test_fail();

    if(fact_result[7] != 40320)
        test_fail();

    /* Extra check */

    if(fact != 40320)
        test_fail();

    test_pass();

    return 0;
}