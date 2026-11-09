#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    uint32_t value;

    asm volatile(

        /* Do NOT modify x1, x2 or x8 */

        /* Write different patterns into registers */

        "li x5,  0xAAAAAAAA\n"
        "li x6,  0x55555555\n"
        "li x7,  0x12345678\n"

        "li x9,  0x87654321\n"
        "li x10, 0xAAAAAAAA\n"
        "li x11, 0x55555555\n"
        "li x12, 0x11111111\n"
        "li x13, 0x22222222\n"
        "li x14, 0x33333333\n"
        "li x15, 0x44444444\n"

        "li x16, 0x55555555\n"
        "li x17, 0x66666666\n"
        "li x18, 0x77777777\n"
        "li x19, 0x88888888\n"
        "li x20, 0x99999999\n"
        "li x21, 0xAAAAAAAA\n"
        "li x22, 0xBBBBBBBB\n"
        "li x23, 0xCCCCCCCC\n"
        "li x24, 0xDDDDDDDD\n"
        "li x25, 0xEEEEEEEE\n"
        "li x26, 0xFFFFFFFF\n"
        "li x27, 0x10101010\n"
        "li x28, 0x20202020\n"
        "li x29, 0x40404040\n"
        "li x30, 0x80808080\n"
        "li x31, 0xDEADBEEF\n"

        /* Exercise rs1/rs2 combinations */

        "add x5,  x5,  x6\n"
        "add x6,  x7,  x9\n"
        "add x7,  x10, x11\n"
        "add x9,  x12, x13\n"
        "add x10, x14, x15\n"
        "add x11, x16, x17\n"
        "add x12, x18, x19\n"
        "add x13, x20, x21\n"
        "add x14, x22, x23\n"
        "add x15, x24, x25\n"
        "add x16, x26, x27\n"
        "add x17, x28, x29\n"
        "add x18, x30, x31\n"

        /* Exercise destination addresses */

        "add x19, x5,  x6\n"
        "add x20, x7,  x9\n"
        "add x21, x10, x11\n"
        "add x22, x12, x13\n"
        "add x23, x14, x15\n"
        "add x24, x16, x17\n"
        "add x25, x18, x19\n"
        "add x26, x20, x21\n"
        "add x27, x22, x23\n"
        "add x28, x24, x25\n"
        "add x29, x26, x27\n"
        "add x30, x28, x29\n"
        "add x31, x30, x5\n"

        /* Put result into a C variable */
        "mv %0, x31\n"

        : "=r"(value)
        :
        : "memory"
    );

    sink = value;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}