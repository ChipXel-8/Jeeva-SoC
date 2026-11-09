#include "pragya_test.h"
#include <stdint.h>

#define N 100

volatile uint8_t prime[N + 1];
volatile uint32_t prime_count;
volatile uint32_t prime_sum;

int main(void)
{
    uint32_t i, j;

    /* Initialize */
    for(i = 0; i <= N; i++)
        prime[i] = 1;

    prime[0] = 0;
    prime[1] = 0;

    /* Sieve of Eratosthenes */
    for(i = 2; i * i <= N; i++)
    {
        if(prime[i])
        {
            for(j = i * i; j <= N; j += i)
                prime[j] = 0;
        }
    }

    /* Count primes and compute sum */
    prime_count = 0;
    prime_sum   = 0;

    for(i = 2; i <= N; i++)
    {
        if(prime[i])
        {
            prime_count++;
            prime_sum += i;
        }
    }

    /* Verify prime count */
    if(prime_count != 25)
        test_fail();

    /* Verify sum of primes */
    if(prime_sum != 1060)
        test_fail();

    /* Verify prime numbers */
    if(prime[2]  != 1) test_fail();
    if(prime[3]  != 1) test_fail();
    if(prime[5]  != 1) test_fail();
    if(prime[7]  != 1) test_fail();
    if(prime[11] != 1) test_fail();
    if(prime[13] != 1) test_fail();
    if(prime[17] != 1) test_fail();
    if(prime[19] != 1) test_fail();
    if(prime[97] != 1) test_fail();

    /* Verify non-prime numbers */
    if(prime[4]  != 0) test_fail();
    if(prime[6]  != 0) test_fail();
    if(prime[8]  != 0) test_fail();
    if(prime[9]  != 0) test_fail();
    if(prime[10] != 0) test_fail();
    if(prime[12] != 0) test_fail();
    if(prime[15] != 0) test_fail();
    if(prime[20] != 0) test_fail();
    if(prime[100] != 0) test_fail();

    /* Additional sanity checks */
    if(prime_count < 20)
        test_fail();

    if(prime_sum <= 1000)
        test_fail();

    test_pass();

    return 0;
}