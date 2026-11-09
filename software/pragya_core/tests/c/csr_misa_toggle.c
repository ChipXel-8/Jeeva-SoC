#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_misa(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x301"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_misa(uint32_t value)
{
    asm volatile (
        "csrw 0x301, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    /*
     * MISA reset = 0x40001100
     *
     * Bit 12 = M extension.
     */

    write_misa(0x40000100);
    value = read_misa();

    write_misa(0x40001100);
    value = read_misa();

    write_misa(0x40000100);
    value = read_misa();

    write_misa(0x40001100);
    value = read_misa();

    write_misa(0x40000100);
    value = read_misa();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}