#ifndef PRAGYA_TEST_H
#define PRAGYA_TEST_H

#define TOHOST (*(volatile unsigned int *)0x80008000)

static inline void test_pass(void)
{
    TOHOST = 1;
    while (1);
}

static inline void test_fail(void)
{
    TOHOST = 2;
    while (1);
}

static inline void test_fail_code(unsigned int code)
{
    TOHOST = code;
    while (1);
}

#endif
