#include "pragya_test.h"
#include <stdint.h>

static inline void csr_write_mie(uint32_t value)
{
    asm volatile (
        "csrw 0x304, %0"
        :
        : "r"(value)
        : "memory"
    );
}

static inline uint32_t csr_read_mie(void)
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

int main(void)
{
    uint32_t value;

    csr_write_mie(0x00000000);
    value = csr_read_mie();

    /* MEIE */
    csr_write_mie(0x00000800);
    value = csr_read_mie();

    csr_write_mie(0x00000000);

    /* MTIE */
    csr_write_mie(0x00000080);
    value = csr_read_mie();

    csr_write_mie(0x00000000);

    /* MSIE */
    csr_write_mie(0x00000008);
    value = csr_read_mie();

    csr_write_mie(0x00000000);

    (void)value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}