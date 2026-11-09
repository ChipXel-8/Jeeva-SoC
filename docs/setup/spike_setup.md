# Spike RISC-V ISA Simulator — Installation and Configuration

This guide explains how to clone, build, install, configure, and use Spike for functional verification of the PRAGYA RISC-V processor.

Spike acts as the Instruction Set Simulator (ISS). The project uses it as a reference model to compare the architectural execution of the RTL processor against a software model.

## 1. Official GitHub Repository

Repository:

https://github.com/riscv-software-src/riscv-isa-sim

Spike supports RISC-V instruction set simulation, including RV32I, RV32M, Zicsr, Zicntr, and machine-mode execution.

## 2. Prerequisites

Spike requires a C++ build environment and supporting libraries.

### Ubuntu / Debian

```bash
sudo apt update

sudo apt install -y \
    git build-essential \
    autoconf automake libtool \
    device-tree-compiler \
    libboost-regex-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    zlib1g-dev
```

### CentOS / RHEL

```bash
sudo yum install -y \
    git gcc gcc-c++ make \
    autoconf automake libtool \
    device-tree-compiler \
    boost-devel \
    zlib-devel
```

For newer systems, use `dnf` instead of `yum`.

The exact package names may vary by distribution and repository configuration. Install the development packages, not only the runtime libraries.

## 3. Configure the RISC-V Installation Directory

Spike is installed alongside the RISC-V GNU toolchain.

For a user-managed installation:

```bash
export RISCV=$HOME/riscv
mkdir -p $RISCV
```

For a shared installation, an administrator can use:

```bash
export RISCV=/opt/riscv
```

Ensure that the selected installation directory is writable by the account performing installation.

## 4. Clone the Official Spike Repository

Create a source directory:

```bash
mkdir -p $HOME/riscv_tools
cd $HOME/riscv_tools
```

Clone Spike:

```bash
git clone https://github.com/riscv-software-src/riscv-isa-sim.git
```

Enter the source directory:

```bash
cd riscv-isa-sim
```

Initialize the submodules:

```bash
git submodule update --init --recursive
```

## 5. Configure Spike with Commit Logging

The PRAGYA verification flow compares instruction commit information from RTL and Spike.

Therefore, Spike must be built with commit logging enabled.

Create a separate build directory:

```bash
mkdir build
cd build
```

Configure the build:

```bash
../configure \
    --prefix=$RISCV \
    --enable-commitlog
```

The important option is:

```bash
--enable-commitlog
```

This enables commit logging at compile time. Runtime logging must also be enabled with `--log-commits`.

Without this build option, Spike may report:

```text
Commit logging support has not been properly enabled;
please re-build the riscv-isa-sim project using
"configure --enable-commitlog".
```

## 6. Build Spike

Compile using the available processor cores:

```bash
make -j$(nproc)
```

Install:

```bash
make install
```

If the installation directory requires administrator privileges, use an administrator-managed installation procedure rather than changing permissions on a shared installation.

## 7. Configure Environment Variables

Add the installation directory to `PATH`:

```bash
export RISCV=$HOME/riscv
export PATH=$RISCV/bin:$PATH
```

For persistent configuration, add these lines to `~/.bashrc`:

```bash
echo 'export RISCV=$HOME/riscv' >> ~/.bashrc
echo 'export PATH=$RISCV/bin:$PATH' >> ~/.bashrc
```

Reload:

```bash
source ~/.bashrc
```

Set the Spike path variable:

```bash
export SPIKE_PATH=$RISCV/bin
```

Persist it:

```bash
echo 'export SPIKE_PATH=$RISCV/bin' >> ~/.bashrc
```

Reload:

```bash
source ~/.bashrc
```

`SPIKE_PATH` is used by tools such as RISC-V-DV to locate the Spike executable. The project Makefile can also specify the full executable path directly.

## 8. Verify the Installation

Check the executable:

```bash
which spike
```

Check the Spike version banner:

```bash
spike --help
```

Check the commit logging option:

```bash
spike --help | grep -E 'log-commits|isa|priv'
```

Confirm that the installed executable is the one you expect:

```bash
ls -l $RISCV/bin/spike
```

## 9. Spike Configuration Used in the PRAGYA Project

The project uses the following configuration:

```makefile
ISA        ?= rv32im_zicsr_zicntr
ABI        ?= ilp32
SPIKE_MAX  ?= 100000

SPIKE := /opt/riscv/bin/spike
```

The project Makefile selects Spike explicitly:

```makefile
SPIKE := /opt/riscv/bin/spike
```

If using a different installation directory, update this path to the location of your Spike executable.

## 10. Spike Command Used for C-Test Verification

The project invokes Spike with:

```bash
$(SPIKE) \
    --isa=$(ISA) \
    --priv=m \
    --disable-dtb \
    --pc=0x80000000 \
    --instructions=$(SPIKE_MAX) \
    -l \
    --log-commits \
    $(SPIKE_ELF)
```

Explanation:

| Option | Purpose |
|---|---|
| `--isa` | Selects the supported RISC-V ISA |
| `--priv=m` | Enables machine-mode execution |
| `--disable-dtb` | Disables device-tree generation |
| `--pc=0x80000000` | Sets the initial program counter |
| `--instructions` | Limits the number of simulated instructions |
| `-l` | Enables instruction logging |
| `--log-commits` | Enables architectural commit logging |
| ELF argument | Program to execute |

The initial PC and memory map must match the project's linker scripts and RTL memory configuration.

## 11. Spike Command Used for RISC-V-DV Verification

The project uses a separate ELF for Spike execution.

The command is:

```bash
$(SPIKE) \
    --isa=$(ISA) \
    --priv=m \
    --disable-dtb \
    --pc=0x80000000 \
    -l \
    --log-commits \
    $(DV_SPIKE_ELF)
```

The RTL and Spike executables are linked separately because their memory layouts are different.

The Spike ELF is generated using:

```makefile
DV_SPIKE_LD := software/pragya_core/linker/pragya_dv_spike.ld
```

## 12. Run Spike on a Project Test

First, build the test:

```bash
make c TEST=01_alu_test
```

Run Spike manually:

```bash
/opt/riscv/bin/spike \
    --isa=rv32im_zicsr_zicntr \
    --priv=m \
    --disable-dtb \
    --pc=0x80000000 \
    --instructions=100000 \
    -l \
    --log-commits \
    build/elf/01_alu_test_spike.elf
```

The actual project Makefile manages log files and the test termination procedure.

For the complete verification flow, run:

```bash
make c TEST=01_alu_test
```

## 13. Commit Log and RTL Comparison

Spike generates architectural execution information using:

```bash
--log-commits
```

The project stores the raw Spike log and processes it into a comparison log.

The C-test flow uses:

```text
results/logs/spike/
results/logs/core/
results/logs/compare/
```

The comparison script checks the architectural commit information from the RTL and Spike executions.

The project also uses a `tohost` memory marker to identify test completion. In this flow, the expected marker is:

```text
mem 0x80008000 0x00000001
```

This termination behavior belongs to the project's custom runner; it is not a general requirement for every Spike application.

## 14. Important Compatibility Note: RISC-V-DV and --misaligned

The upstream RISC-V-DV Spike configuration may invoke Spike with:

```bash
--misaligned
```

However, the installed Spike version on the verified server does not accept this option.

The observed error is:

```text
unrecognized option --misaligned
```

Setting `SPIKE_PATH` only helps RISC-V-DV locate the executable. It does not add support for an unsupported command-line option.

The PRAGYA project therefore invokes Spike directly through its Makefile using the supported options:

```bash
--isa=$(ISA) \
--priv=m \
--disable-dtb \
--pc=0x80000000 \
-l \
--log-commits
```

Do not assume that the upstream RISC-V-DV ISS configuration and the project's custom Spike runner are interchangeable. Check compatibility before changing the upstream configuration or replacing the installed Spike executable.

## 15. Troubleshooting

### Spike command not found

Check:

```bash
echo $RISCV
echo $PATH
which spike
```

Add the installation directory:

```bash
export PATH=$RISCV/bin:$PATH
```

### Commit logging is unavailable

Reconfigure and rebuild Spike:

```bash
cd $HOME/riscv_tools/riscv-isa-sim/build
../configure --prefix=$RISCV --enable-commitlog
make -j$(nproc)
make install
```

Then check that the runtime command includes:

```bash
--log-commits
```

### Unsupported command-line option

Check the installed executable:

```bash
spike --help
```

Do not copy options from a different Spike version without checking support.

### Wrong initial PC or memory layout

Verify that the Spike linker script and initial PC agree:

```text
software/pragya_core/linker/pragya_spike.ld
software/pragya_core/linker/pragya_dv_spike.ld
```

### Permission denied during installation

Install into a user-writable directory such as:

```bash
export RISCV=$HOME/riscv
```

Do not overwrite the shared `/opt/riscv` installation without administrator permission.

## 16. Reference

Official Spike repository:

https://github.com/riscv-software-src/riscv-isa-sim

Official build instructions:

https://github.com/riscv-software-src/riscv-isa-sim#build-steps
