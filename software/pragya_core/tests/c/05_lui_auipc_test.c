#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t value1;
volatile uint32_t value2;
volatile uint32_t value3;
volatile uint32_t value4;
volatile uint32_t value5;

volatile uint32_t array[256];

int main(void)
{
    /* Force compiler to create large constants */

    value1 = 0x12345678;
    value2 = 0x87654321;
    value3 = 0xABCDEF01;
    value4 = 0x80000000;
    value5 = 0x7FFFFFFF;

    if(value1 != 0x12345678)
        test_fail();

    if(value2 != 0x87654321)
        test_fail();

    if(value3 != 0xABCDEF01)
        test_fail();

    if(value4 != 0x80000000)
        test_fail();

    if(value5 != 0x7FFFFFFF)
        test_fail();

    /* Access far memory locations to encourage AUIPC */

    array[0]   = value1;
    array[50]  = value2;
    array[100] = value3;
    array[150] = value4;
    array[200] = value5;

    if(array[0] != value1)
        test_fail();

    if(array[50] != value2)
        test_fail();

    if(array[100] != value3)
        test_fail();

    if(array[150] != value4)
        test_fail();

    if(array[200] != value5)
        test_fail();

    /* Address arithmetic */

    volatile uint32_t *p = &array[120];

    *p = 0xDEADBEEF;

    if(*p != 0xDEADBEEF)
        test_fail();

    p = p + 10;

    *p = 0xCAFEBABE;

    if(*p != 0xCAFEBABE)
        test_fail();

    test_pass();

    return 0;
}