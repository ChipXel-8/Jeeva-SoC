#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mepc(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x341"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mepc(uint32_t value)
{
    asm volatile (
        "csrw 0x341, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    write_mepc(0x00000000);
    value = read_mepc();

    write_mepc(0xFFFFFFFF);
    value = read_mepc();

    write_mepc(0xAAAAAAAA);
    value = read_mepc();

    write_mepc(0x55555554);
    value = read_mepc();

    write_mepc(0xFFFFFFFF);
    value = read_mepc();

    write_mepc(0x00000000);
    value = read_mepc();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}