#include "pragya_test.h"
#include <stdint.h>

/*
 * Directed Fibonacci Verification Test
 *
 * Expected sequence:
 * 0 1 1 2 3 5 8 13 21 34
 */

volatile uint32_t fib[10];

int main(void)
{
    uint32_t i;

    fib[0] = 0;
    fib[1] = 1;

    /* Generate Fibonacci sequence */
    for(i = 2; i < 10; i++)
    {
        fib[i] = fib[i-1] + fib[i-2];
    }

    /* Verify results */

    if(fib[0] != 0)   test_fail();
    if(fib[1] != 1)   test_fail();
    if(fib[2] != 1)   test_fail();
    if(fib[3] != 2)   test_fail();
    if(fib[4] != 3)   test_fail();
    if(fib[5] != 5)   test_fail();
    if(fib[6] != 8)   test_fail();
    if(fib[7] != 13)  test_fail();
    if(fib[8] != 21)  test_fail();
    if(fib[9] != 34)  test_fail();

    test_pass();

    return 0;
}