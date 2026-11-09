#include "pragya_test.h"
#include <stdint.h>

/*
 * Directed Sorted Array Verification Test
 *
 * Checks if an array is already sorted.
 */

volatile int arr[10] =
{
    1,2,3,4,5,
    6,7,8,9,10
};

volatile int sorted;

int main(void)
{
    int i;

    sorted = 1;

    /* Check sorted order */

    for(i = 0; i < 9; i++)
    {
        if(arr[i] > arr[i + 1])
        {
            sorted = 0;
            break;
        }
    }

    /* Verify */

    if(sorted != 1)
        test_fail();

    /* Verify first element */

    if(arr[0] != 1)
        test_fail();

    /* Verify middle element */

    if(arr[4] != 5)
        test_fail();

    /* Verify last element */

    if(arr[9] != 10)
        test_fail();

    /* Additional checks */

    if(arr[0] >= arr[9])
        test_fail();

    if(arr[3] >= arr[4])
        test_fail();

    if(arr[8] >= arr[9])
        test_fail();

    test_pass();

    return 0;
}