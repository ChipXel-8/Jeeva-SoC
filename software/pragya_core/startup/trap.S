.section .text.trap
.align 2

.globl trap_entry
.type trap_entry, @function

trap_entry:

    csrr t0, mcause
    csrr t1, mepc
    csrr t2, mtval

    la t3, _signature_start

    sw t0, 4(t3)
    sw t1, 8(t3)
    sw t2, 12(t3)

    /*
     * INTERRUPT CHECK (Bit 31 is 1)
     * Agar t0 negative hai (MSB = 1), toh yeh Interrupt hai
     */
    bgez t0, check_exceptions

    /*
     * Yahan tab aayega jab INTERRUPT aayega (Timer / External / Software)
     * WFI se aage nikalne ke liye mepc ko next instruction par point karein
     */
    j trap_skip_instruction

check_exceptions:
    /*
     * ECALL = 11
     */
    li t3, 11
    beq t0, t3, trap_skip_instruction

    /*
     * EBREAK = 3
     */
    li t3, 3
    beq t0, t3, trap_skip_instruction

    /*
     * ILLEGAL INSTRUCTION = 2
     */
    li t3, 2
    beq t0, t3, trap_skip_instruction

    /*
     * INSTRUCTION ADDRESS MISALIGNED = 0
     */
    li t3, 0
    beq t0, t3, trap_skip_instruction

    /*
     * Other traps:
     * return without changing MEPC.
     */
    j trap_return


trap_skip_instruction:

    addi t1, t1, 4
    csrw mepc, t1


trap_return:

    mret

.size trap_entry, .-trap_entry
