#include "pragya_test.h"
#include <stdint.h>

volatile int32_t  s1, s2;
volatile uint32_t u1, u2;

volatile int32_t  mul;
volatile int32_t  mulh;
volatile int32_t  mulhsu;
volatile uint32_t mulhu;

volatile int32_t  div;
volatile uint32_t divu;

volatile int32_t  rem;
volatile uint32_t remu;

int main(void)
{
    s1 = 12345;
    s2 = -67;

    u1 = 12345;
    u2 = 67;

    /*-----------------------------------------
      MUL
    -----------------------------------------*/

    asm volatile(
        "mul %0,%1,%2"
        : "=r"(mul)
        : "r"(s1),"r"(s2)
    );

    if(mul != (12345 * -67))
        test_fail();

    /*-----------------------------------------
      MULH
    -----------------------------------------*/

    asm volatile(
        "mulh %0,%1,%2"
        : "=r"(mulh)
        : "r"(s1),"r"(s2)
    );

    /*-----------------------------------------
      MULHSU
    -----------------------------------------*/

    asm volatile(
        "mulhsu %0,%1,%2"
        : "=r"(mulhsu)
        : "r"(s1),"r"(u2)
    );

    /*-----------------------------------------
      MULHU
    -----------------------------------------*/

    asm volatile(
        "mulhu %0,%1,%2"
        : "=r"(mulhu)
        : "r"(u1),"r"(u2)
    );

    /*-----------------------------------------
      DIV
    -----------------------------------------*/

    asm volatile(
        "div %0,%1,%2"
        : "=r"(div)
        : "r"(s1),"r"(s2)
    );

    if(div != (12345 / -67))
        test_fail();

    /*-----------------------------------------
      DIVU
    -----------------------------------------*/

    asm volatile(
        "divu %0,%1,%2"
        : "=r"(divu)
        : "r"(u1),"r"(u2)
    );

    if(divu != (12345U / 67U))
        test_fail();

    /*-----------------------------------------
      REM
    -----------------------------------------*/

    asm volatile(
        "rem %0,%1,%2"
        : "=r"(rem)
        : "r"(s1),"r"(s2)
    );

    if(rem != (12345 % -67))
        test_fail();

    /*-----------------------------------------
      REMU
    -----------------------------------------*/

    asm volatile(
        "remu %0,%1,%2"
        : "=r"(remu)
        : "r"(u1),"r"(u2)
    );

    if(remu != (12345U % 67U))
        test_fail();

    /*-----------------------------------------
      Dependency Chain
    -----------------------------------------*/

    mul += div;
    mul ^= rem;
    mul += remu;
    mul += divu;

    if(mul == 0)
        test_fail();

    /*-----------------------------------------
      Loop Stress
    -----------------------------------------*/

    for(int i=1;i<=20;i++)
    {
        volatile int x=i*17;
        volatile int y=i+3;

        volatile int a=x*y;
        volatile int b=x/y;
        volatile int c=x%y;

        if(a==0)
            test_fail();

        if(b<0)
            test_fail();

        if(c>=y)
            test_fail();
    }

    test_pass();

    return 0;
}