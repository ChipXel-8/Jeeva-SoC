#include "pragya_test.h"
#include <stdint.h>

volatile int32_t  s1, s2;
volatile uint32_t u1, u2;

volatile int32_t  mulh_result;
volatile uint32_t mulhu_result;
volatile int32_t  mulhsu_result;

int main(void)
{
    /*------------------------------------------
      MULH
      Signed × Signed (High 32 bits)
    ------------------------------------------*/

    s1 = 0x40000000;
    s2 = 8;

    asm volatile(
        "mulh %0, %1, %2"
        : "=r"(mulh_result)
        : "r"(s1), "r"(s2)
    );

    if(mulh_result != 2)
        test_fail();

    /*------------------------------------------
      MULHU
      Unsigned × Unsigned
    ------------------------------------------*/

    u1 = 0xFFFFFFFF;
    u2 = 0xFFFFFFFF;

    asm volatile(
        "mulhu %0, %1, %2"
        : "=r"(mulhu_result)
        : "r"(u1), "r"(u2)
    );

    if(mulhu_result != 0xFFFFFFFE)
        test_fail();

    /*------------------------------------------
      MULHSU
      Signed × Unsigned
    ------------------------------------------*/

    s1 = -2;
    u2 = 8;

    asm volatile(
        "mulhsu %0, %1, %2"
        : "=r"(mulhsu_result)
        : "r"(s1), "r"(u2)
    );

    if(mulhsu_result != -1)
        test_fail();

    /*------------------------------------------
      Additional Cases
    ------------------------------------------*/

    s1 = 12345678;
    s2 = 87654321;

    asm volatile(
        "mulh %0, %1, %2"
        : "=r"(mulh_result)
        : "r"(s1), "r"(s2)
    );

    u1 = 12345678;
    u2 = 87654321;

    asm volatile(
        "mulhu %0, %1, %2"
        : "=r"(mulhu_result)
        : "r"(u1), "r"(u2)
    );

    s1 = -12345678;
    u2 = 87654321;

    asm volatile(
        "mulhsu %0, %1, %2"
        : "=r"(mulhsu_result)
        : "r"(s1), "r"(u2)
    );

    test_pass();

    return 0;
}