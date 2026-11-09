#include "pragya_test.h"
#include <stdint.h>

/*
 * Directed Load/Store Verification Test
 *
 * Instructions exercised:
 *  LB
 *  LBU
 *  LH
 *  LHU
 *  LW
 *  SB
 *  SH
 *  SW
 */

volatile uint8_t mem[64];

int main(void)
{
    volatile int8_t   lb;
    volatile uint8_t  lbu;
    volatile int16_t  lh;
    volatile uint16_t lhu;
    volatile int32_t  lw;

    /*----------------------------------------------------
      Word Stores
    ----------------------------------------------------*/

    *(volatile uint32_t *)&mem[0] = 0x12345678;
    *(volatile uint32_t *)&mem[4] = 0x89ABCDEF;

    /*----------------------------------------------------
      Byte Store
    ----------------------------------------------------*/

    *(volatile uint8_t *)&mem[8] = 0xAA;

    /*----------------------------------------------------
      Half-word Store
    ----------------------------------------------------*/

    *(volatile uint16_t *)&mem[10] = 0x55CC;

    /*----------------------------------------------------
      Word Store
    ----------------------------------------------------*/

    *(volatile uint32_t *)&mem[12] = 0xCAFEBABE;

    /*----------------------------------------------------
      LB
    ----------------------------------------------------*/

    lb = *(volatile int8_t *)&mem[0];

    if(lb != (int8_t)0x78)
        test_fail();

    lb = *(volatile int8_t *)&mem[7];

    if(lb != (int8_t)0x89)
        test_fail();

    /*----------------------------------------------------
      LBU
    ----------------------------------------------------*/

    lbu = *(volatile uint8_t *)&mem[7];

    if(lbu != 0x89)
        test_fail();

    /*----------------------------------------------------
      LH
    ----------------------------------------------------*/

    lh = *(volatile int16_t *)&mem[0];

    if(lh != (int16_t)0x5678)
        test_fail();

    /*----------------------------------------------------
      LHU
    ----------------------------------------------------*/

    lhu = *(volatile uint16_t *)&mem[0];

    if(lhu != 0x5678)
        test_fail();

    /*----------------------------------------------------
      LW
    ----------------------------------------------------*/

    lw = *(volatile int32_t *)&mem[0];

    if(lw != 0x12345678)
        test_fail();

    lw = *(volatile int32_t *)&mem[12];

    if(lw != (int32_t)0xCAFEBABE)
        test_fail();

    /*----------------------------------------------------
      Verify Stores
    ----------------------------------------------------*/

    if(mem[8] != 0xAA)
        test_fail();

    if(mem[10] != 0xCC)
        test_fail();

    if(mem[11] != 0x55)
        test_fail();

    test_pass();

    return 0;
}