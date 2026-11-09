#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mcause(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x342"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mcause(uint32_t value)
{
    asm volatile (
        "csrw 0x342, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    write_mcause(0x00000000);
    value = read_mcause();

    write_mcause(0x00000002);
    value = read_mcause();

    write_mcause(0x00000003);
    value = read_mcause();

    write_mcause(0x00000007);
    value = read_mcause();

    write_mcause(0x0000000B);
    value = read_mcause();

    write_mcause(0x80000000);
    value = read_mcause();

    write_mcause(0x00000000);
    value = read_mcause();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}