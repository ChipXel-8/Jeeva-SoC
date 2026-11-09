#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t old_val;
volatile uint32_t temp;
volatile uint32_t sum;

int main(void)
{
    /*------------------------------------------
      Initialize MIE = 0
    ------------------------------------------*/

    asm volatile(
        "csrrw zero, mie, zero"
    );

    /*------------------------------------------
      CSRRW Stress
    ------------------------------------------*/

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrrw %0, mie, %1"
            : "=r"(old_val)
            : "r"(8)
        );

        asm volatile(
            "csrr %0, mie"
            : "=r"(temp)
        );

        if(temp != 8)
            test_fail();
    }

    /*------------------------------------------
      CSRRS Stress
    ------------------------------------------*/

    asm volatile("csrrw zero,mie,zero");

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrrs %0,mie,%1"
            : "=r"(old_val)
            : "r"(8)
        );

        asm volatile(
            "csrr %0,mie"
            : "=r"(temp)
        );

        if(temp != 8)
            test_fail();
    }

    /*------------------------------------------
      CSRRC Stress
    ------------------------------------------*/

    asm volatile(
        "csrrw zero,mie,%0"
        :
        : "r"(8)
    );

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrrc %0,mie,%1"
            : "=r"(old_val)
            : "r"(8)
        );

        asm volatile(
            "csrr %0,mie"
            : "=r"(temp)
        );

        if(temp != 0)
            test_fail();
    }

    /*------------------------------------------
      CSRRWI Stress
    ------------------------------------------*/

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrrwi %0,mie,8"
            : "=r"(old_val)
        );

        asm volatile(
            "csrr %0,mie"
            : "=r"(temp)
        );

        if(temp != 8)
            test_fail();
    }

    /*------------------------------------------
      CSRRSI Stress
    ------------------------------------------*/

    asm volatile("csrrwi zero,mie,0");

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrrsi %0,mie,8"
            : "=r"(old_val)
        );

        asm volatile(
            "csrr %0,mie"
            : "=r"(temp)
        );

        if(temp != 8)
            test_fail();
    }

    /*------------------------------------------
      CSRRCI Stress
    ------------------------------------------*/

    asm volatile("csrrwi zero,mie,8");

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrrci %0,mie,8"
            : "=r"(old_val)
        );

        asm volatile(
            "csrr %0,mie"
            : "=r"(temp)
        );

        if(temp != 0)
            test_fail();
    }

    /*------------------------------------------
      CSR Read Dependency
    ------------------------------------------*/

    for(int i=0;i<50;i++)
    {
        asm volatile(
            "csrr %0,mie"
            : "=r"(temp)
        );

        sum = temp;
        sum = sum + 1;
        sum = sum + 2;
        sum = sum + 3;
        sum = sum + 4;
        sum = sum + 5;
        sum = sum + 6;
        sum = sum + 7;

        if(sum == 0xffffffff)
            test_fail();
    }

    test_pass();

    return 0;
}
