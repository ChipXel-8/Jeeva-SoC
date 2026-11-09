#include "pragya_test.h"

volatile int a;

int main(void)
{
    a=1;

    asm volatile("ecall");

    a++;

    asm volatile("ebreak");

    a++;

    test_pass();

    return 0;
}
