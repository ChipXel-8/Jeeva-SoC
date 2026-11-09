#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t u;
volatile int32_t  s;
volatile uint32_t result;

int main(void)
{
    /*--------------------------------------------------
      Logical Left Shift (SLLI)
    --------------------------------------------------*/

    u = 1;

    if ((u << 1) != 2)
        test_fail();

    if ((u << 5) != 32)
        test_fail();

    if ((u << 31) != 0x80000000)
        test_fail();

    /*--------------------------------------------------
      Logical Right Shift (SRLI)
    --------------------------------------------------*/

    u = 0x80000000;

    if ((u >> 1) != 0x40000000)
        test_fail();

    if ((u >> 4) != 0x08000000)
        test_fail();

    if ((u >> 31) != 1)
        test_fail();

    /*--------------------------------------------------
      Arithmetic Right Shift (SRAI)
    --------------------------------------------------*/

    s = -16;

    if ((s >> 1) != -8)
        test_fail();

    if ((s >> 2) != -4)
        test_fail();

    if ((s >> 4) != -1)
        test_fail();

    /*--------------------------------------------------
      Variable Left Shift (SLL)
    --------------------------------------------------*/

    result = 1;

    for(int i=0;i<5;i++)
        result <<= 1;

    if(result != 32)
        test_fail();

    /*--------------------------------------------------
      Variable Right Shift (SRL)
    --------------------------------------------------*/

    result = 1024;

    for(int i=0;i<5;i++)
        result >>= 1;

    if(result != 32)
        test_fail();

    /*--------------------------------------------------
      Shift by Zero
    --------------------------------------------------*/

    result = 0x12345678;

    if((result << 0) != 0x12345678)
        test_fail();

    if((result >> 0) != 0x12345678)
        test_fail();

    /*--------------------------------------------------
      Mixed Shift Operations
    --------------------------------------------------*/

    result = 0x55;

    result <<= 8;

    if(result != 0x5500)
        test_fail();

    result >>= 4;

    if(result != 0x0550)
        test_fail();

    /*--------------------------------------------------
      Compiler-generated variable shifts
    --------------------------------------------------*/

    uint32_t value = 0x10;
    uint32_t shamt = 3;

    if((value << shamt) != 0x80)
        test_fail();

    if((0x80 >> shamt) != 0x10)
        test_fail();

    test_pass();

    return 0;
}