#include "pragya_test.h"
#include <stdint.h>

volatile int result;

/*-----------------------------------------
  Level 3
-----------------------------------------*/
int level3(int x)
{
    return x + 3;
}

/*-----------------------------------------
  Level 2
-----------------------------------------*/
int level2(int x)
{
    int y;

    y = level3(x);

    return y * 2;
}

/*-----------------------------------------
  Level 1
-----------------------------------------*/
int level1(int x)
{
    int y;

    y = level2(x);

    return y - 5;
}

/*-----------------------------------------
  Recursive Function
-----------------------------------------*/
int sum(int n)
{
    if(n == 0)
        return 0;

    return n + sum(n-1);
}

/*-----------------------------------------
  Main
-----------------------------------------*/
int main(void)
{
    result = level1(10);

    /*
        level3(10)=13
        level2=26
        level1=21
    */

    if(result != 21)
        test_fail();

    result = level1(5);

    /*
        level3=8
        level2=16
        level1=11
    */

    if(result != 11)
        test_fail();

    result = sum(10);

    if(result != 55)
        test_fail();

    /* Multiple direct calls */

    if(level3(7) != 10)
        test_fail();

    if(level2(4) != 14)
        test_fail();

    if(level1(8) != 17)
        test_fail();

    test_pass();

    return 0;
}