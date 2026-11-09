#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t a, b, c, d;

#define MSIE 0x00000008

int main(void)
{
    /*------------------------------------------
      CSRRS Stress
    ------------------------------------------*/

    asm volatile("csrrw zero, mie, zero");

    for(int i = 0; i < 20; i++)
    {
        asm volatile(
            "csrrs %0, mie, %1"
            : "=r"(a)
            : "r"(MSIE)
        );

        asm volatile(
            "csrr %0, mie"
            : "=r"(b)
        );

        if((b & MSIE) != MSIE)
            test_fail();
    }

    /*------------------------------------------
      CSRRC Stress
    ------------------------------------------*/

    for(int i = 0; i < 20; i++)
    {
        asm volatile(
            "csrrc %0, mie, %1"
            : "=r"(a)
            : "r"(MSIE)
        );

        asm volatile(
            "csrr %0, mie"
            : "=r"(b)
        );

        if((b & MSIE) != 0)
            test_fail();
    }

    /*------------------------------------------
      CSRRSI Stress
    ------------------------------------------*/

    asm volatile("csrrw zero, mie, zero");

    for(int i = 0; i < 20; i++)
    {
        asm volatile(
            "csrrsi %0, mie, 8"
            : "=r"(a)
        );

        asm volatile(
            "csrr %0, mie"
            : "=r"(b)
        );

        if((b & MSIE) != MSIE)
            test_fail();
    }

    /*------------------------------------------
      CSRRCI Stress
    ------------------------------------------*/

    for(int i = 0; i < 20; i++)
    {
        asm volatile(
            "csrrci %0, mie, 8"
            : "=r"(a)
        );

        asm volatile(
            "csrr %0, mie"
            : "=r"(b)
        );

        if((b & MSIE) != 0)
            test_fail();
    }

    /*------------------------------------------
      CSR RAW Dependency
    ------------------------------------------*/

    asm volatile(
        "csrr %0, mstatus"
        : "=r"(a)
    );

    b = a + 1;
    c = b + 2;
    d = c + 3;

    if(d == 0)
        test_fail();

    /*------------------------------------------
      CSR Read After Write
    ------------------------------------------*/

    asm volatile(
        "csrrw %0, mstatus, %1"
        : "=r"(a)
        : "r"(0x00001808)
    );

    asm volatile(
        "csrr %0, mstatus"
        : "=r"(b)
    );

    c = b + 10;

    if(c != (0x00001808 + 10))
        test_fail();

    test_pass();

    return 0;
}
