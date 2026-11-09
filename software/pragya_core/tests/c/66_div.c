#include "pragya_test.h"
#include <stdint.h>

int main(void)
{

/*============================================================*
 * RV32M DIVISION OVERFLOW
 *
 * DIV signed overflow case:
 *
 * INT32_MIN / -1
 *
 * rs1 = 0x80000000
 * rs2 = 0xFFFFFFFF
 *
 * This must hit:
 *
 *     cross_overflow
 *     DIV × yes
 *============================================================*/

asm volatile(
    "li x5, 0x80000000\n"
    "li x6, -1\n"
    "div x7, x5, x6\n"
    :
    :
    : "x5", "x6", "x7"
);


/*============================================================*
 * Normal DIV
 *
 * This hits:
 *
 *     DIV × no
 *============================================================*/

asm volatile(
    "li x5, 100\n"
    "li x6, 5\n"
    "div x7, x5, x6\n"
    :
    :
    : "x5", "x6", "x7"
);


/*============================================================*
 * PASS
 *============================================================*/

test_pass();

return 0;
}