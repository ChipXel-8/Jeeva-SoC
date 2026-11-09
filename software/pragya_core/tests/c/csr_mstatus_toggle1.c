#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x300"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw 0x300, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    /* Initial value */
    write_mstatus(0x00000000);
    value = read_mstatus();

    /* Toggle MIE bit [3] */
    write_mstatus(0x00000008);
    value = read_mstatus();

    /* Toggle MIE back */
    write_mstatus(0x00000000);
    value = read_mstatus();

    /* Toggle MPIE bit [7] */
    write_mstatus(0x00000080);
    value = read_mstatus();

    /* Toggle MPIE back */
    write_mstatus(0x00000000);
    value = read_mstatus();

    /* Toggle both */
    write_mstatus(0x00000088);
    value = read_mstatus();

    /* Toggle both back */
    write_mstatus(0x00000000);
    value = read_mstatus();

    /* Toggle both again */
    write_mstatus(0x00000088);
    value = read_mstatus();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}