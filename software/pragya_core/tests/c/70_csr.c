#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t a;
volatile uint32_t b;
volatile uint32_t c;
volatile uint32_t d;
volatile uint32_t e;
volatile uint32_t f;

int main(void)
{

/*============================================================*
 * MSTATUS
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x00000008\n"
    "csrrw t1, mstatus, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000008\n"
    "csrrs t1, mstatus, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000008\n"
    "csrrc t1, mstatus, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mstatus, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mstatus, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mstatus, 1\n"
);


/*============================================================*
 * MISA
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x40001100\n"
    "csrrw t1, misa, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000100\n"
    "csrrs t1, misa, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000100\n"
    "csrrc t1, misa, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, misa, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, misa, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, misa, 1\n"
);


/*============================================================*
 * MIE
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x00000888\n"
    "csrrw t1, mie, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000888\n"
    "csrrs t1, mie, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000888\n"
    "csrrc t1, mie, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mie, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mie, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mie, 1\n"
);


/*============================================================*
 * MTVEC
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x80000000\n"
    "csrrw t1, mtvec, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000001\n"
    "csrrs t1, mtvec, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000001\n"
    "csrrc t1, mtvec, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mtvec, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mtvec, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mtvec, 1\n"
);


/*============================================================*
 * MSCRATCH
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x12345678\n"
    "csrrw t1, mscratch, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x0000000F\n"
    "csrrs t1, mscratch, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000003\n"
    "csrrc t1, mscratch, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mscratch, 7\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mscratch, 3\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mscratch, 1\n"
);


/*============================================================*
 * MEPC
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x80000100\n"
    "csrrw t1, mepc, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000004\n"
    "csrrs t1, mepc, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000004\n"
    "csrrc t1, mepc, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mepc, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mepc, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mepc, 1\n"
);


/*============================================================*
 * MCAUSE
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x0000000B\n"
    "csrrw t1, mcause, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000001\n"
    "csrrs t1, mcause, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000001\n"
    "csrrc t1, mcause, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mcause, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mcause, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mcause, 1\n"
);


/*============================================================*
 * MTVAL
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x12345678\n"
    "csrrw t1, mtval, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x0000000F\n"
    "csrrs t1, mtval, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000003\n"
    "csrrc t1, mtval, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mtval, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mtval, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mtval, 1\n"
);


/*============================================================*
 * MIP
 *============================================================*/

/* CSRRW */
asm volatile(
    "li t0, 0x00000888\n"
    "csrrw t1, mip, t0\n"
);

/* CSRRS */
asm volatile(
    "li t0, 0x00000888\n"
    "csrrs t1, mip, t0\n"
);

/* CSRRC */
asm volatile(
    "li t0, 0x00000888\n"
    "csrrc t1, mip, t0\n"
);

/* CSRRWI */
asm volatile(
    "csrrwi t1, mip, 1\n"
);

/* CSRRSI */
asm volatile(
    "csrrsi t1, mip, 1\n"
);

/* CSRRCI */
asm volatile(
    "csrrci t1, mip, 1\n"
);


/*============================================================*
 * READ-ONLY CSR
 *
 * For these CSRs use:
 *
 *   CSRRS  with x0
 *   CSRRC  with x0
 *   CSRRSI with 0
 *   CSRRCI with 0
 *
 * These are read-only accesses and do not attempt to write.
 *============================================================*/


/*============================================================*
 * MVENDORID
 *============================================================*/

asm volatile(
    "csrrs t1, mvendorid, zero\n"
);

asm volatile(
    "csrrc t1, mvendorid, zero\n"
);

asm volatile(
    "csrrsi t1, mvendorid, 0\n"
);

asm volatile(
    "csrrci t1, mvendorid, 0\n"
);


/*============================================================*
 * MARCHID
 *============================================================*/

asm volatile(
    "csrrs t1, marchid, zero\n"
);

asm volatile(
    "csrrc t1, marchid, zero\n"
);

asm volatile(
    "csrrsi t1, marchid, 0\n"
);

asm volatile(
    "csrrci t1, marchid, 0\n"
);


/*============================================================*
 * MIMPID
 *============================================================*/

asm volatile(
    "csrrs t1, mimpid, zero\n"
);

asm volatile(
    "csrrc t1, mimpid, zero\n"
);

asm volatile(
    "csrrsi t1, mimpid, 0\n"
);

asm volatile(
    "csrrci t1, mimpid, 0\n"
);


/*============================================================*
 * MHARTID
 *============================================================*/

asm volatile(
    "csrrs t1, mhartid, zero\n"
);

asm volatile(
    "csrrc t1, mhartid, zero\n"
);

asm volatile(
    "csrrsi t1, mhartid, 0\n"
);

asm volatile(
    "csrrci t1, mhartid, 0\n"
);


/*============================================================*
 * MCYCLE
 *============================================================*/

asm volatile(
    "csrrs t1, mcycle, zero\n"
);

asm volatile(
    "csrrc t1, mcycle, zero\n"
);

asm volatile(
    "csrrsi t1, mcycle, 0\n"
);

asm volatile(
    "csrrci t1, mcycle, 0\n"
);


/*============================================================*
 * MINSTRET
 *============================================================*/

asm volatile(
    "csrrs t1, minstret, zero\n"
);

asm volatile(
    "csrrc t1, minstret, zero\n"
);

asm volatile(
    "csrrsi t1, minstret, 0\n"
);

asm volatile(
    "csrrci t1, minstret, 0\n"
);


/*============================================================*
 * MCYCLEH
 *============================================================*/

asm volatile(
    "csrrs t1, mcycleh, zero\n"
);

asm volatile(
    "csrrc t1, mcycleh, zero\n"
);

asm volatile(
    "csrrsi t1, mcycleh, 0\n"
);

asm volatile(
    "csrrci t1, mcycleh, 0\n"
);


/*============================================================*
 * MINSTRETH
 *============================================================*/

asm volatile(
    "csrrs t1, minstreth, zero\n"
);

asm volatile(
    "csrrc t1, minstreth, zero\n"
);

asm volatile(
    "csrrsi t1, minstreth, 0\n"
);

asm volatile(
    "csrrci t1, minstreth, 0\n"
);


/*============================================================*
 * CYCLE
 *============================================================*/

asm volatile(
    "csrrs t1, cycle, zero\n"
);

asm volatile(
    "csrrc t1, cycle, zero\n"
);

asm volatile(
    "csrrsi t1, cycle, 0\n"
);

asm volatile(
    "csrrci t1, cycle, 0\n"
);


/*============================================================*
 * INSTRET
 *============================================================*/

asm volatile(
    "csrrs t1, instret, zero\n"
);

asm volatile(
    "csrrc t1, instret, zero\n"
);

asm volatile(
    "csrrsi t1, instret, 0\n"
);

asm volatile(
    "csrrci t1, instret, 0\n"
);


/*============================================================*
 * CYCLEH
 *============================================================*/

asm volatile(
    "csrrs t1, cycleh, zero\n"
);

asm volatile(
    "csrrc t1, cycleh, zero\n"
);

asm volatile(
    "csrrsi t1, cycleh, 0\n"
);

asm volatile(
    "csrrci t1, cycleh, 0\n"
);


/*============================================================*
 * INSTRETH
 *============================================================*/

asm volatile(
    "csrrs t1, instreth, zero\n"
);

asm volatile(
    "csrrc t1, instreth, zero\n"
);

asm volatile(
    "csrrsi t1, instreth, 0\n"
);

asm volatile(
    "csrrci t1, instreth, 0\n"
);


/*============================================================*
 * FINAL READS
 *============================================================*/

asm volatile("csrr %0, mstatus"  : "=r"(a));
asm volatile("csrr %0, mie"      : "=r"(b));
asm volatile("csrr %0, mtvec"    : "=r"(c));
asm volatile("csrr %0, mscratch" : "=r"(d));
asm volatile("csrr %0, mepc"     : "=r"(e));
asm volatile("csrr %0, mcause"   : "=r"(f));


/*============================================================*
 * PASS
 *============================================================*/

test_pass();

return 0;
}