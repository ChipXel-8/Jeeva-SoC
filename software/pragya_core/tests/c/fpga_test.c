#include <stdint.h>

#define GPIO_REG (*((volatile uint32_t *)0x0000C000))

volatile int32_t   s_a, s_b, s_quot, s_rem, s_mul;
volatile uint32_t  u_a, u_b, u_quot, u_rem;

void test_fail_step(uint16_t step) {
    GPIO_REG = 0xFA00 | step; // Displays FA01, FA02, etc.
    while (1);
}

void test_pass_final(void) {
    GPIO_REG = 0x900D;        // Displays 900D ("GOOD")
    while (1);
}

int main(void)
{
    /* Step 1: Multiply */
    u_a = 15; u_b = 6;
    s_mul = u_a * u_b;
    if (s_mul != 90) test_fail_step(1);

    /* Step 2: Unsigned Div & Rem */
    u_quot = u_a / u_b;   /* 15 / 6 = 2 */
    u_rem  = u_a % u_b;   /* 15 % 6 = 3 */
    if (u_quot != 2 || u_rem != 3) test_fail_step(2);

    /* Step 3: Signed Div with negative dividend */
    s_a = -100; s_b = 7;
    s_quot = s_a / s_b;   /* -100 / 7 = -14 */
    s_rem  = s_a % s_b;   /* -100 % 7 = -2 */
    if (s_quot != -14 || s_rem != -2) test_fail_step(3);

    /* Step 4: Signed Div with both negative */
    s_a = -84; s_b = -12;
    s_quot = s_a / s_b;   /* -84 / -12 = 7 */
    s_rem  = s_a % s_b;   /* -84 % -12 = 0 */
    if (s_quot != 7 || s_rem != 0) test_fail_step(4);

    test_pass_final();
    return 0;
}