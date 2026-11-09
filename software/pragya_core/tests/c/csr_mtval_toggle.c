#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mtval(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x343"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mtval(uint32_t value)
{
    asm volatile (
        "csrw 0x343, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    write_mtval(0x00000000);
    value = read_mtval();

    write_mtval(0xFFFFFFFF);
    value = read_mtval();

    write_mtval(0xAAAAAAAA);
    value = read_mtval();

    write_mtval(0x55555555);
    value = read_mtval();

    write_mtval(0xFFFFFFFF);
    value = read_mtval();

    write_mtval(0x00000000);
    value = read_mtval();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}