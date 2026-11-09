#include "pragya_test.h"
#include <stdint.h>

volatile int arr[10] =
{
    64, 25, 12, 22, 11,
    90, 34, 56, 78, 3
};

void swap(volatile int *a, volatile int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

int main(void)
{
    int i, j, min;

    /* Selection Sort */

    for(i = 0; i < 9; i++)
    {
        min = i;

        for(j = i + 1; j < 10; j++)
        {
            if(arr[j] < arr[min])
                min = j;
        }

        if(min != i)
            swap(&arr[i], &arr[min]);
    }

    /* Verify ascending order */

    for(i = 0; i < 9; i++)
    {
        if(arr[i] > arr[i + 1])
            test_fail();
    }

    /* Verify exact sorted values */

    if(arr[0] != 3)   test_fail();
    if(arr[1] != 11)  test_fail();
    if(arr[2] != 12)  test_fail();
    if(arr[3] != 22)  test_fail();
    if(arr[4] != 25)  test_fail();
    if(arr[5] != 34)  test_fail();
    if(arr[6] != 56)  test_fail();
    if(arr[7] != 64)  test_fail();
    if(arr[8] != 78)  test_fail();
    if(arr[9] != 90)  test_fail();

    /* Additional sanity checks */

    if(arr[0] >= arr[9])
        test_fail();

    if(arr[4] != 25)
        test_fail();

    test_pass();

    return 0;
}