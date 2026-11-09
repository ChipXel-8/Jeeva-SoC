#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t mem[32];

volatile uint32_t a;
volatile uint32_t b;
volatile uint32_t c;
volatile uint32_t d;

int main(void)
{
    /* -----------------------------------------
       Basic register dependencies
       ----------------------------------------- */

    a = 10;
    b = 20;

    c = a + b;
    d = c + 5;

    if (d != 35)
        test_fail();


    /* -----------------------------------------
       Store -> Load
       ----------------------------------------- */

    mem[0] = 0x11111111;

    a = mem[0];

    if (a != 0x11111111)
        test_fail();


    /* -----------------------------------------
       Load -> ALU -> ALU
       ----------------------------------------- */

    a = mem[0];
    b = a + 1;
    c = b + 1;

    if (c != 0x11111113)
        test_fail();


    /* -----------------------------------------
       Store -> Load -> Store
       ----------------------------------------- */

    mem[1] = 10;

    a = mem[1];
    b = a + 1;

    mem[1] = b;

    c = mem[1];

    if (c != 11)
        test_fail();


    /* -----------------------------------------
       Consecutive memory operations
       ----------------------------------------- */

    mem[2] = 20;
    mem[3] = 30;

    a = mem[2];
    b = mem[3];

    c = a + b;

    if (c != 50)
        test_fail();


    /* -----------------------------------------
       RAW dependency chain
       ----------------------------------------- */

    a = 1;

    a = a + 2;
    a = a + 3;
    a = a + 4;
    a = a + 5;

    if (a != 15)
        test_fail();


    /* -----------------------------------------
       Memory dependency
       ----------------------------------------- */

    mem[4] = 100;

    a = mem[4];
    b = a + 10;

    mem[4] = b;

    c = mem[4];

    if (c != 110)
        test_fail();


    /* -----------------------------------------
       Additional load/store hazards
       ----------------------------------------- */

    mem[5] = 200;

    a = mem[5];
    b = a + 1;
    mem[5] = b;

    a = mem[5];
    b = a + 1;
    mem[5] = b;

    c = mem[5];

    if (c != 202)
        test_fail();


    /* -----------------------------------------
       Simple branch dependency
       ----------------------------------------- */

    a = 5;
    b = 5;

    if (a == b)
        c = 1;
    else
        c = 0;

    if (c != 1)
        test_fail();


    /* -----------------------------------------
       Simple arithmetic dependency
       ----------------------------------------- */

    a = 100;
    b = 25;

    c = a - b;
    d = c + 10;

    if (d != 85)
        test_fail();


    /* -----------------------------------------
       Final memory verification
       ----------------------------------------- */

    if (mem[0] != 0x11111111)
        test_fail();

    if (mem[1] != 11)
        test_fail();

    if (mem[2] != 20)
        test_fail();

    if (mem[3] != 30)
        test_fail();

    if (mem[4] != 110)
        test_fail();

    if (mem[5] != 202)
        test_fail();


    /* -----------------------------------------
       PASS
       ----------------------------------------- */

    test_pass();

    return 0;
}
