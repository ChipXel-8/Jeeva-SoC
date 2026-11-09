#include "pragya_test.h"

volatile int a = 10;
volatile int b = 20;
volatile int c = 0;

int main(void)
{
    /* BEQ not taken */
    if(a == b)
        c++;

    /* BEQ taken */
    if(a == 10)
        c++;

    /* BNE taken */
    if(a != b)
        c++;

    /* BNE not taken */
    if(a != 10)
        c++;

    /* BLT taken */
    if(a < b)
        c++;

    /* BLT not taken */
    if(b < a)
        c++;

    /* BGE taken */
    if(b >= a)
        c++;

    /* BGE not taken */
    if(a >= b)
        c++;

    /* BLTU */
    if((unsigned)a < (unsigned)b)
        c++;

    /* BGEU */
    if((unsigned)b >= (unsigned)a)
        c++;

    /* Loop branch */
    for(int i = 0; i < 20; i++)
    {
        c += i;
    }

    /* Switch generates jump table or branches */
    switch(a)
    {
        case 5:
            c++;
            break;

        case 10:
            c += 2;
            break;

        default:
            c--;
            break;
    }

    if(c == 0)
        test_fail();

    test_pass();

    return 0;
}
