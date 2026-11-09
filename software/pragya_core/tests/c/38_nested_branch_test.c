#include "pragya_test.h"
#include <stdint.h>

volatile int i,j,k;
volatile int sum;
volatile int count;

int main(void)
{
    /*------------------------------------------
      Nested Loop
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<8;i++)
    {
        for(j=0;j<8;j++)
        {
            sum += i*j;
        }
    }

    if(sum != 784)
        test_fail();

    /*------------------------------------------
      Multiple Branches
    ------------------------------------------*/

    count = 0;

    for(i=0;i<30;i++)
    {
        if(i < 10)
        {
            count += 1;
        }
        else if(i < 20)
        {
            count += 2;
        }
        else
        {
            count += 3;
        }
    }

    if(count != 60)
        test_fail();

    /*------------------------------------------
      Signed Comparison
    ------------------------------------------*/

    sum = 0;

    for(i=-20;i<=20;i++)
    {
        if(i < 0)
            sum--;
        else
            sum++;
    }

    if(sum != 1)
        test_fail();

    /*------------------------------------------
      Unsigned Comparison
    ------------------------------------------*/

    uint32_t ua = 10;
    uint32_t ub = 20;

    if(ua < ub)
        sum = 100;
    else
        sum = 0;

    if(sum != 100)
        test_fail();

    /*------------------------------------------
      Branch Chain
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<50;i++)
    {
        if(i&1)
            sum++;

        if(i&2)
            sum++;

        if(i&4)
            sum++;

        if(i&8)
            sum++;

        if(i&16)
            sum++;
    }

    if(sum != 113)
        test_fail();

    /*------------------------------------------
      Deep Nested Branch
    ------------------------------------------*/

    count = 0;

    for(i=0;i<5;i++)
    {
        for(j=0;j<5;j++)
        {
            for(k=0;k<5;k++)
            {
                if(i==j)
                {
                    if(j==k)
                    {
                        count++;
                    }
                    else
                    {
                        count+=2;
                    }
                }
                else
                {
                    count+=3;
                }
            }
        }
    }

    if(count != 315)
        test_fail();

    /*------------------------------------------
      Forward / Backward Branch
    ------------------------------------------*/

    sum = 0;

    i = 0;

loop1:

    sum += i;

    i++;

    if(i < 20)
        goto loop1;

    if(sum != 190)
        test_fail();

    /*------------------------------------------
      Branch Stress
    ------------------------------------------*/

    sum = 0;

    for(i=0;i<100;i++)
    {
        if(i%3==0)
            sum+=3;
        else if(i%3==1)
            sum+=2;
        else
            sum+=1;
    }

    if(sum != 201)
        test_fail();

    test_pass();

    return 0;
}
