#include "pragya_test.h"
#include <stdint.h>

/*
 * ============================================================
 * PRAGYA INTERRUPT CROSS COVERAGE TEST
 *
 * Covers:
 *
 *   1. Software interrupt
 *   2. Timer interrupt
 *   3. External interrupt
 *
 * Each interrupt is tested in:
 *
 *   - Direct mode
 *   - Vectored mode
 *
 * Exercises:
 *
 *   MSTATUS.MIE
 *   MIE.MSIE
 *   MIE.MTIE
 *   MIE.MEIE
 *
 * IMPORTANT:
 *
 *   Interrupt request is injected by TESTBENCH.
 *
 *   The TESTBENCH watches IRQ_READY_ADDR and injects the
 *   corresponding interrupt.
 *
 * ============================================================
 */


/* ============================================================
 * TESTBENCH SYNCHRONIZATION
 * ============================================================ */

#define IRQ_READY_ADDR   0x80007FF0UL

#define IRQ_SW_DIRECT    0x00000011UL
#define IRQ_TIMER_DIRECT 0x00000012UL
#define IRQ_EXT_DIRECT   0x00000013UL

#define IRQ_SW_VECTOR    0x00000021UL
#define IRQ_TIMER_VECTOR 0x00000022UL
#define IRQ_EXT_VECTOR   0x00000023UL


/* ============================================================
 * CSR BIT DEFINITIONS
 * ============================================================ */

/* MSTATUS */
#define MSTATUS_MIE      (1UL << 3)

/* MIE */
#define MIE_MSIE         (1UL << 3)
#define MIE_MTIE         (1UL << 7)
#define MIE_MEIE         (1UL << 11)

/* MTVEC */
#define MTVEC_MODE_MASK  0x3UL
#define MTVEC_MODE_DIRECT 0x0UL
#define MTVEC_MODE_VECTOR 0x1UL


/* ============================================================
 * CSR ACCESS
 * ============================================================ */

static inline uint32_t read_mstatus(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x300"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t read_mie(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x304"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline uint32_t read_mtvec(void)
{
    uint32_t value;

    asm volatile (
        "csrr %0, 0x305"
        : "=r"(value)
        :
        : "memory"
    );

    return value;
}


static inline void write_mstatus(uint32_t value)
{
    asm volatile (
        "csrw 0x300, %0"
        :
        : "r"(value)
        : "memory"
    );
}


static inline void write_mie(uint32_t value)
{
    asm volatile (
        "csrw 0x304, %0"
        :
        : "r"(value)
        : "memory"
    );
}


static inline void write_mtvec(uint32_t value)
{
    asm volatile (
        "csrw 0x305, %0"
        :
        : "r"(value)
        : "memory"
    );
}


/* ============================================================
 * TESTBENCH HANDSHAKE
 *
 * IMPORTANT:
 *
 * Do NOT use FENCE here because the current PRAGYA core
 * does not yet handle the FENCE instruction correctly.
 *
 * The volatile store + "memory" clobber is sufficient for
 * the software/testbench handshake used here.
 * ============================================================ */

static inline void notify_tb(uint32_t value)
{
    volatile uint32_t *ready =
        (volatile uint32_t *)IRQ_READY_ADDR;

    *ready = value;

    asm volatile ("" ::: "memory");
}


/* ============================================================
 * DISABLE ALL INTERRUPTS
 * ============================================================ */

static inline void disable_interrupts(void)
{
    /*
     * Disable global machine interrupts.
     */
    write_mstatus(0x00000000UL);

    /*
     * Disable software, timer and external interrupts.
     */
    write_mie(0x00000000UL);

    /*
     * Allow CSR writes to settle before the next test.
     */
    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * ENABLE GLOBAL MACHINE INTERRUPTS
 * ============================================================ */

static inline void enable_global_interrupts(void)
{
    uint32_t mstatus;

    mstatus = read_mstatus();

    mstatus |= MSTATUS_MIE;

    write_mstatus(mstatus);

    asm volatile (
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * CONFIGURE DIRECT MODE
 * ============================================================ */

static inline void configure_direct_mode(void)
{
    uint32_t mtvec;

    mtvec = read_mtvec();

    /*
     * Preserve MTVEC BASE.
     *
     * Clear MODE bits.
     */
    mtvec &= ~MTVEC_MODE_MASK;

    mtvec |= MTVEC_MODE_DIRECT;

    write_mtvec(mtvec);

    asm volatile (
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * CONFIGURE VECTORED MODE
 * ============================================================ */

static inline void configure_vectored_mode(void)
{
    uint32_t mtvec;

    mtvec = read_mtvec();

    /*
     * Preserve MTVEC BASE.
     *
     * Set MODE = 01.
     */
    mtvec &= ~MTVEC_MODE_MASK;

    mtvec |= MTVEC_MODE_VECTOR;

    write_mtvec(mtvec);

    asm volatile (
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * WAIT AFTER INTERRUPT INJECTION
 * ============================================================ */

static inline void wait_for_interrupt(void)
{
    /*
     * The TESTBENCH injects the interrupt after observing
     * IRQ_READY_ADDR.
     *
     * These instructions give the core time to recognize
     * the interrupt, enter the trap handler and execute MRET.
     */
    asm volatile (
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        "nop\n"
        :
        :
        : "memory"
    );
}


/* ============================================================
 * SOFTWARE INTERRUPT - DIRECT MODE
 * ============================================================ */

static void software_direct(void)
{
    disable_interrupts();

    /*
     * MTVEC MODE = 00
     */
    configure_direct_mode();

    /*
     * Enable software interrupt.
     *
     * MIE.MSIE = bit 3
     */
    write_mie(MIE_MSIE);

    /*
     * Enable global machine interrupts.
     *
     * MSTATUS.MIE = bit 3
     */
    enable_global_interrupts();

    /*
     * Tell TESTBENCH:
     *
     * Inject machine software interrupt.
     */
    notify_tb(IRQ_SW_DIRECT);

    /*
     * Wait for:
     *
     * interrupt
     *     ↓
     * trap
     *     ↓
     * handler
     *     ↓
     * MRET
     */
    wait_for_interrupt();
}


/* ============================================================
 * TIMER INTERRUPT - DIRECT MODE
 * ============================================================ */

static void timer_direct(void)
{
    disable_interrupts();

    /*
     * MTVEC MODE = 00
     */
    configure_direct_mode();

    /*
     * Enable timer interrupt.
     *
     * MIE.MTIE = bit 7
     */
    write_mie(MIE_MTIE);

    /*
     * Enable global machine interrupts.
     */
    enable_global_interrupts();

    /*
     * Tell TESTBENCH:
     *
     * Inject machine timer interrupt.
     */
    notify_tb(IRQ_TIMER_DIRECT);

    /*
     * Wait for interrupt and MRET.
     */
    wait_for_interrupt();
}


/* ============================================================
 * EXTERNAL INTERRUPT - DIRECT MODE
 * ============================================================ */

static void external_direct(void)
{
    disable_interrupts();

    /*
     * MTVEC MODE = 00
     */
    configure_direct_mode();

    /*
     * Enable external interrupt.
     *
     * MIE.MEIE = bit 11
     */
    write_mie(MIE_MEIE);

    /*
     * Enable global machine interrupts.
     */
    enable_global_interrupts();

    /*
     * Tell TESTBENCH:
     *
     * Inject machine external interrupt.
     */
    notify_tb(IRQ_EXT_DIRECT);

    /*
     * Wait for interrupt and MRET.
     */
    wait_for_interrupt();
}


/* ============================================================
 * SOFTWARE INTERRUPT - VECTORED MODE
 * ============================================================ */

static void software_vectored(void)
{
    disable_interrupts();

    /*
     * MTVEC MODE = 01
     */
    configure_vectored_mode();

    /*
     * Enable software interrupt.
     */
    write_mie(MIE_MSIE);

    /*
     * Enable global machine interrupts.
     */
    enable_global_interrupts();

    /*
     * Tell TESTBENCH:
     *
     * Inject machine software interrupt.
     */
    notify_tb(IRQ_SW_VECTOR);

    /*
     * Wait for interrupt and MRET.
     */
    wait_for_interrupt();
}


/* ============================================================
 * TIMER INTERRUPT - VECTORED MODE
 * ============================================================ */

static void timer_vectored(void)
{
    disable_interrupts();

    /*
     * MTVEC MODE = 01
     */
    configure_vectored_mode();

    /*
     * Enable timer interrupt.
     */
    write_mie(MIE_MTIE);

    /*
     * Enable global machine interrupts.
     */
    enable_global_interrupts();

    /*
     * Tell TESTBENCH:
     *
     * Inject machine timer interrupt.
     */
    notify_tb(IRQ_TIMER_VECTOR);

    /*
     * Wait for interrupt and MRET.
     */
    wait_for_interrupt();
}


/* ============================================================
 * EXTERNAL INTERRUPT - VECTORED MODE
 * ============================================================ */

static void external_vectored(void)
{
    disable_interrupts();

    /*
     * MTVEC MODE = 01
     */
    configure_vectored_mode();

    /*
     * Enable external interrupt.
     */
    write_mie(MIE_MEIE);

    /*
     * Enable global machine interrupts.
     */
    enable_global_interrupts();

    /*
     * Tell TESTBENCH:
     *
     * Inject machine external interrupt.
     */
    notify_tb(IRQ_EXT_VECTOR);

    /*
     * Wait for interrupt and MRET.
     */
    wait_for_interrupt();
}


/* ============================================================
 * MAIN
 * ============================================================ */

int main(void)
{
    volatile uint32_t value;

    /*
     * ========================================================
     * INITIAL STATE
     * ========================================================
     */

    disable_interrupts();


    /*
     * ========================================================
     * 1. SOFTWARE INTERRUPT - DIRECT
     * ========================================================
     */

    software_direct();


    /*
     * ========================================================
     * 2. TIMER INTERRUPT - DIRECT
     * ========================================================
     */

    timer_direct();


    /*
     * ========================================================
     * 3. EXTERNAL INTERRUPT - DIRECT
     * ========================================================
     */

    external_direct();


    /*
     * ========================================================
     * 4. SOFTWARE INTERRUPT - VECTORED
     * ========================================================
     */

    software_vectored();


    /*
     * ========================================================
     * 5. TIMER INTERRUPT - VECTORED
     * ========================================================
     */

    timer_vectored();


    /*
     * ========================================================
     * 6. EXTERNAL INTERRUPT - VECTORED
     * ========================================================
     */

    external_vectored();


    /*
     * ========================================================
     * FINAL CSR READS
     * ========================================================
     */

    value = read_mstatus();

    value = read_mie();

    value = read_mtvec();

    (void)value;


    /*
     * ========================================================
     * TEST PASS
     * ========================================================
     */

    test_pass();


    /*
     * ========================================================
     * STOP
     * ========================================================
     */

    while (1)
    {
        asm volatile ("nop");
    }

    return 0;
}
