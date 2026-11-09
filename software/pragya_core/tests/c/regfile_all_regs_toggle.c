#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

/*
 * Force compiler to generate writes to many different
 * architectural registers.
 */
__attribute__((noinline))
static uint32_t reg_write_pattern(uint32_t a)
{
    register uint32_t r1  = a ^ 0x11111111;
    register uint32_t r2  = a ^ 0x22222222;
    register uint32_t r3  = a ^ 0x33333333;
    register uint32_t r4  = a ^ 0x44444444;
    register uint32_t r5  = a ^ 0x55555555;
    register uint32_t r6  = a ^ 0x66666666;
    register uint32_t r7  = a ^ 0x77777777;
    register uint32_t r8  = a ^ 0x88888888;
    register uint32_t r9  = a ^ 0x99999999;
    register uint32_t r10 = a ^ 0xAAAAAAAA;
    register uint32_t r11 = a ^ 0xBBBBBBBB;
    register uint32_t r12 = a ^ 0xCCCCCCCC;
    register uint32_t r13 = a ^ 0xDDDDDDDD;
    register uint32_t r14 = a ^ 0xEEEEEEEE;
    register uint32_t r15 = a ^ 0xFFFFFFFF;

    return r1 ^ r2 ^ r3 ^ r4 ^
           r5 ^ r6 ^ r7 ^ r8 ^
           r9 ^ r10 ^ r11 ^ r12 ^
           r13 ^ r14 ^ r15;
}

int main(void)
{
    volatile uint32_t i;
    uint32_t value;

    /*
     * Generate many register writes.
     */
    for (i = 0; i < 64; i++)
    {
        value = reg_write_pattern(
            0xAAAAAAAA ^ (i * 0x01010101)
        );

        sink = value;
    }

    /*
     * Different arithmetic operations increase
     * register destination/source variation.
     */
    for (i = 0; i < 128; i++)
    {
        uint32_t a = i;
        uint32_t b = i + 1;
        uint32_t c = a + b;
        uint32_t d = c ^ 0xAAAAAAAA;
        uint32_t e = d + 0x12345678;

        sink = e;
    }

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}