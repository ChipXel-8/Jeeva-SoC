#include "pragya_test.h"
#include <stdint.h>

volatile signed char s8[32];
volatile unsigned char u8[32];

volatile signed short s16[32];
volatile unsigned short u16[32];

volatile int w32[32];

volatile signed char c;
volatile unsigned char uc;
volatile signed short s;
volatile unsigned short us;
volatile int w;

int main(void)
{
    s8[0]=-10;
    s8[1]=100;

    u8[0]=200;
    u8[1]=255;

    s16[0]=-1234;
    s16[1]=1234;

    u16[0]=60000;
    u16[1]=50000;

    w32[0]=0x12345678;

    c=s8[0];
    c=s8[1];

    uc=u8[0];
    uc=u8[1];

    s=s16[0];
    s=s16[1];

    us=u16[0];
    us=u16[1];

    w=w32[0];

    s8[5]=-55;
    s16[5]=-2222;
    w32[5]=0xAAAAAAAA;

    c=s8[5];
    s=s16[5];
    w=w32[5];

    if(c!=-55) test_fail();
    if(s!=-2222) test_fail();
    if(w!=0xAAAAAAAA) test_fail();

    test_pass();

    return 0;
}
