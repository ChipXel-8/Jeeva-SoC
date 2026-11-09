#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t a,b,c,d,e,f,g,h;

int main(void)
{
    /*------------------------------------------
      Read mstatus
    ------------------------------------------*/

    asm volatile("csrr %0, mstatus" : "=r"(a));

    b = a + 1;
    c = b + 2;

    if(c == 0)
        test_fail();

    /*------------------------------------------
      Read mie
    ------------------------------------------*/

    asm volatile("csrr %0, mie" : "=r"(a));

    b = a ^ 0x55AA55AA;

    if((b ^ 0x55AA55AA) != a)
        test_fail();

    /*------------------------------------------
      Read mtvec
    ------------------------------------------*/

    asm volatile("csrr %0, mtvec" : "=r"(a));

    if((a & 0x3)!=0)
        test_fail();

    /*------------------------------------------
      Read mepc
    ------------------------------------------*/

    asm volatile("csrr %0, mepc" : "=r"(a));

    b=a+5;
    c=b+10;

    if(c==0)
        test_fail();

    /*------------------------------------------
      Read mcause
    ------------------------------------------*/

    asm volatile("csrr %0, mcause" : "=r"(a));

    d=a+1;

    if(d==0xFFFFFFFF)
        test_fail();

    /*------------------------------------------
      CSR Dependency Chain
    ------------------------------------------*/

    asm volatile("csrr %0, mstatus":"=r"(a));

    b=a+1;
    c=b+2;
    d=c+3;
    e=d+4;
    f=e+5;
    g=f+6;
    h=g+7;

    if(h==0)
        test_fail();

    /*------------------------------------------
      Read Same CSR Multiple Times
    ------------------------------------------*/

    asm volatile("csrr %0,mstatus":"=r"(a));
    asm volatile("csrr %0,mstatus":"=r"(b));
    asm volatile("csrr %0,mstatus":"=r"(c));
    asm volatile("csrr %0,mstatus":"=r"(d));

    if((a!=b)||(b!=c)||(c!=d))
        test_fail();

    /*------------------------------------------
      CSR + ALU Mix
    ------------------------------------------*/

    asm volatile("csrr %0,mstatus":"=r"(a));

    b=a+100;
    c=b^0x1234;
    d=c|0x55;
    e=d&0xFFFF;

    if(e==0)
        test_fail();

    test_pass();

    return 0;
}
