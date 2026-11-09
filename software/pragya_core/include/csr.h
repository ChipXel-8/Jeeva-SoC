#ifndef PRAGYA_CSR_H
#define PRAGYA_CSR_H


#define CSR_MSTATUS   0x300
#define CSR_MISA      0x301
#define CSR_MIE       0x304
#define CSR_MTVEC     0x305

#define CSR_MSCRATCH  0x340
#define CSR_MEPC      0x341
#define CSR_MCAUSE    0x342
#define CSR_MTVAL     0x343
#define CSR_MIP       0x344

#define CSR_MVENDORID 0xF11
#define CSR_MARCHID   0xF12
#define CSR_MIMPID    0xF13
#define CSR_MHARTID   0xF14
// --- DEBUG CSRs ---
#define CSR_DCSR      0x7B0
#define CSR_DPC       0x7B1
#define CSR_DSCRATCH0 0x7B2
#define CSR_DSCRATCH1 0x7B3

#define read_csr(reg)                         \
({                                            \
    unsigned long __tmp;                      \
    asm volatile ("csrr %0, " #reg            \
                  : "=r"(__tmp));             \
    __tmp;                                    \
})


#define write_csr(reg, value)                 \
do {                                          \
    unsigned long __tmp = (unsigned long)(value); \
    asm volatile ("csrw " #reg ", %0"         \
                  :                           \
                  : "rK"(__tmp));             \
} while (0)


#define set_csr(reg, bit)                     \
do {                                          \
    unsigned long __tmp = (unsigned long)(bit); \
    asm volatile ("csrs " #reg ", %0"         \
                  :                           \
                  : "rK"(__tmp));             \
} while (0)


#define clear_csr(reg, bit)                   \
do {                                          \
    unsigned long __tmp = (unsigned long)(bit); \
    asm volatile ("csrc " #reg ", %0"         \
                  :                           \
                  : "rK"(__tmp));             \
} while (0)


#endif
