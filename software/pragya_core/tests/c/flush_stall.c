#include "pragya_test.h"
#include <stdint.h>

int main(void)
{
    volatile uint32_t *result =
        (volatile uint32_t *)0x80007FF4;

    volatile uint32_t mem_value;

    /*
     * Put a known value in memory.
     */
    *result = 0x12345678;

    /*
     * The compiler must generate a LOAD followed by a
     * taken branch.
     *
     * The important thing is the pipeline overlap:
     *
     *        EX  : taken branch
     *        DE  : load
     *
     * This can create:
     *
     *        branch_taken = 1
     *        mem_req_DE   = 1
     *
     * therefore:
     *
     *        flush_DE = 1
     *        stallD   = 1
     */

    mem_value = *result;

    if (mem_value != 0x12345678)
        test_fail();

    goto branch_target;

    /*
     * Instructions here are younger than the branch.
     * They should be flushed.
     */
    *result = 0xAAAAAAAA;

branch_target:

    /*
     * Make sure execution reached the branch target.
     */
    *result = 0xCAFEBABE;

    mem_value = *result;

    if (mem_value != 0xCAFEBABE)
        test_fail();

    test_pass();

    while (1)
        asm volatile ("nop");

    return 0;
}