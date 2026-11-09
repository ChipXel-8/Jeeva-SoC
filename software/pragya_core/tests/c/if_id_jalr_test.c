#include "pragya_test.h"
#include <stdint.h>

volatile int signature[16];

static int function1(int x)
{
    return x+10;
}

static int function2(int x)
{
    return x+20;
}

static int function3(int x)
{
    return x+30;
}

int main(void)
{
    int (*func)(int);

    /*------------------------------------------
      Initialize
    ------------------------------------------*/

    for(int k=0;k<16;k++)
        signature[k]=0;

    /*------------------------------------------
      JALR Function Call 1
    ------------------------------------------*/

    func=function1;

    signature[0]=func(10);

    /*------------------------------------------
      JALR Function Call 2
    ------------------------------------------*/

    func=function2;

    signature[1]=func(20);

    /*------------------------------------------
      JALR Function Call 3
    ------------------------------------------*/

    func=function3;

    signature[2]=func(30);

    /*------------------------------------------
      Multiple Indirect Calls
    ------------------------------------------*/

    for(int k=0;k<10;k++)
    {
        if(k%3==0)
            func=function1;

        else if(k%3==1)
            func=function2;

        else
            func=function3;

        signature[3]=func(k);
    }

    /*------------------------------------------
      Verify
    ------------------------------------------*/

    if(signature[0]!=20)
        test_fail();

    if(signature[1]!=40)
        test_fail();

    if(signature[2]!=60)
        test_fail();

    test_pass();

    return 0;
}