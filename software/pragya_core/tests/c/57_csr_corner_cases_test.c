#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t a,b,c,d,e,f;

int main(void)
{
    /*------------------------------------------
      Read Common CSRs
    ------------------------------------------*/

    asm volatile("csrr %0, mstatus"  : "=r"(a));
    asm volatile("csrr %0, mie"      : "=r"(b));
    asm volatile("csrr %0, mtvec"    : "=r"(c));
    asm volatile("csrr %0, mscratch" : "=r"(d));

    /*------------------------------------------
      CSRRW
    ------------------------------------------*/

    asm volatile(
        "li t0,0x12345678\n"
        "csrrw zero, mscratch, t0"
    );

    asm volatile("csrr %0, mscratch" : "=r"(a));

    if(a != 0x12345678)
        test_fail();

    /*------------------------------------------
      CSRRS
    ------------------------------------------*/

    asm volatile(
        "li t0,0x8\n"
        "csrrs zero, mie, t0"
    );

    asm volatile("csrr %0, mie" : "=r"(b));

    if((b & 0x8) == 0)
        test_fail();

    /*------------------------------------------
      CSRRC
    ------------------------------------------*/

    asm volatile(
        "li t0,0x8\n"
        "csrrc zero, mie, t0"
    );

    asm volatile("csrr %0, mie" : "=r"(c));

    if((c & 0x8) != 0)
        test_fail();

    /*------------------------------------------
      CSRRWI
    ------------------------------------------*/

    asm volatile("csrrwi zero, mscratch, 7");

    asm volatile("csrr %0, mscratch" : "=r"(d));

    if(d != 7)
        test_fail();

    /*------------------------------------------
      CSRRSI
    ------------------------------------------*/

    asm volatile("csrrsi zero, mscratch, 1");

    asm volatile("csrr %0, mscratch" : "=r"(d));

    if(d != 7)
        test_fail();

    /*------------------------------------------
      CSRRCI
    ------------------------------------------*/

    asm volatile("csrrci zero, mscratch, 1");

    asm volatile("csrr %0, mscratch" : "=r"(d));

    if(d != 6)
        test_fail();

    /*------------------------------------------
      CSR RAW Dependency
    ------------------------------------------*/

    asm volatile("csrr %0, mscratch" : "=r"(a));

    b = a + 1;
    c = b + 2;
    d = c + 3;
    e = d + 4;
    f = e + 5;

    if(f != 21)       /* 6+1+2+3+4+5 = 21 */
        test_fail();

    /*------------------------------------------
      CSR Read Stress
    ------------------------------------------*/

    for(int i=0;i<100;i++)
    {
        asm volatile("csrr %0,mstatus"  : "=r"(a));
        asm volatile("csrr %0,mie"      : "=r"(b));
        asm volatile("csrr %0,mtvec"    : "=r"(c));
        asm volatile("csrr %0,mscratch" : "=r"(d));

        e = a ^ b;
        f = c + d;

        if((e | f) == 0xFFFFFFFF)
            test_fail();
    }

    /*------------------------------------------
      Read After Write
    ------------------------------------------*/

    asm volatile(
        "li t0,0x55555555\n"
        "csrrw zero, mscratch, t0"
    );

    asm volatile("csrr %0, mscratch" : "=r"(a));

    if(a != 0x55555555)
        test_fail();

    asm volatile(
        "li t0,0xAAAAAAAA\n"
        "csrrw zero, mscratch, t0"
    );

    asm volatile("csrr %0, mscratch" : "=r"(b));

    if(b != 0xAAAAAAAA)
        test_fail();

    /*------------------------------------------
      Final CSR Stress
    ------------------------------------------*/

    for(int i=0;i<50;i++)
    {
        asm volatile("csrr %0,mstatus" : "=r"(a));
        asm volatile("csrr %0,mie"     : "=r"(b));
        asm volatile("csrr %0,mtvec"   : "=r"(c));
        asm volatile("csrr %0,mscratch": "=r"(d));

        a = a + i;
        b = b ^ a;
        c = c + b;
        d = d ^ c;

        if((a & b & c & d) == 0xFFFFFFFF)
            test_fail();
    }

    test_pass();

    return 0;
}
