#ifndef PRAGYA_H
#define PRAGYA_H

#include <stdint.h>


/*
 * ============================================================
 * Pragya processor configuration
 * ============================================================
 */

#define PRAGYA_XLEN       32

#define PRAGYA_IMEM_BASE  0x00000000UL
#define PRAGYA_IMEM_SIZE  0x00008000UL

#define PRAGYA_DMEM_BASE  0x00008000UL
#define PRAGYA_DMEM_SIZE  0x00008000UL


/*
 * ============================================================
 * Test result values
 * ============================================================
 */

#define PRAGYA_TEST_PASS  0
#define PRAGYA_TEST_FAIL  1


/*
 * Prevent compiler from optimizing a value away.
 */

#define PRAGYA_BARRIER() \
    asm volatile ("" ::: "memory")


static inline void pragya_nop(void)
{
    asm volatile ("nop");
}


#endif
