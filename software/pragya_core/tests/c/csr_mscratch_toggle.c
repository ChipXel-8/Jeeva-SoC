#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mscratch(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x340"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mscratch(uint32_t value)
{
    asm volatile (
        "csrw 0x340, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    write_mscratch(0x00000000);
    value = read_mscratch();

    write_mscratch(0xFFFFFFFF);
    value = read_mscratch();

    write_mscratch(0xAAAAAAAA);
    value = read_mscratch();

    write_mscratch(0x55555555);
    value = read_mscratch();

    write_mscratch(0xFFFFFFFF);
    value = read_mscratch();

    write_mscratch(0x00000000);
    value = read_mscratch();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}