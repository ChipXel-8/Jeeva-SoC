#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA MACHINE SOFTWARE INTERRUPT TEST
 *
 * MSTATUS.MIE = bit 3
 * MIE.MSIE    = bit 3
 *
 * Expected:
 *     MCAUSE = 0x80000003
 *
 * The testbench watches IRQ_READY and then asserts the
 * machine software interrupt.
 *
 * IMPORTANT:
 * After MRET, execution must continue through the
 * POST-TRAP TEST section.
 * ============================================================
 */


/* ============================================================
 * CSR ACCESS
 * ============================================================ */

static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mstatus"
        : "=r"(value)
    );

    return value;
}


static inline void write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw mstatus, %0"
        :
        : "r"(value)
        : "memory"
    );
}


static inline uint32_t read_mie(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, mie"
        : "=r"(value)
    );

    return value;
}


static inline void write_mie(uint32_t value)
{
    asm volatile (
        "csrw mie, %0"
        :
        : "r"(value)
        : "memory"
    );
}


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    uint32_t mstatus;
    uint32_t mie;

    /*
     * Testbench communication locations
     */
    volatile uint32_t *irq_ready =
        (volatile uint32_t *)0x80007FF0;

    volatile uint32_t *result =
        (volatile uint32_t *)0x80007FF4;


    /* ========================================================
     * TEST 1
     * Enable global machine interrupts
     * ======================================================== */

    mstatus = read_mstatus();

    mstatus |= (1u << 3);

    write_mstatus(mstatus);


    /* ========================================================
     * TEST 2
     * Enable Machine Software Interrupt
     * ======================================================== */

    mie = read_mie();

    mie |= (1u << 3);

    write_mie(mie);


    /* ========================================================
     * TEST 3
     * Verify MSTATUS.MIE
     * ======================================================== */

    mstatus = read_mstatus();

    if ((mstatus & (1u << 3)) == 0)
    {
        test_fail();
    }


    /* ========================================================
     * TEST 4
     * Verify MIE.MSIE
     * ======================================================== */

    mie = read_mie();

    if ((mie & (1u << 3)) == 0)
    {
        test_fail();
    }


    /* ========================================================
     * TEST 5
     * Tell testbench that the program is ready.
     *
     * TB will assert software interrupt after seeing this.
     * ======================================================== */

    *irq_ready = 1;


    /* ========================================================
     * PRE-TRAP TESTS
     *
     * These instructions execute before the interrupt.
     * ======================================================== */

    volatile uint32_t a;
    volatile uint32_t b;
    volatile uint32_t c;
    volatile uint32_t d;

    a = 0x11111111;

    b = 0x22222222;

    c = a + b;

    if (c != 0x33333333)
    {
        test_fail();
    }

    d = c + 1;

    if (d != 0x33333334)
    {
        test_fail();
    }


    /* ========================================================
     * More instructions before trap.
     * This gives the testbench enough time to assert IRQ.
     * ======================================================== */

    a = 0x12345678;

    b = 0x00000010;

    c = a + b;

    d = c - 1;

    if (d != 0x12345681)
    {
        test_fail();
    }


    /*
     * Store a recognizable value.
     */
    *result = 0x11111111;


    /* ========================================================
     * IMPORTANT
     *
     * DO NOT PUT while(1) HERE.
     *
     * The TB will interrupt the processor asynchronously.
     *
     * When interrupt is taken:
     *
     *       MEPC = interrupted PC
     *       PC   = MTVEC
     *
     * trap_entry executes
     *
     *       MRET
     *
     * Then:
     *
     *       PC = MEPC
     *
     * and execution continues below.
     * ======================================================== */


    /*
     * These instructions are intentionally placed after the
     * irq_ready notification.
     *
     * The interrupt should occur somewhere in this region.
     */

    a = 0xAAAAAAAA;

    b = 0x55555555;

    c = a ^ b;

    d = a & b;

    /*
     * If these execute after MRET, then:
     *
     * c = FFFFFFFF
     * d = 00000000
     */

    if (c != 0xFFFFFFFF)
    {
        test_fail();
    }

    if (d != 0x00000000)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 1
     * Arithmetic
     * ======================================================== */

    a = 100;

    b = 25;

    c = a + b;

    d = c - 5;

    if (d != 120)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 2
     * Logical operations
     * ======================================================== */

    a = 0xF0F0F0F0;

    b = 0x0F0F0F0F;

    c = a | b;

    if (c != 0xFFFFFFFF)
    {
        test_fail();
    }

    d = a & b;

    if (d != 0x00000000)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 3
     * Shift operations
     * ======================================================== */

    a = 0x00000001;

    b = a << 4;

    if (b != 0x00000010)
    {
        test_fail();
    }

    c = b << 4;

    if (c != 0x00000100)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 4
     * More arithmetic
     * ======================================================== */

    a = 0x1000;

    b = 0x0100;

    c = a + b;

    c = c + 0x10;

    c = c - 0x10;

    if (c != 0x1100)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 5
     * Memory STORE / LOAD
     * ======================================================== */

    *result = 0x12345678;

    a = *result;

    if (a != 0x12345678)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 6
     * Another memory operation
     * ======================================================== */

    *result = 0xA5A5A5A5;

    b = *result;

    if (b != 0xA5A5A5A5)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 7
     * Branch / comparison
     * ======================================================== */

    a = 10;

    if (a == 10)
    {
        b = 0x11112222;
    }
    else
    {
        b = 0xFFFFFFFF;
    }

    if (b != 0x11112222)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 8
     * Loop
     * ======================================================== */

    a = 0;

    for (b = 0; b < 10; b++)
    {
        a = a + b;
    }

    /*
     * 0+1+2+...+9 = 45
     */

    if (a != 45)
    {
        test_fail();
    }


    /* ========================================================
     * POST-TRAP TEST 9
     * More register operations
     * ======================================================== */

    a = 0x11111111;

    b = 0x22222222;

    c = a + b;

    d = c ^ 0xFFFFFFFF;

    if (d != 0xCCCCCCCC)
    {
        test_fail();
    }


    /* ========================================================
     * FINAL TEST
     *
     * Reaching here proves:
     *
     * 1. Software interrupt was taken
     * 2. trap_entry executed
     * 3. MCAUSE was written
     * 4. MEPC was written
     * 5. MRET executed
     * 6. PC returned to interrupted program
     * 7. Instructions after MRET executed
     * 8. Arithmetic continued correctly
     * 9. Load/store continued correctly
     * 10. Branches/loops continued correctly
     * ======================================================== */

    *result = 0xCAFEBABE;


    /*
     * Final successful value.
     */
    volatile uint32_t final_value;

    final_value = *result;

    if (final_value != 0xCAFEBABE)
    {
        test_fail();
    }


    /*
     * Return to _start.
     *
     * Your existing _start code should write the return value
     * to the test result location.
     */

    return 0;
}
