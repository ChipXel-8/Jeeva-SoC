#include "pragya_test.h"
#include <stdint.h>

static inline uint32_t read_mie(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x304"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}

static inline void write_mie(uint32_t value)
{
    asm volatile (
        "csrw 0x304, %0"
        :
        : "r"(value)
        : "memory"
    );
}

int main(void)
{
    volatile uint32_t value;

    /* All interrupt enables OFF */
    write_mie(0x00000000);
    value = read_mie();

    /* MSIE bit 3 */
    write_mie(0x00000008);
    value = read_mie();

    write_mie(0x00000000);
    value = read_mie();

    /* MTIE bit 7 */
    write_mie(0x00000080);
    value = read_mie();

    write_mie(0x00000000);
    value = read_mie();

    /* MEIE bit 11 */
    write_mie(0x00000800);
    value = read_mie();

    write_mie(0x00000000);
    value = read_mie();

    /* All three */
    write_mie(0x00000888);
    value = read_mie();

    write_mie(0x00000000);
    value = read_mie();

    write_mie(0x00000888);
    value = read_mie();

    (void)value;

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}