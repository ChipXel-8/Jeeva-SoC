#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mcycle(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0xB00"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mcycle(uint32_t value)
{
    asm volatile (
        "csrw 0xB00, %0"
        :
        : "r"(value)
        : "memory"
    );
}

static inline void write_mcycleh(uint32_t value)
{
    asm volatile (
        "csrw 0xB80, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    write_mcycleh(0x00000000);
    write_mcycle(0x00000000);
    value = read_mcycle();

    write_mcycleh(0xFFFFFFFF);
    write_mcycle(0xFFFFFFFF);
    value = read_mcycle();

    write_mcycleh(0xAAAAAAAA);
    write_mcycle(0xAAAAAAAA);
    value = read_mcycle();

    write_mcycleh(0x55555555);
    write_mcycle(0x55555555);
    value = read_mcycle();

    write_mcycleh(0xFFFFFFFF);
    write_mcycle(0xFFFFFFFF);
    value = read_mcycle();

    write_mcycleh(0x00000000);
    write_mcycle(0x00000000);
    value = read_mcycle();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}
