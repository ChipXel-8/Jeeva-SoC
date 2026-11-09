# RISC-V Toolchain and Verification Setup

This directory documents the software and verification tools used by the Jeeva-SoC / Pragya RISC-V project in the verified Linux environment.

## Setup Guides

1. [RISC-V GNU Toolchain](riscv_gcc_setup.md)
2. [Spike ISA Simulator](spike_setup.md)
3. [RISC-V-DV](riscv_dv_setup.md)

## Verified Server Environment

| Component | Configuration |
|---|---|
| Operating System | CentOS 8 |
| RISC-V Toolchain | GCC 16.1.0 |
| GNU Binutils | 2.46 |
| Toolchain Location | /opt/riscv |
| Compiler Target | riscv32-unknown-linux-gnu |
| Spike | 1.1.1-dev |
| Spike Location | /opt/riscv/bin/spike |
| Python | 3.6.8 |
| RISC-V-DV | chipsalliance/riscv-dv |
| Questa | /opt/modeltech |

## Project ISA and ABI

The project Makefile uses:

```make
ISA ?= rv32im_zicsr_zicntr
ABI ?= ilp32
```

## Project Verification Commands

Run from the project root:

```bash
make c TEST=01_alu_test
make dv DV_TEST=pragya_arithmetic_basic_test SEED=1
make dv_irq DV_TEST=pragya_interrupt_test SEED=1
```

## Important Notes

- The current project Makefile uses absolute paths for GCC and Spike.
- The upstream RISC-V-DV Spike configuration contains an unsupported `--misaligned` option for the installed Spike version.
- The project Makefile invokes Spike directly without that option.
- The RISC-V-DV checkout contains a local source modification. Preserve it unless intentionally reviewed and changed.
- Exact historical GCC and Spike build commands could not be verified from the available account permissions.
- Do not publish institutional license-server addresses or license files.
