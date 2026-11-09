#include "pragya_test.h"
#include <stdint.h>

volatile int arr[10] =
{
    45, 12, 89, 3, 56,
    78, 34, 23, 90, 1
};

void swap(volatile int *a, volatile int *b)
{
    int t = *a;
    *a = *b;
    *b = t;
}

int partition(int low, int high)
{
    int pivot = arr[high];
    int i = low - 1;

    for(int j = low; j < high; j++)
    {
        if(arr[j] < pivot)
        {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }

    swap(&arr[i + 1], &arr[high]);

    return i + 1;
}

void quicksort(int low, int high)
{
    if(low < high)
    {
        int pi = partition(low, high);

        quicksort(low, pi - 1);
        quicksort(pi + 1, high);
    }
}

int main(void)
{
    quicksort(0, 9);

    /* Verify ascending order */

    for(int i = 0; i < 9; i++)
    {
        if(arr[i] > arr[i + 1])
            test_fail();
    }

    /* Verify exact values */

    if(arr[0] != 1)   test_fail();
    if(arr[1] != 3)   test_fail();
    if(arr[2] != 12)  test_fail();
    if(arr[3] != 23)  test_fail();
    if(arr[4] != 34)  test_fail();
    if(arr[5] != 45)  test_fail();
    if(arr[6] != 56)  test_fail();
    if(arr[7] != 78)  test_fail();
    if(arr[8] != 89)  test_fail();
    if(arr[9] != 90)  test_fail();

    test_pass();

    return 0;
}