#include "pragya_test.h"
#include <stdint.h>

volatile int a, b, c, d, e, f;
volatile unsigned ua, ub, uc;


/*============================================================*
 *                         MAIN
 *============================================================*/

int main(void)
{

/*------------------------------------------------------------*
 * MUL : rs1 = x18
 *------------------------------------------------------------*/

a = 12;
b = 7;

/*
 * Force:
 *     mul x5, x18, x6
 *
 * Required coverage:
 *     cross_instr_rs1
 *     MUL + x18
 */

asm volatile(
    "mv x18, %0\n"
    "mv x6,  %1\n"
    "mul x5, x18, x6\n"
    :
    : "r"(a), "r"(b)
    : "x18", "x6", "x5"
);

if(a * b != 84)
    test_fail();


/*------------------------------------------------------------*
 * REM : rs1 = x11
 *------------------------------------------------------------*/

a = 101;
b = 10;

/*
 * Force:
 *     rem x5, x11, x6
 *
 * Required coverage:
 *     REM + x11
 */

asm volatile(
    "mv x11, %0\n"
    "mv x6,  %1\n"
    "rem x5, x11, x6\n"
    :
    : "r"(a), "r"(b)
    : "x11", "x6", "x5"
);

if(a % b != 1)
    test_fail();


/*------------------------------------------------------------*
 * MULH : rs1 = x6
 *------------------------------------------------------------*/

a = 100000;
b = 200;

/*
 * Force:
 *     mulh x5, x6, x7
 *
 * Required coverage:
 *     MULH + x6
 */

asm volatile(
    "mv x6, %0\n"
    "mv x7, %1\n"
    "mulh x5, x6, x7\n"
    :
    : "r"(a), "r"(b)
    : "x6", "x7", "x5"
);


/*------------------------------------------------------------*
 * REM : rs1 = x5
 *------------------------------------------------------------*/

a = -101;
b = 10;

/*
 * Force:
 *     rem x6, x5, x7
 *
 * Required coverage:
 *     REM + x5
 */

asm volatile(
    "mv x5, %0\n"
    "mv x7, %1\n"
    "rem x6, x5, x7\n"
    :
    : "r"(a), "r"(b)
    : "x5", "x7", "x6"
);

if(a % b != -1)
    test_fail();


/*------------------------------------------------------------*
 * MULH : rs1 = x4
 *------------------------------------------------------------*/

a = 0x40000000;
b = 4;

/*
 * Force:
 *     mulh x5, x4, x6
 *
 * Required coverage:
 *     MULH + x4
 */

asm volatile(
    "mv x4, %0\n"
    "mv x6, %1\n"
    "mulh x5, x4, x6\n"
    :
    : "r"(a), "r"(b)
    : "x4", "x6", "x5"
);


/*------------------------------------------------------------*
 * MULHSU : rs1 = x0
 *------------------------------------------------------------*/

/*
 * x0 is permanently zero.
 *
 * Force:
 *     mulhsu x5, x0, x6
 *
 * Required coverage:
 *     MULHSU + x0
 */

a = 12345;

asm volatile(
    "mv x6, %0\n"
    "mulhsu x5, x0, x6\n"
    :
    : "r"(a)
    : "x6", "x5"
);


/*------------------------------------------------------------*
 * DIV : rs1 = x29
 *------------------------------------------------------------*/

a = 1000;
b = 10;

/*
 * Force:
 *     div x5, x29, x6
 *
 * Required coverage:
 *     DIV + x29
 */

asm volatile(
    "mv x29, %0\n"
    "mv x6,  %1\n"
    "div x5, x29, x6\n"
    :
    : "r"(a), "r"(b)
    : "x29", "x6", "x5"
);

if(a / b != 100)
    test_fail();


/*------------------------------------------------------------*
 * REM : rs1 = x25
 *------------------------------------------------------------*/

a = 101;
b = 10;

/*
 * Force:
 *     rem x5, x25, x6
 *
 * Required coverage:
 *     REM + x25
 */

asm volatile(
    "mv x25, %0\n"
    "mv x6,  %1\n"
    "rem x5, x25, x6\n"
    :
    : "r"(a), "r"(b)
    : "x25", "x6", "x5"
);

if(a % b != 1)
    test_fail();


/*------------------------------------------------------------*
 * REM : rs1 = x24
 *------------------------------------------------------------*/

a = -101;
b = 10;

/*
 * Force:
 *     rem x5, x24, x6
 *
 * Required coverage:
 *     REM + x24
 */

asm volatile(
    "mv x24, %0\n"
    "mv x6,  %1\n"
    "rem x5, x24, x6\n"
    :
    : "r"(a), "r"(b)
    : "x24", "x6", "x5"
);

if(a % b != -1)
    test_fail();


/*------------------------------------------------------------*
 * MULH : rs1 = x24
 *------------------------------------------------------------*/

a = 100000;
b = 200;

/*
 * Force:
 *     mulh x5, x24, x6
 *
 * Required coverage:
 *     MULH + x24
 */

asm volatile(
    "mv x24, %0\n"
    "mv x6,  %1\n"
    "mulh x5, x24, x6\n"
    :
    : "r"(a), "r"(b)
    : "x24", "x6", "x5"
);


/*------------------------------------------------------------*
 * REMU : rs1 = x18
 *------------------------------------------------------------*/

ua = 1000;
ub = 7;

/*
 * Force:
 *     remu x5, x18, x6
 *
 * Required coverage:
 *     REMU + x18
 */

asm volatile(
    "mv x18, %0\n"
    "mv x6,  %1\n"
    "remu x5, x18, x6\n"
    :
    : "r"(ua), "r"(ub)
    : "x18", "x6", "x5"
);

if((ua % ub) != 6)
    test_fail();


/*------------------------------------------------------------*
 * Additional MULHSU + x0
 *------------------------------------------------------------*
 *
 * More than one occurrence makes it easier to verify that
 * the coverage sampler is correctly detecting the instruction.
 */

asm volatile(
    "li x6, 0x7fffffff\n"
    "mulhsu x5, x0, x6\n"
    :
    :
    : "x6", "x5"
);

asm volatile(
    "li x6, 0xffffffff\n"
    "mulhsu x5, x0, x6\n"
    :
    :
    : "x6", "x5"
);


/*------------------------------------------------------------*
 * Additional hits for the remaining bins
 *------------------------------------------------------------*/

asm volatile(
    "li x29, 1234\n"
    "li x6, 17\n"
    "div x5, x29, x6\n"
    :
    :
    : "x29", "x6", "x5"
);

asm volatile(
    "li x25, 1234\n"
    "li x6, 17\n"
    "rem x5, x25, x6\n"
    :
    :
    : "x25", "x6", "x5"
);

asm volatile(
    "li x24, -1234\n"
    "li x6, 17\n"
    "rem x5, x24, x6\n"
    :
    :
    : "x24", "x6", "x5"
);

asm volatile(
    "li x24, 123456\n"
    "li x6, 321\n"
    "mulh x5, x24, x6\n"
    :
    :
    : "x24", "x6", "x5"
);

asm volatile(
    "li x18, 1234\n"
    "li x6, 17\n"
    "remu x5, x18, x6\n"
    :
    :
    : "x18", "x6", "x5"
);


/*------------------------------------------------------------*
 * PASS
 *------------------------------------------------------------*/

test_pass();

return 0;

}