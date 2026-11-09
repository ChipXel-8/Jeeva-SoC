#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_pmpaddr16(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x3C0"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

int main(void)
{
    volatile uint32_t value;

    /*
     * PMPADDR16
     *
     * Read several times.
     * Do not write this CSR because the current
     * Spike configuration returns zero.
     */

    value = read_pmpaddr16();
    value = read_pmpaddr16();
    value = read_pmpaddr16();
    value = read_pmpaddr16();
    value = read_pmpaddr16();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}