# RISC-V GNU Toolchain (GCC) — Installation and Configuration

This guide explains how to download, build, install, configure, and use the RISC-V GNU Compiler Toolchain for the Jeeva-SoC / PRAGYA RISC-V processor verification project.

## 1. Official GitHub Repository

Repository: https://github.com/riscv-collab/riscv-gnu-toolchain

The RISC-V GNU Toolchain provides:
- RISC-V GCC cross-compiler
- GNU assembler and linker
- `objcopy` for generating binary and memory images
- `objdump` for disassembling ELF executables
- Other GNU Binutils utilities

## 2. Prerequisites

### Ubuntu / Debian

```bash
sudo apt update

sudo apt install -y \
    autoconf automake autotools-dev curl \
    python3 python3-pip python3-tomli \
    libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo \
    gperf libtool patchutils bc \
    zlib1g-dev libexpat-dev \
    meson ninja-build git cmake \
    libglib2.0-dev expect device-tree-compiler \
    libslirp-dev libzstd-dev libncurses-dev
```

### CentOS / RHEL / Fedora

For CentOS/RHEL systems with the `yum` package manager:

```bash
sudo yum install -y \
    autoconf automake python3 \
    libmpc-devel mpfr-devel gmp-devel \
    gawk bison flex texinfo patchutils \
    gcc gcc-c++ zlib-devel expat-devel \
    libslirp-devel ncurses-devel \
    meson ninja-build cmake dtc \
    git curl wget
```

On newer Fedora/RHEL systems, use `dnf` instead of `yum`.

## 3. Clone the Repository

Create a directory for the RISC-V tools:

```bash
mkdir -p $HOME/riscv_tools
cd $HOME/riscv_tools
```

Clone the official repository:

```bash
git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
```

Enter the repository:

```bash
cd riscv-gnu-toolchain
```

Check the repository:

```bash
git status
```

## 4. Select Installation Directory

For a user-managed installation, use a directory inside your home folder. This avoids requiring root permission for the build and installation.

```bash
export RISCV=$HOME/riscv
mkdir -p $RISCV
```

For a shared system-wide installation, `/opt/riscv` can be used if you have administrator permission.

## 5. Configure the Toolchain

The project uses a 32-bit RISC-V target.

Configure the toolchain:

```bash
./configure \
    --prefix=$RISCV \
    --with-arch=rv32gc \
    --with-abi=ilp32d \
    --disable-multilib
```

Configuration options:

| Option | Purpose |
|---|---|
| `--prefix` | Installation directory |
| `--with-arch=rv32gc` | Default compiler architecture |
| `--with-abi=ilp32d` | Default compiler ABI |
| `--disable-multilib` | Build a single default library configuration |

**Important:** These are the default toolchain build settings. The project explicitly selects its own ISA and ABI during compilation in Section 9.

## 6. Build and Install

For a Linux-targeting toolchain, build the Linux/glibc toolchain:

```bash
make -j$(nproc) linux
```

The build may take considerable time and disk space.

If you use a different installation directory, ensure that it is writable by your account.

The official toolchain also supports Newlib and Picolibc builds. Select the appropriate target according to your application. Do not substitute a bare-metal toolchain for the project's configured Linux-targeting compiler without checking the executable and linker requirements.

## 7. Configure Environment Variables

Add the toolchain to the current terminal session:

```bash
export RISCV=$HOME/riscv
export PATH=$RISCV/bin:$PATH
```

For persistent configuration, add the same lines to `~/.bashrc`:

```bash
echo 'export RISCV=$HOME/riscv' >> ~/.bashrc
echo 'export PATH=$RISCV/bin:$PATH' >> ~/.bashrc
```

Reload the configuration:

```bash
source ~/.bashrc
```

## 8. Verify the Installation

List the RISC-V GCC executables:

```bash
ls $RISCV/bin/*gcc
```

Check the compiler version:

```bash
riscv32-unknown-linux-gnu-gcc --version
```

Check the compiler target:

```bash
riscv32-unknown-linux-gnu-gcc -dumpmachine
```

Check the installation path:

```bash
which riscv32-unknown-linux-gnu-gcc
```

Check the binutils:

```bash
riscv32-unknown-linux-gnu-objcopy --version
riscv32-unknown-linux-gnu-objdump --version
riscv32-unknown-linux-gnu-ld --version
```

The project uses the `riscv32-unknown-linux-gnu-` executable prefix.

## 9. Project-Specific ISA and ABI Configuration

The Jeeva-SoC / PRAGYA project uses:

```makefile
ISA ?= rv32im_zicsr_zicntr
ABI ?= ilp32
```

Architecture extensions:

- `rv32`: 32-bit RISC-V architecture.
- `i`: Base integer instruction set.
- `m`: Integer multiplication and division.
- `zicsr`: CSR instructions.
- `zicntr`: Counter instructions.
- `ilp32`: 32-bit integer and pointer ABI.

The compiler's default architecture and ABI are not necessarily the same as the project's settings. Therefore, always pass `-march` and `-mabi` explicitly.

## 10. Compiler Configuration Used in the Project

The project's Makefile defines:

```makefile
PREFIX  := /opt/riscv/bin/riscv32-unknown-linux-gnu-

CC      := $(PREFIX)gcc
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
NM      := $(PREFIX)nm
```

The C-test compilation flags are:

```makefile
CFLAGS := \
    -march=$(ISA) \
    -mabi=$(ABI) \
    -mcmodel=medany \
    -mno-relax \
    -ffreestanding \
    -fno-builtin \
    -fno-stack-protector \
    -fno-pic \
    -fno-unwind-tables \
    -fno-asynchronous-unwind-tables \
    -nostdlib \
    -nostartfiles \
    -static \
    -I software/pragya_core/include \
    -Wl,--build-id=none
```

The RISC-V-DV compilation flags are:

```makefile
DV_CFLAGS := \
    -march=$(ISA) \
    -mabi=$(ABI) \
    -mcmodel=medany \
    -mno-relax \
    -nostdlib \
    -nostartfiles \
    -static \
    -Wl,--build-id=none \
    -I$(HOME)/riscv-dv/user_extension
```

These flags configure the compiler for the project's freestanding processor test programs.

## 11. Compile a Simple RISC-V Program

Create a test file:

```bash
nano hello.c
```

Example:

```c
int main(void)
{
    int a = 10;
    int b = 20;
    int c = a + b;

    return c;
}
```

Compile it:

```bash
riscv32-unknown-linux-gnu-gcc \
    -march=rv32im_zicsr_zicntr \
    -mabi=ilp32 \
    -c hello.c -o hello.o
```

Inspect the object:

```bash
riscv32-unknown-linux-gnu-objdump -d hello.o
```

This is a compiler smoke test. It does not verify the project's startup code, linker scripts, or complete RTL execution flow.

## 12. Compile a Project C Test

Go to the project root:

```bash
cd /path/to/Jeeva-SoC_work
```

Run:

```bash
make c TEST=01_alu_test
```

The project Makefile handles:
- C source compilation
- Startup assembly
- Trap handler
- Linker script selection
- ELF generation
- Binary and memory-image generation
- RTL and Spike comparison

## 13. Inspect the Generated ELF

```bash
riscv32-unknown-linux-gnu-objdump \
    -d build/elf/01_alu_test.elf
```

Check the ELF format:

```bash
file build/elf/01_alu_test.elf
```

## 14. Convert ELF to Binary

Extract the `.text` section:

```bash
riscv32-unknown-linux-gnu-objcopy \
    -O binary \
    -j .text \
    build/elf/01_alu_test.elf \
    build/bin/01_alu_test.bin
```

The project uses its conversion scripts to generate the memory files required by the RTL testbench.

## 15. Troubleshooting

### GCC command not found

Check:

```bash
echo $RISCV
echo $PATH
which riscv32-unknown-linux-gnu-gcc
```

Reload:

```bash
source ~/.bashrc
```

### Wrong architecture or ABI

Check the compile command and confirm that it includes:

```bash
-march=rv32im_zicsr_zicntr -mabi=ilp32
```

### Permission denied during installation

Install into a user-writable directory, such as:

```bash
export RISCV=$HOME/riscv
```

Do not try to overwrite a shared `/opt/riscv` installation without administrator permission.

### Missing libraries or build dependencies

Recheck the prerequisites for your Linux distribution and rerun the configure step.

## 16. Reference

Official project:
https://github.com/riscv-collab/riscv-gnu-toolchain

Official build instructions:
https://github.com/riscv-collab/riscv-gnu-toolchain/blob/master/README.md
