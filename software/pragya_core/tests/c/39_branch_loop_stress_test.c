#include "pragya_test.h"
#include <stdint.h>

volatile int i,j,k;
volatile int sum;
volatile int matrix[16][16];

int main(void)
{
    /*------------------------------------------
      Long Backward Loop
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<100;i++)
    {
        sum += i;
    }

    if(sum != 4950)
        test_fail();

    /*------------------------------------------
      Reverse Loop
    ------------------------------------------*/

    sum = 0;

    for(i=100;i>0;i--)
    {
        sum += i;
    }

    if(sum != 5050)
        test_fail();

    /*------------------------------------------
      Even / Odd Branch
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<100;i++)
    {
        if(i & 1)
            sum++;
        else
            sum--;
    }

    if(sum != 0)
        test_fail();

    /*------------------------------------------
      Triple Nested Loop
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<5;i++)
    {
        for(j=0;j<5;j++)
        {
            for(k=0;k<5;k++)
            {
                sum += i + j + k;
            }
        }
    }

    if(sum != 750)
        test_fail();

    /*------------------------------------------
      Continue Branch
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<50;i++)
    {
        if(i%3==0)
            continue;

        sum += i;
    }

    if(sum != 817)
        test_fail();

    /*------------------------------------------
      Break Branch
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<100;i++)
    {
        if(i==40)
            break;

        sum += i;
    }

    if(sum != 780)
        test_fail();

    /*------------------------------------------
      Mixed Branches
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<30;i++)
    {
        if(i<10)
            sum+=1;
        else if(i<20)
            sum+=2;
        else
            sum+=3;
    }

    if(sum != 60)
        test_fail();

    /*------------------------------------------
      Matrix Traversal
    ------------------------------------------*/

    for(i=0;i<16;i++)
    {
        for(j=0;j<16;j++)
        {
            matrix[i][j]=i+j;
        }
    }

    sum=0;

    for(i=0;i<16;i++)
    {
        for(j=0;j<16;j++)
        {
            sum+=matrix[i][j];
        }
    }

    if(sum!=3840)
        test_fail();

    /*------------------------------------------
      Dependency Loop
    ------------------------------------------*/

    sum=1;

    for(i=1;i<100;i++)
    {
        sum=sum+i;
        sum=sum-1;
        sum=sum+2;
        sum=sum^i;
    }

    if(sum==0)
        test_fail();

    test_pass();

    return 0;
}
