#include "pragya_test.h"
#include <stdint.h>

/*
 * Directed Matrix Multiplication Verification Test
 *
 * C = A × B
 *
 * Expected:
 * 19 22
 * 43 50
 */

volatile int32_t A[2][2] =
{
    {1,2},
    {3,4}
};

volatile int32_t B[2][2] =
{
    {5,6},
    {7,8}
};

volatile int32_t C[2][2];

int main(void)
{
    int i,j,k;

    /* Matrix Multiplication */

    for(i=0;i<2;i++)
    {
        for(j=0;j<2;j++)
        {
            C[i][j]=0;

            for(k=0;k<2;k++)
            {
                C[i][j]+=A[i][k]*B[k][j];
            }
        }
    }

    /* Verify Results */

    if(C[0][0] != 19)
        test_fail();

    if(C[0][1] != 22)
        test_fail();

    if(C[1][0] != 43)
        test_fail();

    if(C[1][1] != 50)
        test_fail();

    /* Additional sanity checks */

    if(C[0][0] + C[1][1] != 69)
        test_fail();

    if(C[0][1] + C[1][0] != 65)
        test_fail();

    test_pass();

    return 0;
}