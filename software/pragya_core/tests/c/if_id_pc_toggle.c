#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 *              IF/ID REGISTER TOGGLE TEST
 * ============================================================
 *
 * Purpose:
 *
 *   Exercise:
 *
 *       pc_out
 *       pc_plus_4_pipline1_out
 *
 * particularly:
 *
 *       [1:0]
 *       [15:30]
 *
 * Also exercise:
 *
 *       if_valid
 *       stall_d
 *       flush
 *
 * ============================================================
 */


/* ------------------------------------------------------------
 * Prevent compiler from removing the operations
 * ------------------------------------------------------------ */

static volatile uint32_t sink;


/* ------------------------------------------------------------
 * Simple instruction blocks
 * ------------------------------------------------------------ */

__attribute__((noinline))
static void block_1(void)
{
    volatile uint32_t a = 0x11111111;

    a ^= 0xAAAAAAAA;
    a += 0x12345678;
    a ^= 0x55555555;

    sink = a;
}


__attribute__((noinline))
static void block_2(void)
{
    volatile uint32_t a = 0x22222222;

    a ^= 0xAAAAAAAA;
    a += 0x87654321;
    a ^= 0x55555555;

    sink = a;
}


__attribute__((noinline))
static void block_3(void)
{
    volatile uint32_t a = 0x33333333;

    a ^= 0xAAAAAAAA;
    a += 0x13572468;
    a ^= 0xAAAAAAAA;

    sink = a;
}


__attribute__((noinline))
static void block_4(void)
{
    volatile uint32_t a = 0x44444444;

    a ^= 0x55555555;
    a += 0x24681357;
    a ^= 0xAAAAAAAA;

    sink = a;
}


/* ------------------------------------------------------------
 * Main
 * ------------------------------------------------------------ */

int main(void)
{

    /*
     * ========================================================
     * Sequential execution
     *
     * Exercises normal IF -> ID transfer.
     *
     * PC increments:
     *
     * 00 -> 04 -> 08 -> 0C -> ...
     *
     * This exercises PC[1:0].
     * ========================================================
     */

    block_1();
    block_2();
    block_3();
    block_4();


    /*
     * ========================================================
     * More sequential instructions
     *
     * Increase the number of PC transitions.
     * ========================================================
     */

    for (volatile uint32_t i = 0; i < 64; i++)
    {
        sink = i;
        sink += 0x12345678;
        sink ^= 0xAAAAAAAA;
        sink ^= 0x55555555;
    }


    /*
     * ========================================================
     * Branch transitions
     *
     * These exercise PC changes through the fetch path.
     * ========================================================
     */

    for (volatile uint32_t i = 0; i < 8; i++)
    {
        if (i & 1)
        {
            block_1();
        }
        else
        {
            block_2();
        }
    }


    /*
     * ========================================================
     * Jump/call transitions
     * ========================================================
     */

    block_3();
    block_4();
    block_1();
    block_2();


    /*
     * ========================================================
     * More instructions to create additional PC transitions
     * ========================================================
     */

    for (volatile uint32_t i = 0; i < 128; i++)
    {
        sink = i * 4;
        sink = sink + 1;
        sink = sink ^ 0xFFFFFFFF;
        sink = sink + 0x1000;
    }


    /*
     * ========================================================
     * PASS
     * ========================================================
     */

    test_pass();

    while (1)
    {
        asm volatile("nop");
    }

    return 0;
}
