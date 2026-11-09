#include "pragya_test.h"
#include <stdint.h>

volatile int32_t  s1, s2;
volatile uint32_t u1, u2;

volatile int32_t  mul_r;
volatile int32_t  mulh_r;
volatile int32_t  mulhsu_r;
volatile uint32_t mulhu_r;

volatile int32_t  div_r;
volatile uint32_t divu_r;
volatile int32_t  rem_r;
volatile uint32_t remu_r;

int main(void)
{
    //--------------------------------------------------
    // Positive numbers
    //--------------------------------------------------

    s1 = 123456;
    s2 = 321;

    u1 = 0x87654321;
    u2 = 12345;

    //--------------------------------------------------
    // MUL
    //--------------------------------------------------

    asm volatile(
        "mul %0,%1,%2"
        : "=r"(mul_r)
        : "r"(s1), "r"(s2)
    );

    //--------------------------------------------------
    // MULH
    //--------------------------------------------------

    asm volatile(
        "mulh %0,%1,%2"
        : "=r"(mulh_r)
        : "r"(s1), "r"(s2)
    );

    //--------------------------------------------------
    // MULHSU
    //--------------------------------------------------

    asm volatile(
        "mulhsu %0,%1,%2"
        : "=r"(mulhsu_r)
        : "r"(s1), "r"(u2)
    );

    //--------------------------------------------------
    // MULHU
    //--------------------------------------------------

    asm volatile(
        "mulhu %0,%1,%2"
        : "=r"(mulhu_r)
        : "r"(u1), "r"(u2)
    );

    //--------------------------------------------------
    // DIV
    //--------------------------------------------------

    asm volatile(
        "div %0,%1,%2"
        : "=r"(div_r)
        : "r"(s1), "r"(s2)
    );

    //--------------------------------------------------
    // DIVU
    //--------------------------------------------------

    asm volatile(
        "divu %0,%1,%2"
        : "=r"(divu_r)
        : "r"(u1), "r"(u2)
    );

    //--------------------------------------------------
    // REM
    //--------------------------------------------------

    asm volatile(
        "rem %0,%1,%2"
        : "=r"(rem_r)
        : "r"(s1), "r"(s2)
    );

    //--------------------------------------------------
    // REMU
    //--------------------------------------------------

    asm volatile(
        "remu %0,%1,%2"
        : "=r"(remu_r)
        : "r"(u1), "r"(u2)
    );

    //--------------------------------------------------
    // Repeat several times with different operands
    //--------------------------------------------------

    for(int i=1;i<=40;i++)
    {
        s1 = 1000*i + 7;
        s2 = i + 3;

        u1 = 0x80000000u + i;
        u2 = i + 5;

        asm volatile("mul    %0,%1,%2" : "=r"(mul_r)    : "r"(s1),"r"(s2));
        asm volatile("mulh   %0,%1,%2" : "=r"(mulh_r)   : "r"(s1),"r"(s2));
        asm volatile("mulhsu %0,%1,%2" : "=r"(mulhsu_r) : "r"(s1),"r"(u2));
        asm volatile("mulhu  %0,%1,%2" : "=r"(mulhu_r)  : "r"(u1),"r"(u2));

        asm volatile("div    %0,%1,%2" : "=r"(div_r)    : "r"(s1),"r"(s2));
        asm volatile("divu   %0,%1,%2" : "=r"(divu_r)   : "r"(u1),"r"(u2));

        asm volatile("rem    %0,%1,%2" : "=r"(rem_r)    : "r"(s1),"r"(s2));
        asm volatile("remu   %0,%1,%2" : "=r"(remu_r)   : "r"(u1),"r"(u2));
    }

    //--------------------------------------------------
    // Basic sanity
    //--------------------------------------------------

    if(div_r != (s1 / s2))
        test_fail();

    if(rem_r != (s1 % s2))
        test_fail();

    if(divu_r != (u1 / u2))
        test_fail();

    if(remu_r != (u1 % u2))
        test_fail();

    test_pass();

    return 0;
}
