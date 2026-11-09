#include "pragya_test.h"
#include <stdint.h>

volatile int a,b,c,d,e,f,g,h;
volatile unsigned ua,ub,uc;

int main(void)
{
    /*------------------------------------------
      MUL Special Values
    ------------------------------------------*/

    a = 0;
    b = 1234;

    if(a*b != 0)
        test_fail();

    a = 1;
    b = 5678;

    if(a*b != 5678)
        test_fail();

    a = -1;
    b = 123;

    if(a*b != -123)
        test_fail();

    a = -10;
    b = -20;

    if(a*b != 200)
        test_fail();

    a = 32767;
    b = 32767;

    c = a*b;

    if(c != 1073676289)
        test_fail();

    /*------------------------------------------
      DIV Special Values
    ------------------------------------------*/

    a = 100;
    b = 5;

    if(a/b != 20)
        test_fail();

    a = -100;
    b = 5;

    if(a/b != -20)
        test_fail();

    a = 100;
    b = -5;

    if(a/b != -20)
        test_fail();

    a = -100;
    b = -5;

    if(a/b != 20)
        test_fail();

    /*------------------------------------------
      REM Special Values
    ------------------------------------------*/

    a = 101;
    b = 10;

    if(a%b != 1)
        test_fail();

    a = -101;
    b = 10;

    if(a%b != -1)
        test_fail();

    a = 101;
    b = -10;

    if(a%b != 1)
        test_fail();

    a = -101;
    b = -10;

    if(a%b != -1)
        test_fail();

    /*------------------------------------------
      Unsigned Division
    ------------------------------------------*/

    ua = 100;
    ub = 3;

    uc = ua/ub;

    if(uc != 33)
        test_fail();

    uc = ua%ub;

    if(uc != 1)
        test_fail();

    /*------------------------------------------
      RAW Dependency
    ------------------------------------------*/

    a = 12;

    b = a * 5;
    c = b / 3;
    d = c % 7;
    e = d * 11;
    f = e / 2;

    if(f != 22)
        test_fail();

    /*------------------------------------------
      Continuous M Operations
    ------------------------------------------*/

    a = 2;

    for(int i=1;i<=20;i++)
    {
        a = a * i;
        a = a / i;
    }

    if(a != 2)
        test_fail();

    /*------------------------------------------
      Mixed MUL DIV REM
    ------------------------------------------*/

    a = 55;

    b = a * 4;
    c = b / 5;
    d = c % 8;
    e = d * 7;
    f = e / 2;
    g = f % 5;

    if(g != 1)
        test_fail();

    /*------------------------------------------
      Stress Loop
    ------------------------------------------*/

    a = 12345;

    for(int i=1;i<50;i++)
    {
        a = a * 3;
        a = a / 3;
        a = a % 100000;
    }

    if(a <= 0)
        test_fail();

    test_pass();

    return 0;
}
