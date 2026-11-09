#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * REMAINING CSR FUNCTIONAL COVERAGE
 *
 * Covers:
 *
 * 1. cp_mtvec_mode
 *       mtvec_vectored = 2'b01
 *
 * 2. cp_csr_wdata
 *       ones = 32'hFFFFFFFF
 *
 * ============================================================
 */


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t value;


    /*
     * ========================================================
     * 1. COVER MTVEC VECTORED MODE
     *
     * mtvec_mode = csr_wdata[1:0]
     *
     * Write:
     *
     *     0x80000001
     *
     * Lower two bits:
     *
     *     01
     *
     * Therefore:
     *
     *     mtvec_mode = 2'b01
     * ========================================================
     */

    asm volatile (
        "li t0, 0x80000001\n"
        "csrrw t1, 0x305, t0\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * ========================================================
     * IMPORTANT:
     *
     * Execute another CSR instruction after the MTVEC write.
     *
     * This allows the coverage sampler to observe the updated
     * mtvec_mode = 01.
     * ========================================================
     */

    asm volatile (
        "csrr t1, 0x305\n"
        :
        :
        : "t1", "memory"
    );


    /*
     * ========================================================
     * 2. COVER csr_wdata = 0xFFFFFFFF
     *
     * Put FFFFFFFF into a register.
     *
     * Then use CSRRW with that register.
     *
     * Therefore:
     *
     *     csr_data_in = 0xFFFFFFFF
     *
     * and:
     *
     *     cp_csr_wdata -> ones
     * ========================================================
     */

    asm volatile (
        "li t0, -1\n"
        "csrrw t1, 0x340, t0\n"
        :
        :
        : "t0", "t1", "memory"
    );


    /*
     * ========================================================
     * Another CSR instruction so coverage sees the state.
     * ========================================================
     */

    asm volatile (
        "csrr t1, 0x340\n"
        :
        :
        : "t1", "memory"
    );


    /*
     * ========================================================
     * PASS
     * ========================================================
     */

    value = 0;

    (void)value;

    test_pass();

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}