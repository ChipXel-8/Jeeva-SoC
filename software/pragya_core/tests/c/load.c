#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t mem[256];

volatile uint32_t a,b,c,d,e,f,g,h;

int main(void)
{
    // Initialize memory
    for(int i=0;i<256;i++)
        mem[i] = i + 1;

    // Repeated load operations
    for(int i=0;i<200;i++)
    {
        a = mem[(i + 0) & 255];
        b = mem[(i + 1) & 255];
        c = mem[(i + 2) & 255];
        d = mem[(i + 3) & 255];

        e = a + b;
        f = c + d;
        g = e + f;
        h = g + i;

        if(h == 0xFFFFFFFF)
            test_fail();
    }

    test_pass();

    return 0;
}
