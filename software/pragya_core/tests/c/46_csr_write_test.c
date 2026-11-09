#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t old_val;
volatile uint32_t temp;

#define MSIE   0x00000008
#define MTIE   0x00000080
#define MEIE   0x00000800
#define ALL_IE (MSIE | MTIE | MEIE)

int main(void)
{
    /*------------------------------------------
      CSRRW
    ------------------------------------------*/

    asm volatile(
        "csrrw %0, mie, %1"
        : "=r"(old_val)
        : "r"(ALL_IE)
    );

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    if(temp != ALL_IE)
        test_fail();

    /*------------------------------------------
      CSRRS
      Set MTIE (already set, value unchanged)
    ------------------------------------------*/

    asm volatile(
        "csrrs %0, mie, %1"
        : "=r"(old_val)
        : "r"(MTIE)
    );

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    if(temp != ALL_IE)
        test_fail();

    /*------------------------------------------
      CSRRC
      Clear MTIE
    ------------------------------------------*/

    asm volatile(
        "csrrc %0, mie, %1"
        : "=r"(old_val)
        : "r"(MTIE)
    );

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    if(temp != (MSIE | MEIE))
        test_fail();

    /*------------------------------------------
      CSRRWI
      Write only MSIE
    ------------------------------------------*/

    asm volatile(
        "csrrwi %0, mie, 8"
        : "=r"(old_val)
    );

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    if(temp != MSIE)
        test_fail();

    /*------------------------------------------
      CSRRS
      Set MEIE
    ------------------------------------------*/

    asm volatile(
        "csrrs %0, mie, %1"
        : "=r"(old_val)
        : "r"(MEIE)
    );

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    if(temp != (MSIE | MEIE))
        test_fail();

    /*------------------------------------------
      CSRRC
      Clear MSIE
    ------------------------------------------*/

    asm volatile(
        "csrrc %0, mie, %1"
        : "=r"(old_val)
        : "r"(MSIE)
    );

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    if(temp != MEIE)
        test_fail();

    /*------------------------------------------
      Dependency Chain
    ------------------------------------------*/

    asm volatile(
        "csrr %0, mie"
        : "=r"(temp)
    );

    temp = temp + 1;
    temp = temp + 2;
    temp = temp + 3;
    temp = temp + 4;
    temp = temp + 5;

    if(temp != (MEIE + 15))
        test_fail();

    test_pass();

    return 0;
}
