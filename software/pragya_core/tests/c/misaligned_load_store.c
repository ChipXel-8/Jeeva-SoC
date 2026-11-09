#include "pragya_test.h"
#include <stdint.h>

/*------------------------------------------
  Exception Log Memory
------------------------------------------*/

volatile uint32_t exception_log[16];

/*
   exception_log[0] = STORE exception MCAUSE
   exception_log[1] = STORE exception MEPC
   exception_log[2] = STORE exception MTVAL

   exception_log[4] = LOAD exception MCAUSE
   exception_log[5] = LOAD exception MEPC
   exception_log[6] = LOAD exception MTVAL
*/

volatile uint32_t trap_count = 0;


/*------------------------------------------
  Trap Handler
------------------------------------------*/

void trap_handler(void)
{
    uint32_t mcause;
    uint32_t mepc;
    uint32_t mtval;
    uint32_t count;

    asm volatile ("csrr %0, mcause" : "=r"(mcause));
    asm volatile ("csrr %0, mepc"   : "=r"(mepc));
    asm volatile ("csrr %0, mtval"  : "=r"(mtval));

    count = trap_count;

    if(count == 0)
    {
        /*----------------------------------
          First exception = Misaligned Store
        ----------------------------------*/

        exception_log[0] = mcause;
        exception_log[1] = mepc;
        exception_log[2] = mtval;
    }
    else if(count == 1)
    {
        /*----------------------------------
          Second exception = Misaligned Load
        ----------------------------------*/

        exception_log[4] = mcause;
        exception_log[5] = mepc;
        exception_log[6] = mtval;
    }

    trap_count = count + 1;

    /*
       Skip the faulting instruction.
       Both SW and LW are 4 bytes.
    */

    mepc = mepc + 4;

    asm volatile ("csrw mepc, %0" :: "r"(mepc));

    asm volatile ("mret");
}


/*==========================================
  MAIN
==========================================*/

int main(void)
{
    uint32_t value = 0x12345678;
    uint32_t loaded_value;

    /*
       Aligned address:
             0x80008000

       Misaligned addresses:
             0x80008001
             0x80008002
             0x80008003
    */

    volatile uint32_t *aligned_addr =
        (volatile uint32_t *)0x80008000;

    volatile uint8_t *misaligned_addr =
        (volatile uint8_t *)0x80008001;


    /*------------------------------------------
      Initialize Memory
    ------------------------------------------*/

    *aligned_addr = 0xAABBCCDD;


    /*------------------------------------------
      MISALIGNED STORE EXCEPTION
    ------------------------------------------*/

    /*
       Generate exactly:

           SW value, 0(t0)

       where:

           t0 = 0x80008001

       SW requires 4-byte alignment.
    */

    asm volatile (
        "mv t0, %0\n"
        "sw %1, 0(t0)\n"
        :
        : "r"(misaligned_addr),
          "r"(value)
        : "t0", "memory"
    );


    /*------------------------------------------
      Check First Exception
    ------------------------------------------*/

    if(trap_count != 1)
        test_fail();

    /*
       MCAUSE = 6
       Store/AMO address misaligned
    */

    if(exception_log[0] != 0x00000006)
        test_fail();

    /*
       MTVAL = address that caused exception
    */

    if(exception_log[2] != 0x80008001)
        test_fail();


    /*------------------------------------------
      MISALIGNED LOAD EXCEPTION
    ------------------------------------------*/

    /*
       Generate exactly:

           LW t1, 0(t0)

       where:

           t0 = 0x80008001

       LW requires 4-byte alignment.
    */

    asm volatile (
        "mv t0, %1\n"
        "lw %0, 0(t0)\n"
        : "=r"(loaded_value)
        : "r"(misaligned_addr)
        : "t0", "memory"
    );


    /*------------------------------------------
      Check Second Exception
    ------------------------------------------*/

    if(trap_count != 2)
        test_fail();

    /*
       MCAUSE = 4
       Load address misaligned
    */

    if(exception_log[4] != 0x00000004)
        test_fail();

    /*
       MTVAL = address that caused exception
    */

    if(exception_log[6] != 0x80008001)
        test_fail();


    /*------------------------------------------
      Final Exception Checks
    ------------------------------------------*/

    /*
       Both are exceptions, not interrupts.
       Therefore bit 31 of MCAUSE must be 0.
    */

    if(exception_log[0] & 0x80000000)
        test_fail();

    if(exception_log[4] & 0x80000000)
        test_fail();


    /*------------------------------------------
      Test Passed
    ------------------------------------------*/

    test_pass();

    return 0;
}