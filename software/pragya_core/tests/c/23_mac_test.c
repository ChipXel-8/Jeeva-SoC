#include "pragya_test.h"
#include <stdint.h>

/*
 * Directed MAC (Multiply-Accumulate) Verification Test
 *
 * Computes:
 * result = Σ (A[i] * B[i])
 *
 * Expected Result:
 * 1*8 + 2*7 + 3*6 + 4*5 + 5*4 + 6*3 + 7*2 + 8*1 = 120
 */

volatile int32_t A[8] = {1,2,3,4,5,6,7,8};
volatile int32_t B[8] = {8,7,6,5,4,3,2,1};

volatile int32_t mac_result;

int main(void)
{
    int i;

    mac_result = 0;

    for(i = 0; i < 8; i++)
    {
        mac_result += A[i] * B[i];
    }

    /* Verify MAC result */

    if(mac_result != 120)
        test_fail();

    /* Individual sanity checks */

    if(A[0] * B[0] != 8)
        test_fail();

    if(A[3] * B[3] != 20)
        test_fail();

    if(A[7] * B[7] != 8)
        test_fail();

    test_pass();

    return 0;
}