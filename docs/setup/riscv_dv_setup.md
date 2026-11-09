# RISC-V-DV — Installation, Configuration and Execution

This guide explains how to install and configure the RISC-V-DV verification environment and integrate it with the PRAGYA RISC-V core.

RISC-V-DV is a random instruction generator. It generates assembly programs that can be compiled and executed on the RTL processor and an Instruction Set Simulator (Spike). The resulting architectural commit logs are compared to identify functional differences.

## 1. Official GitHub Repository

Repository:

https://github.com/chipsalliance/riscv-dv

Clone the official repository:

```bash
git clone https://github.com/chipsalliance/riscv-dv.git
```

Official documentation:

https://github.com/chipsalliance/riscv-dv

## 2. Prerequisites

The RISC-V-DV environment requires:

- Python 3
- Git
- RISC-V GNU Compiler Toolchain
- Spike ISA Simulator
- QuestaSim or another supported simulator
- UVM support in the selected simulator

The verified shared-server environment uses:

| Component | Configuration |
|---|---|
| Operating system | CentOS Linux 8.5.2111 |
| Python | 3.6.8 |
| Git | 2.27.0 |
| RISC-V-DV | Commit `b7a0b4b0b51346a3c64f159f81ea262d867c14a9` |
| GCC | 16.1.0 |
| Spike | 1.1.1-dev |
| Simulator | QuestaSim |
| Questa installation | `/opt/modeltech` |
| UVM | 1.2 |

## 3. Install System Dependencies

### Ubuntu / Debian

```bash
sudo apt update

sudo apt install -y \
    git python3 python3-pip python3-venv \
    make gcc g++ \
    perl
```

### CentOS / RHEL

```bash
sudo yum install -y \
    git python3 python3-pip \
    make gcc gcc-c++ \
    perl
```

The simulator, RISC-V toolchain, and Spike must also be installed and accessible.

## 4. Clone RISC-V-DV

Create a workspace:

```bash
mkdir -p $HOME
cd $HOME
```

Clone the repository:

```bash
git clone https://github.com/chipsalliance/riscv-dv.git
```

Enter the repository:

```bash
cd $HOME/riscv-dv
```

Check the repository:

```bash
git remote -v
git status
```

The verified server checkout uses:

```text
https://github.com/chipsalliance/riscv-dv.git
```

The verified revision is:

```text
b7a0b4b0b51346a3c64f159f81ea262d867c14a9
```

To check the current revision:

```bash
git rev-parse HEAD
```

To check the latest available upstream changes:

```bash
git fetch origin
git log -1 origin/master
```

Do not automatically reset an existing checkout to the latest upstream revision. The project may depend on local configuration changes.

## 5. Install Python Dependencies

Go to the RISC-V-DV repository:

```bash
cd $HOME/riscv-dv
```

Inspect the dependency list:

```bash
cat requirements.txt
```

The repository requirements include:

```text
PyYAML
bitstring
Sphinx
Pallets-Sphinx-Themes
sphinxcontrib-log-cabinet
sphinx-issues
sphinx_rtd_theme
rst2pdf
flake8
pyvsc
tabulate
pandas
```

Install dependencies in a dedicated Python environment when setting up a new machine.

Example:

```bash
python3 -m venv $HOME/riscv-dv-venv
```

Activate it:

```bash
source $HOME/riscv-dv-venv/bin/activate
```

Upgrade pip where supported:

```bash
python3 -m pip install --upgrade pip
```

Install repository dependencies:

```bash
python3 -m pip install -r requirements.txt
```

Verify important packages:

```bash
python3 -m pip show PyYAML bitstring pyvsc tabulate pandas
```

Verify imports:

```bash
python3 -c "import yaml, bitstring, vsc, tabulate, pandas; print('Python dependencies OK')"
```

**Python compatibility:** The verified server uses Python 3.6.8 and has an existing set of compatible packages. Newer Python package releases may no longer support Python 3.6. For a fresh installation, select a Python version supported by the RISC-V-DV revision being used and install compatible dependency versions. Do not blindly upgrade packages in a shared server environment.

## 6. Configure the RISC-V GNU Toolchain

The project uses:

```bash
export RISCV=/opt/riscv
export PATH=$RISCV/bin:$PATH
```

Compiler prefix:

```bash
export CROSS_COMPILE=$RISCV/bin/riscv32-unknown-linux-gnu-
```

Verify:

```bash
${CROSS_COMPILE}gcc --version
${CROSS_COMPILE}objcopy --version
${CROSS_COMPILE}objdump --version
```

## 7. Configure Spike

Set the Spike installation directory:

```bash
export SPIKE_PATH=/opt/riscv/bin
```

Verify:

```bash
which spike
spike --help
```

The verified server uses:

```text
/opt/riscv/bin/spike
```

Spike must be built with commit logging enabled for the project's architectural comparison flow.

## 8. Configure QuestaSim

The verified server uses:

```bash
export QUESTA_HOME=/opt/modeltech
```

Add the simulator executable directory to `PATH`:

```bash
export PATH=$QUESTA_HOME/linux_x86_64:$PATH
```

Verify:

```bash
which vsim
vsim -version
```

The verified UVM library location is:

```text
/opt/modeltech/uvm-1.2
```

The project's RISC-V-DV simulator configuration uses this UVM library.

For a new installation, use a Questa version and UVM library compatible with the selected RISC-V-DV revision and the project's SystemVerilog testbench.

## 9. Configure Environment Variables Permanently

For the verified shared-server environment, the main variables are:

```bash
export RISCV=/opt/riscv
export PATH=$RISCV/bin:$PATH

export SPIKE_PATH=$RISCV/bin

export QUESTA_HOME=/opt/modeltech
export PATH=$QUESTA_HOME/linux_x86_64:$PATH
```

Add the configuration to `~/.bashrc` if it is not already present. Avoid appending duplicate entries each time the setup is performed.

Reload:

```bash
source ~/.bashrc
```

Verify:

```bash
echo $RISCV
echo $SPIKE_PATH
echo $QUESTA_HOME
which spike
which vsim
```

## 10. Understand the RISC-V-DV Directory Structure

The upstream repository contains the generator, configuration files, simulator configuration, and test infrastructure.

Important upstream locations include:

```text
riscv-dv/
├── run.py
├── requirements.txt
├── src/
├── yaml/
├── scripts/
├── user_extension/
└── test/
```

Important files:

| File | Purpose |
|---|---|
| `run.py` | Main RISC-V-DV execution script |
| `requirements.txt` | Python dependencies |
| `src/` | Instruction generator and verification infrastructure |
| `yaml/simulator.yaml` | Simulator configuration |
| `yaml/iss.yaml` | ISS configuration |
| `user_extension/` | User-defined instruction extensions |

## 11. Project-Specific RISC-V-DV Configuration

The PRAGYA project keeps its own target, testlists, linker scripts, and conversion scripts.

Important project paths:

```text
verification/pragya_core/riscv_dv/
├── config/
│   ├── riscv_core_setting.sv
│   └── riscvOVPsim.ic
├── pragya/
│   └── rv32i/
│       ├── pragya_testlist.yaml
│       ├── testlist.yaml
│       ├── riscv_core_setting.sv
│       └── riscvOVPsim.ic
└── testlists/
    ├── pragya_testlist.yaml
    └── testlist.yaml
```

The project-specific target directory is:

```makefile
DV_TARGET_DIR := $(CURDIR)/verification/pragya_core/riscv_dv/pragya/rv32i
```

The project testlist is:

```makefile
DV_TESTLIST := $(CURDIR)/verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml
```

The RISC-V-DV script is:

```makefile
RISCV_DV_RUN := $(HOME)/riscv-dv/run.py
```

These paths must match the actual location of the repository and project files on the machine.

## 12. Configure ISA and ABI

The project uses:

```makefile
ISA ?= rv32im_zicsr_zicntr
ABI ?= ilp32
```

This configuration selects:

- RV32 base integer instructions
- Multiplication and division extension
- CSR instructions
- Counter instructions
- 32-bit integer ABI

The same ISA and ABI must be used consistently by the generator, compiler, linker scripts, and Spike.

## 13. Configure the RISC-V-DV Testlist

The project testlist is:

```text
verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml
```

It defines the tests available for generation.

The test used in the verified flow is:

```text
pragya_arithmetic_basic_test
```

Inspect the testlist before running:

```bash
cat verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml
```

The selected test name must match an entry in the testlist.

## 14. Generate Random Assembly Tests

The project Makefile defines:

```makefile
RISCV_DV_RUN  := $(HOME)/riscv-dv/run.py
DV_TARGET_DIR := $(CURDIR)/verification/pragya_core/riscv_dv/pragya/rv32i
DV_TESTLIST   := $(CURDIR)/verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml
```

The generation command is:

```bash
python3 $(HOME)/riscv-dv/run.py \
    -ct verification/pragya_core/riscv_dv/pragya/rv32i \
    -tl verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml \
    -tn pragya_arithmetic_basic_test \
    -i 1 \
    -si questa \
    --isa rv32im_zicsr_zicntr \
    -m ilp32 \
    -o build/riscv_dv/pragya_arithmetic_basic_test_seed1 \
    -s gen \
    --seed 1 \
    -v
```

The project normally runs generation through its Makefile:

```bash
make dv_gen DV_TEST=pragya_arithmetic_basic_test SEED=1
```

The generated assembly file is placed under:

```text
build/riscv_dv/<test>_seed<seed>/asm_test/
```

For example:

```text
build/riscv_dv/pragya_arithmetic_basic_test_seed1/asm_test/
```

## 15. Compile Generated Assembly

The project creates separate executables for RTL and Spike.

The RISC-V-DV compiler flags are:

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

The linker scripts are:

```makefile
DV_RTL_LD   := software/pragya_core/linker/pragya_dv_rtl.ld
DV_SPIKE_LD := software/pragya_core/linker/pragya_dv_spike.ld
```

The project compiles the generated assembly twice:

```bash
$(CC) $(DV_CFLAGS) \
    -T software/pragya_core/linker/pragya_dv_rtl.ld \
    generated_test.S -o generated_test_rtl.elf
```

```bash
$(CC) $(DV_CFLAGS) \
    -T software/pragya_core/linker/pragya_dv_spike.ld \
    generated_test.S -o generated_test_spike.elf
```

The actual filenames are generated from the selected test name and seed by the Makefile.

## 16. Generate RTL Memory Images

The project extracts executable sections from the RTL ELF:

```bash
$(OBJCOPY) -O binary -j .text \
    generated_test_rtl.elf imem.bin
```

The conversion script converts the binary into the RTL memory format:

```bash
python3 scripts/conversion/elf_to_hex.py imem.bin imem.hex
```

The generated image is copied to:

```text
program.mem
```

The project separately extracts data sections:

```bash
$(OBJCOPY) -O binary \
    -j .data \
    -j .sdata \
    -j .rodata \
    -j .user_stack \
    -j .kernel_stack \
    generated_test_rtl.elf dmem.bin
```

The resulting data image is converted to the format expected by the RTL data memory.

The project Makefile handles these steps through `dv_mem`.

## 17. Run RTL Simulation

The generated RTL memory images are loaded by the PRAGYA testbench.

The project uses QuestaSim for simulation.

The main testbench is:

```text
verification/pragya_core/top/tb_pragya_top.sv
```

The project's `dv_rtl` target handles the RTL simulation and saves the architectural commit log.

Run the complete RTL and Spike comparison flow using:

```bash
make dv DV_TEST=pragya_arithmetic_basic_test SEED=1
```

## 18. Run Spike Simulation

The project uses a direct Spike invocation:

```bash
/opt/riscv/bin/spike \
    --isa=rv32im_zicsr_zicntr \
    --priv=m \
    --disable-dtb \
    --pc=0x80000000 \
    -l \
    --log-commits \
    generated_test_spike.elf
```

The actual Makefile uses the generated Spike ELF and stores the raw execution log.

The project also checks the `tohost` marker:

```text
mem 0x80008000 0x00000001
```

This marker is used by the custom runner to recognize test completion.

## 19. Compare RTL and Spike Results

The project compares the architectural commit logs from the RTL and Spike executions.

The relevant output directories are:

```text
results/logs/core/
results/logs/spike/
results/logs/compare/
```

The comparison script is:

```text
scripts/comparison/compare_logs.py
```

A successful comparison indicates that the checked architectural commit information matches between the RTL execution and Spike execution.

## 20. Run the Complete RISC-V-DV Flow

From the project root:

```bash
make dv DV_TEST=pragya_arithmetic_basic_test SEED=1
```

The top-level target executes:

```text
dv_check
   |
   v
dv_gen
   |
   v
dv_build
   |
   v
dv_mem
   |
   v
dv_rtl
   |
   v
dv_spike
   |
   v
dv_compare
```

To run the interrupt test:

```bash
make dv_irq DV_TEST=pragya_interrupt_test SEED=1
```

## 21. Verified Test Results

The following tests were successfully executed in the verified project environment.

### Arithmetic test

Command:

```bash
make dv DV_TEST=pragya_arithmetic_basic_test SEED=1
```

Observed result:

| Metric | Result |
|---|---:|
| RTL commits | 2449 |
| Spike commits | 2449 |
| Comparison errors | 0 |
| Warnings | 10 |

### Interrupt test

Command:

```bash
make dv_irq DV_TEST=pragya_interrupt_test SEED=1
```

Observed result:

- Comparison errors: 0
- Warnings: 10
- RTL commits: 5489
- Spike commits: 5410
- Pre-interrupt and post-interrupt execution were checked separately.
- The interrupt handler region is handled by the project's interrupt-aware comparison logic.

These results describe the tests executed in the verified environment. Results may differ with a different seed, tool version, configuration, or RTL revision.

## 22. Important Local Configuration and Compatibility Notes

### Preserve local RISC-V-DV modifications

The verified checkout has a local modification in:

```text
src/riscv_instr_gen_config.sv
```

The region size was changed from:

```systemverilog
4096 * 16
```

to:

```systemverilog
16384
```

This is a local project-related modification. Preserve it when updating or replacing the checkout, and confirm that it is still required before applying it to another RISC-V-DV revision.

Check local modifications:

```bash
cd $HOME/riscv-dv
git status
git diff
```

Do not commit editor swap files such as:

```text
src/.riscv_instr_gen_config.sv.swp
```

### Spike --misaligned compatibility

The upstream RISC-V-DV Spike configuration may use:

```text
--misaligned
```

The verified Spike installation does not accept that option.

The PRAGYA Makefile therefore runs Spike directly using the options supported by the installed executable.

Changing `SPIKE_PATH` only changes where the executable is found; it does not add support for an unsupported option.

Do not modify the upstream ISS configuration or replace the shared Spike installation without checking the impact on the project flow.

## 23. Troubleshooting

### Python module not found

Check the installed package:

```bash
python3 -m pip show PyYAML bitstring pyvsc tabulate pandas
```

Install compatible requirements in the selected Python environment:

```bash
python3 -m pip install -r requirements.txt
```

### RISC-V-DV script not found

Check:

```bash
ls -l $HOME/riscv-dv/run.py
```

Update the Makefile variable if the repository is in a different location:

```makefile
RISCV_DV_RUN := $(HOME)/riscv-dv/run.py
```

### Questa command not found

Check:

```bash
echo $QUESTA_HOME
which vsim
```

Set:

```bash
export QUESTA_HOME=/opt/modeltech
export PATH=$QUESTA_HOME/linux_x86_64:$PATH
```

### Spike command not found

Check:

```bash
which spike
echo $SPIKE_PATH
```

Set:

```bash
export SPIKE_PATH=/opt/riscv/bin
```

### Testlist or target directory not found

Check the paths in the project Makefile:

```makefile
DV_TARGET_DIR := $(CURDIR)/verification/pragya_core/riscv_dv/pragya/rv32i
DV_TESTLIST   := $(CURDIR)/verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml
```

### RTL and Spike commit mismatch

Inspect:

```text
results/logs/core/
results/logs/spike/
results/logs/compare/
```

Check that:
- Both executables were built from the same generated assembly test.
- The ISA and ABI match.
- The correct linker scripts were used.
- The RTL memory images were generated from the RTL ELF.
- Spike was started at the expected PC.
- The comparison script is using the intended interrupt or non-interrupt comparison mode.

## 24. References

RISC-V-DV repository:

https://github.com/chipsalliance/riscv-dv

RISC-V-DV documentation:

https://chipsalliance.github.io/riscv-dv/

RISC-V GNU Toolchain:

https://github.com/riscv-collab/riscv-gnu-toolchain

Spike:

https://github.com/riscv-software-src/riscv-isa-sim
