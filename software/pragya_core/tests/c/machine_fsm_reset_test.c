#include <stdint.h>

/*
 * Machine FSM coverage test
 *
 * Intended FSM transitions:
 *
 * RESET       -> OPERATING
 * OPERATING   -> OPERATING
 * OPERATING   -> TRAP_TAKEN
 * TRAP_TAKEN  -> OPERATING
 * OPERATING   -> TRAP_RETURN
 * TRAP_RETURN -> OPERATING
 *
 * The RESET transitions from other states require TB reset injection.
 */

volatile uint32_t test_pass = 0;
volatile uint32_t test_count = 0;


/* ---------------------------------------------------------
 * Read machine CSRs
 * --------------------------------------------------------- */

static inline uint32_t read_mstatus(void)
{
    uint32_t value;
    asm volatile ("csrr %0, mstatus" : "=r"(value));
    return value;
}

static inline uint32_t read_mepc(void)
{
    uint32_t value;
    asm volatile ("csrr %0, mepc" : "=r"(value));
    return value;
}

static inline uint32_t read_mcause(void)
{
    uint32_t value;
    asm volatile ("csrr %0, mcause" : "=r"(value));
    return value;
}

static inline uint32_t read_mtvec(void)
{
    uint32_t value;
    asm volatile ("csrr %0, mtvec" : "=r"(value));
    return value;
}


/* ---------------------------------------------------------
 * Write fixed CSRs
 * --------------------------------------------------------- */

static inline void write_mstatus(uint32_t value)
{
    asm volatile ("csrw mstatus, %0" :: "r"(value));
}

static inline void write_mie(uint32_t value)
{
    asm volatile ("csrw mie, %0" :: "r"(value));
}


/* ---------------------------------------------------------
 * Delay
 * --------------------------------------------------------- */

static void delay(volatile uint32_t count)
{
    while (count--)
        asm volatile ("nop");
}


/* ---------------------------------------------------------
 * Main test
 * --------------------------------------------------------- */

int main(void)
{
    uint32_t mstatus_before;
    uint32_t mstatus_after;
    uint32_t mepc_before;
    uint32_t mcause;
    uint32_t mtvec;

    /*
     * ------------------------------------------------------
     * STEP 1
     * ------------------------------------------------------
     * After reset:
     *
     * STATE_RESET -> STATE_OPERATING
     *
     * Keep the processor executing normal instructions so
     * that STATE_OPERATING -> STATE_OPERATING is exercised.
     */

    delay(20);

    test_count++;

    /* Normal instructions */
    asm volatile ("addi x5, x0, 10");
    asm volatile ("addi x6, x0, 20");
    asm volatile ("add  x7, x5, x6");
    asm volatile ("addi x8, x7, 1");
    asm volatile ("addi x9, x8, 1");

    /*
     * ------------------------------------------------------
     * STEP 2
     * ------------------------------------------------------
     * Read CSRs.
     *
     * This keeps the processor in OPERATING state.
     */

    mstatus_before = read_mstatus();
    mepc_before    = read_mepc();
    mtvec          = read_mtvec();

    test_count++;

    /*
     * ------------------------------------------------------
     * STEP 3
     * ------------------------------------------------------
     * Generate ECALL.
     *
     * This must cause:
     *
     * STATE_OPERATING -> STATE_TRAP_TAKEN
     *
     * The machine control detects:
     *
     * id_valid_in && ecall
     *
     */

    asm volatile ("ecall");

    /*
     * ------------------------------------------------------
     * Execution should reach here after trap handler executes
     * MRET.
     *
     * Trap handler:
     *
     * STATE_TRAP_TAKEN
     *       |
     *       v
     * STATE_OPERATING
     *
     * Then MRET:
     *
     * STATE_OPERATING -> STATE_TRAP_RETURN
     *       |
     *       v
     * STATE_OPERATING
     *
     * depending on your trap.S implementation.
     */

    test_count++;

    /*
     * Normal instructions after return.
     */

    asm volatile ("addi x10, x0, 1");
    asm volatile ("addi x11, x0, 2");
    asm volatile ("add  x12, x10, x11");
    asm volatile ("addi x13, x12, 3");

    /*
     * ------------------------------------------------------
     * STEP 4
     * ------------------------------------------------------
     * Check trap CSRs.
     * ------------------------------------------------------
     */

    mcause = read_mcause();

    /*
     * ECALL from M-mode:
     *
     * mcause = 11
     */

    if ((mcause & 0x7fffffffU) == 11U)
        test_pass++;

    /*
     * ------------------------------------------------------
     * STEP 5
     * ------------------------------------------------------
     * Another ECALL.
     *
     * This gives another opportunity to observe:
     *
     * OPERATING -> TRAP_TAKEN
     * TRAP_TAKEN -> OPERATING
     * OPERATING -> TRAP_RETURN
     * TRAP_RETURN -> OPERATING
     */

    asm volatile ("ecall");

    test_count++;

    /*
     * More normal instructions after return.
     */

    asm volatile ("addi x14, x0, 55");
    asm volatile ("addi x15, x0, 66");
    asm volatile ("add  x16, x14, x15");

    /*
     * ------------------------------------------------------
     * STEP 6
     * ------------------------------------------------------
     * Keep processor in OPERATING state for a while.
     */

    for (volatile uint32_t i = 0; i < 100; i++) {
        asm volatile ("addi x17, x17, 1");
        asm volatile ("addi x18, x18, 1");
    }

    mstatus_after = read_mstatus();

    /*
     * Prevent compiler from optimizing variables away.
     */

    test_pass += (mstatus_before == mstatus_after) ? 1 : 0;
    test_pass += (mepc_before != 0U) ? 1 : 0;
    test_pass += (mtvec != 0U) ? 1 : 0;

    /*
     * ------------------------------------------------------
     * PASS indication
     * ------------------------------------------------------
     */

    if (test_pass >= 3)
        test_pass = 0xCAFEBABEU;
    else
        test_pass = 0xDEADBEEFU;

    /*
     * Stop executing meaningful instructions.
     */

    while (1) {
        asm volatile ("nop");
    }

    return 0;
}
