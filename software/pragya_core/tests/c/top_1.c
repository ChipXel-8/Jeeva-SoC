#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t sink;

int main(void)
{
    volatile uint8_t  *bmem  = (volatile uint8_t  *)0x80008000;
    volatile uint16_t *hmem  = (volatile uint16_t *)0x80008020;
    volatile uint32_t *wmem  = (volatile uint32_t *)0x80008040;

    uint32_t a, b, c, d;

    /*
     * ============================================================
     * 1. REGISTER / ALU DATA PATTERNS
     * ============================================================
     */

    a = 0x00000000;
    b = 0xFFFFFFFF;

    c = a + b;
    d = a - b;

    c = 0xAAAAAAAA;
    d = 0x55555555;

    a = c & d;
    b = c | d;
    c = c ^ d;

    /*
     * Large bit transitions.
     */
    a = 0x80000000;
    b = 0x7FFFFFFF;

    c = a + b;
    d = a - b;

    /*
     * ============================================================
     * 2. SHIFT OPERATIONS
     * ============================================================
     */

    a = 0x00000001;

    b = a << 1;
    b = a << 7;
    b = a << 15;
    b = a << 31;

    a = 0x80000000;

    b = a >> 1;
    b = a >> 7;
    b = a >> 15;
    b = a >> 31;

    /*
     * ============================================================
     * 3. SIGNED / UNSIGNED COMPARISON
     * ============================================================
     */

    c = ((int32_t)0x80000000 < (int32_t)0x00000001);
    c = ((int32_t)0x7FFFFFFF < (int32_t)0xFFFFFFFF);

    c = (0x00000000U < 0xFFFFFFFFU);
    c = (0xFFFFFFFFU < 0x00000000U);

    /*
     * ============================================================
     * 4. WORD STORES
     * ============================================================
     */

    wmem[0] = 0x00000000;
    wmem[1] = 0xFFFFFFFF;
    wmem[2] = 0xAAAAAAAA;
    wmem[3] = 0x55555555;
    wmem[4] = 0x12345678;
    wmem[5] = 0x87654321;
    wmem[6] = 0x80000000;
    wmem[7] = 0x7FFFFFFF;

    /*
     * ============================================================
     * 5. WORD LOADS
     * ============================================================
     */

    a = wmem[0];
    b = wmem[1];
    c = wmem[2];
    d = wmem[3];

    sink = a ^ b ^ c ^ d;

    a = wmem[4];
    b = wmem[5];
    c = wmem[6];
    d = wmem[7];

    sink = a ^ b ^ c ^ d;

    /*
     * ============================================================
     * 6. HALF-WORD STORES
     * ============================================================
     */

    hmem[0] = 0x0000;
    hmem[1] = 0xFFFF;
    hmem[2] = 0xAAAA;
    hmem[3] = 0x5555;
    hmem[4] = 0x1234;
    hmem[5] = 0xFEDC;
    hmem[6] = 0x8000;
    hmem[7] = 0x7FFF;

    /*
     * HALF-WORD LOADS
     */

    a = hmem[0];
    b = hmem[1];
    c = hmem[2];
    d = hmem[3];

    sink ^= a ^ b ^ c ^ d;

    a = hmem[4];
    b = hmem[5];
    c = hmem[6];
    d = hmem[7];

    sink ^= a ^ b ^ c ^ d;

    /*
     * ============================================================
     * 7. BYTE STORES
     * ============================================================
     */

    bmem[0] = 0x00;
    bmem[1] = 0xFF;
    bmem[2] = 0xAA;
    bmem[3] = 0x55;

    bmem[4] = 0x12;
    bmem[5] = 0x34;
    bmem[6] = 0x56;
    bmem[7] = 0x78;

    bmem[8]  = 0x80;
    bmem[9]  = 0x7F;
    bmem[10] = 0x01;
    bmem[11] = 0xFE;

    /*
     * BYTE LOADS
     */

    a = bmem[0];
    b = bmem[1];
    c = bmem[2];
    d = bmem[3];

    sink ^= a ^ b ^ c ^ d;

    a = bmem[4];
    b = bmem[5];
    c = bmem[6];
    d = bmem[7];

    sink ^= a ^ b ^ c ^ d;

    a = bmem[8];
    b = bmem[9];
    c = bmem[10];
    d = bmem[11];

    sink ^= a ^ b ^ c ^ d;

    /*
     * ============================================================
     * 8. DIFFERENT MEMORY ADDRESSES
     * ============================================================
     */

    wmem[20] = 0x11111111;
    wmem[21] = 0x22222222;
    wmem[22] = 0x33333333;
    wmem[23] = 0x44444444;

    a = wmem[20];
    b = wmem[21];
    c = wmem[22];
    d = wmem[23];

    sink ^= a ^ b ^ c ^ d;

    /*
     * ============================================================
     * 9. BACK-TO-BACK LOAD/STORE
     * ============================================================
     */

    wmem[30] = 0xAAAAAAAA;
    a = wmem[30];

    wmem[31] = 0x55555555;
    b = wmem[31];

    wmem[32] = 0x12345678;
    c = wmem[32];

    wmem[33] = 0x87654321;
    d = wmem[33];

    sink ^= a ^ b ^ c ^ d;

    /*
     * ============================================================
     * 10. BRANCH COVERAGE
     * ============================================================
     */

    a = 0;

    if (a == 0)
        a = 0x11111111;

    if (a != 0)
        a = 0x22222222;

    if (a < 0xFFFFFFFF)
        a = 0x33333333;

    if (a >= 0x10000000)
        a = 0x44444444;

    /*
     * False branch cases.
     */

    if (a == 0xFFFFFFFF)
        a = 0xAAAAAAAA;

    if (a != a)
        a = 0xBBBBBBBB;

    /*
     * ============================================================
     * 11. LOOP - MANY SEQUENTIAL INSTRUCTION FETCHES
     * ============================================================
     */

    for (int i = 0; i < 64; i++) {

        a += 0x11111111;
        b ^= a;
        c = b << (i & 31);
        d = c >> (i & 31);

        if (d == 0x12345678)
            sink ^= 0xFFFFFFFF;
        else
            sink ^= d;
    }

    /*
     * ============================================================
     * 12. JUMP / CALL ACTIVITY
     * ============================================================
     */

    asm volatile(
        "jal x1, 1f\n"
        "addi x20, x0, 0x11\n"
        "addi x20, x0, 0x22\n"
        "1:\n"
        "addi x21, x0, 0x33\n"
        "addi x21, x21, 1\n"
        :
        :
        : "x1", "x20", "x21", "memory"
    );

    /*
     * ============================================================
     * 13. MORE PC / INSTRUCTION DATA VARIATION
     * ============================================================
     */

    asm volatile(
        "li x5, 0xAAAAAAAA\n"
        "li x6, 0x55555555\n"
        "add x7, x5, x6\n"
        "sub x8, x5, x6\n"
        "xor x9, x5, x6\n"
        "or  x10, x5, x6\n"
        "and x11, x5, x6\n"
        "sll x12, x5, x6\n"
        "srl x13, x5, x6\n"
        "sra x14, x5, x6\n"
        :
        :
        : "memory"
    );

    /*
     * ============================================================
     * FINAL RESULT
     * ============================================================
     */

    sink ^= a ^ b ^ c ^ d;

    test_pass();

    while (1)
        asm volatile("nop");

    return 0;
}