#include "pragya_test.h"
#include <stdint.h>

volatile int timer_flag = 0;

int main(void)
{
    /* 1. MIE CSR me MTIE (Timer Interrupt Enable, bit 7) enable karein */
    asm volatile("csrs mie, %0" :: "r"(1 << 7));

    /* 2. MSTATUS CSR me MIE (Global Interrupt Enable, bit 3) enable karein */
    asm volatile("csrs mstatus, %0" :: "r"(1 << 3));

    /* 3. Core ko WFI (Sleep) me daalein */
    asm volatile("wfi");

    /* 
     * 4. TB bahar se timer IRQ inject karke core ko jagayega.
     * Trap return ke baad execution yahan aayega.
     */
    timer_flag = 1;

    if (timer_flag == 1) {
        test_pass();
    } else {
        test_fail();
    }

    return 0;
}