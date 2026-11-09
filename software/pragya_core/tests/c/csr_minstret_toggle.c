#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_minstret(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0xB02"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_minstret(uint32_t value)
{
    asm volatile (
        "csrw 0xB02, %0"
        :
        : "r"(value)
        : "memory"
    );
}

static inline void write_minstreth(uint32_t value)
{
    asm volatile (
        "csrw 0xB82, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    write_minstreth(0x00000000);
    write_minstret(0x00000000);
    value = read_minstret();

    write_minstreth(0xFFFFFFFF);
    write_minstret(0xFFFFFFFF);
    value = read_minstret();

    write_minstreth(0xAAAAAAAA);
    write_minstret(0xAAAAAAAA);
    value = read_minstret();

    write_minstreth(0x55555555);
    write_minstret(0x55555555);
    value = read_minstret();

    write_minstreth(0xFFFFFFFF);
    write_minstret(0xFFFFFFFF);
    value = read_minstret();

    write_minstreth(0x00000000);
    write_minstret(0x00000000);
    value = read_minstret();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}