# ============================================================
# PRAGYA RISC-V RTL vs SPIKE VERIFICATION
#
# C TEST:
#    make c TEST=01_alu_test
#
# RISC-V-DV:
#    make dv DV_TEST=pragya_arithmetic_basic_test SEED=1
#
# COMPLETE REGRESSION:
#    make regression
# ============================================================

SHELL := /bin/bash

# ============================================================
# GLOBAL CONFIGURATION
# ============================================================

TEST        ?= 01_alu_test
DV_TEST     ?= pragya_arithmetic_basic_test
SEED        ?= 1

ISA         ?= rv32im_zicsr_zicntr
ABI         ?= ilp32

MAX_CYCLES  ?= 300000
SPIKE_MAX   ?= 100000

# Waivers path
WAIVER_DO   := $(CURDIR)/config/pragya_core_waivers.do

# ============================================================
# TOOLCHAIN
# ============================================================

PREFIX  := /opt/riscv/bin/riscv32-unknown-linux-gnu-

CC      := $(PREFIX)gcc
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
NM      := $(PREFIX)nm

SPIKE   := /opt/riscv/bin/spike
PYTHON  := python3


# ============================================================
# RTL SOURCES
# ============================================================

RTL_SRCS := \
rtl/pragya_core/interfaces/obi_ctrl.v \
rtl/pragya_core/fetch/pc_unit.v \
rtl/pragya_core/execute/pragya_alu_mux.v \
rtl/pragya_core/execute/pragya_alu.v \
rtl/pragya_core/execute/pragya_branch_unit.v \
rtl/pragya_core/system/pragya_csr.v \
rtl/pragya_core/memory/pragya_data_mem_wrapper.v \
rtl/pragya_core/decode/pragya_decoder.v \
rtl/pragya_core/pipeline/pragya_de_mw_pipeline.v \
rtl/pragya_core/memory/pragya_dmem.v \
rtl/pragya_core/hazard/pragya_hazard_unit.v \
rtl/pragya_core/fetch/pragya_if_id_reg.v \
rtl/pragya_core/memory/pragya_imem.v \
rtl/pragya_core/decode/pragya_imm_adder.v \
rtl/pragya_core/decode/pragya_imm_generator.v \
rtl/pragya_core/memory/pragya_instr_mem_wrapper.v \
rtl/pragya_core/memory/pragya_lsu.v \
rtl/pragya_core/system/pragya_machine_control.v \
rtl/pragya_core/execute/pragya_mdu.v \
rtl/pragya_core/decode/pragya_regfile.v \
rtl/pragya_core/writeback/pragya_wb_mux.v \
rtl/pragya_core/pragya_core.v \
rtl/top/pragya_top.v

TB := verification/pragya_core/top/tb_pragya_top.sv


# ============================================================
# COVERAGE FILES
# ============================================================

COV_SRCS := \
verification/pragya_core/functional_coverage/source/pragya_pkg.sv \
verification/pragya_core/functional_coverage/source/rv32i_coverage.sv \
verification/pragya_core/functional_coverage/source/rv32m_coverage.sv \
verification/pragya_core/functional_coverage/source/load_store_coverage.sv \
verification/pragya_core/functional_coverage/source/branch_jump_coverage.sv \
verification/pragya_core/functional_coverage/source/pipeline_coverage.sv \
verification/pragya_core/functional_coverage/source/rv32_system_coverage.sv


# ============================================================
# C TEST CONFIGURATION
# ============================================================

C_SRC    := software/pragya_core/tests/c/$(TEST).c
STARTUP  := software/pragya_core/startup/startup.S
TRAP     := software/pragya_core/startup/trap.S

RTL_LD   := software/pragya_core/linker/pragya.ld
SPIKE_LD := software/pragya_core/linker/pragya_spike.ld

RTL_ELF   := build/elf/$(TEST).elf
SPIKE_ELF := build/elf/$(TEST)_spike.elf

BIN := build/bin/$(TEST).bin
MEM := build/hex/$(TEST).mem

RTL_LOG       := rtl.log
CORE_LOG      := results/logs/core/$(TEST).log
SPIKE_RAW_LOG := results/logs/spike/$(TEST)_raw.log
SPIKE_LOG     := results/logs/spike/$(TEST).log
CMP_LOG       := results/logs/compare/$(TEST).log

# Dedicated Transcript Directories & Files
TRANSCRIPT_DIR    := results/logs/transcripts
TRANSCRIPT_C_DIR  := $(TRANSCRIPT_DIR)/c
TRANSCRIPT_DV_DIR := $(TRANSCRIPT_DIR)/dv

C_TRANSCRIPT      := $(TRANSCRIPT_C_DIR)/$(TEST)_transcript.log


# ============================================================
# C FLAGS
# ============================================================

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


# ============================================================
# RISC-V-DV CONFIGURATION
# ============================================================

RISCV_DV_RUN  := $(HOME)/riscv-dv/run.py
DV_TARGET_DIR := $(CURDIR)/verification/pragya_core/riscv_dv/pragya/rv32i
DV_TESTLIST   := $(CURDIR)/verification/pragya_core/riscv_dv/testlists/pragya_testlist.yaml

DV_OUT        := $(CURDIR)/build/riscv_dv/$(DV_TEST)_seed$(SEED)
DV_ASM        := $(DV_OUT)/asm_test/$(DV_TEST)_0.S
DV_RTL_ELF    := $(DV_OUT)/$(DV_TEST)_0.elf
DV_SPIKE_ELF  := $(DV_OUT)/$(DV_TEST)_0_spike.elf

DV_RTL_LD     := software/pragya_core/linker/pragya_dv_rtl.ld
DV_SPIKE_LD   := software/pragya_core/linker/pragya_dv_spike.ld

DV_IMEM_BIN   := $(DV_OUT)/imem.bin
DV_IMEM_HEX   := $(DV_OUT)/imem.hex
DV_DMEM_BIN   := $(DV_OUT)/dmem.bin
DV_DMEM_HEX   := $(DV_OUT)/dmem.hex

DV_CORE_LOG       := results/logs/core/$(DV_TEST)_seed$(SEED).log
DV_IRQ_CORE_LOG   := results/logs/core/$(DV_TEST)_seed$(SEED)_irq.log
DV_SPIKE_RAW_LOG  := results/logs/spike/$(DV_TEST)_seed$(SEED)_raw.log
DV_SPIKE_LOG      := results/logs/spike/$(DV_TEST)_seed$(SEED).log
DV_CMP_LOG        := results/logs/compare/$(DV_TEST)_seed$(SEED).log
DV_IRQ_CMP_LOG    := results/logs/compare/$(DV_TEST)_seed$(SEED)_irq.log

DV_TRANSCRIPT     := $(TRANSCRIPT_DV_DIR)/$(DV_TEST)_seed$(SEED)_transcript.log
DV_IRQ_TRANSCRIPT := $(TRANSCRIPT_DV_DIR)/$(DV_TEST)_seed$(SEED)_irq_transcript.log


# ============================================================
# RISC-V-DV GCC FLAGS
# ============================================================

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


# ============================================================
# PHONY TARGETS
# ============================================================

.PHONY: \
	all c check build rtl spike compare \
	dv dv_check dv_gen dv_build dv_mem \
	dv_rtl dv_spike dv_compare \
	dv_irq dv_rtl_irq dv_compare_irq \
	disasm dv_disasm coverage_merge regression clean


# ============================================================
# DEFAULT = C TEST
# ============================================================

all: c


# ============================================================
# C TEST FLOW
# ============================================================

ifeq ($(filter csr_mip_pending external_interrupt timer_interrupt software_interrupt interrupt_mie_disabled timer_irq_pending_test timer_irq_mtie_disabled_test timer_both_disabled_test wfi_timer_test mip_toggle pmpaddr16_toggle,$(TEST)),)

c: check build rtl spike compare
	@echo ""
	@echo "========================================"
	@echo " PRAGYA C VERIFICATION COMPLETE"
	@echo " TEST = $(TEST)"
	@echo " RTL vs SPIKE = ENABLED"
	@echo "========================================"
	@echo ""

else

c: check build rtl
	@echo ""
	@echo "========================================"
	@echo " PRAGYA C INTERRUPT VERIFICATION COMPLETE"
	@echo " TEST = $(TEST)"
	@echo " RTL vs SPIKE = SKIPPED"
	@echo " Interrupt injected externally by TB"
	@echo "========================================"
	@echo ""

endif


# ============================================================
# C CHECK
# ============================================================

check:
	@test -f $(C_SRC) || (echo "ERROR: $(C_SRC) not found"; exit 1)
	@test -f $(RTL_LD) || (echo "ERROR: $(RTL_LD) not found"; exit 1)
	@test -f $(SPIKE_LD) || (echo "ERROR: $(SPIKE_LD) not found"; exit 1)
	@mkdir -p \
		build/elf \
		build/bin \
		build/hex \
		results/logs/core \
		results/logs/spike \
		results/logs/compare \
		$(TRANSCRIPT_C_DIR) \
		$(TRANSCRIPT_DV_DIR) \
		coverage/databases/regression \
		coverage/reports/regression \
		coverage/reports/final_merged


# ============================================================
# C BUILD
# ============================================================

build:
	@echo ""
	@echo "========================================"
	@echo " Building C test: $(TEST)"
	@echo "========================================"

	$(CC) $(CFLAGS) \
		$(STARTUP) \
		$(TRAP) \
		$(C_SRC) \
		-T $(RTL_LD) \
		-Wl,-Map=build/elf/$(TEST).map \
		-o $(RTL_ELF)

ifeq ($(filter csr_mip_pending external_interrupt timer_interrupt software_interrupt interrupt_mie_disabled timer_irq_pending_test timer_irq_mtie_disabled_test timer_both_disabled_test wfi_timer_test mip_toggle pmpaddr16_toggle,$(TEST)),)

	@echo ""
	@echo "Building Spike ELF..."
	$(CC) $(CFLAGS) \
		$(STARTUP) \
		$(TRAP) \
		$(C_SRC) \
		-T $(SPIKE_LD) \
		-Wl,-Map=build/elf/$(TEST)_spike.map \
		-o $(SPIKE_ELF)
	@echo "[OK] Spike ELF created: $(SPIKE_ELF)"

else

	@echo ""
	@echo "Interrupt test detected. Skipping Spike ELF."

endif

	$(OBJCOPY) -O binary -j .text $(RTL_ELF) $(BIN)
	$(PYTHON) scripts/conversion/elf_to_hex.py $(BIN) $(MEM)
	cp $(MEM) program.mem

	$(OBJCOPY) -O binary -j .data -j .sdata -j .rodata $(RTL_ELF) build/bin/$(TEST)_data.bin || true
	@if [ -s build/bin/$(TEST)_data.bin ]; then \
		$(PYTHON) scripts/conversion/elf_to_dmem.py build/bin/$(TEST)_data.bin data.mem; \
	else \
		: > data.mem; \
	fi

	@echo ""
	@echo "[OK] C program built"
	@echo ""


# ============================================================
# C RTL
# ============================================================

rtl: build
	@echo ""
	@echo "========================================"
	@echo " Running RTL"
	@echo " TEST = $(TEST)"
	@echo "========================================"

	@mkdir -p $(TRANSCRIPT_C_DIR)
	rm -rf work
	vlib work

	vlog -64 -sv -mfcu \
		$(COV_SRCS) \
		$(TB)
	vlog -64 -sv -mfcu -cover bcesfx \
		$(RTL_SRCS)

	rm -f $(RTL_LOG)

ifeq ($(TEST),csr_mip_pending)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_mip_cross_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),external_interrupt)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_irq_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),wfi_timer_test)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_wfi_timer_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),timer_interrupt)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_timer_irq_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),interrupt_mie_disabled)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_interrupt_mie_disabled_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),timer_irq_pending_test)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_timer_pending_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),timer_both_disabled_test)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_timer_both_disabled_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),timer_irq_mtie_disabled_test)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_timer_mtie_disabled_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else ifeq ($(TEST),software_interrupt)
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		+c_software_irq_test \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
else
	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(C_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=0 \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(TEST).ucdb; quit -f"
endif

	@test -f $(RTL_LOG) || (echo "ERROR: RTL log not generated"; exit 1)
	cp $(RTL_LOG) $(CORE_LOG)

	vcover report \
		-html \
		-details \
		-output coverage/reports/regression/$(TEST)_report \
		coverage/databases/regression/$(TEST).ucdb

	@echo ""
	@echo "[OK] RTL log: $(CORE_LOG)"
	@echo "[OK] Transcript log: $(C_TRANSCRIPT)"
	@echo ""


# ============================================================
# C SPIKE
# ============================================================

spike: build
ifeq ($(filter mip_toggle pmpaddr16_toggle,$(TEST)),)
	@echo ""
	@echo "========================================"
	@echo " Running Spike"
	@echo "========================================"

	@rm -f $(SPIKE_RAW_LOG)
	@rm -f $(SPIKE_LOG)

	@$(SPIKE) \
		--isa=$(ISA) \
		--priv=m \
		--disable-dtb \
		--pc=0x80000000 \
		--instructions=$(SPIKE_MAX) \
		-l \
		--log-commits \
		$(SPIKE_ELF) \
		2> $(SPIKE_RAW_LOG) & \
	SPIKE_PID=$$!; \
	while ! grep -q "mem 0x80008000 0x00000001" $(SPIKE_RAW_LOG); do \
		sleep 0.1; \
	done; \
	kill $$SPIKE_PID; \
	wait $$SPIKE_PID 2>/dev/null || true

	@awk '{ print; if ($$0 ~ /mem 0x80008000 0x00000001/) exit; }' $(SPIKE_RAW_LOG) > $(SPIKE_LOG)

	@test -s $(SPIKE_LOG) || (echo "ERROR: Spike log not generated"; exit 1)

	@echo ""
	@echo "[OK] Spike log:"
	@echo "     $(SPIKE_LOG)"
	@echo ""
else
	@echo ""
	@echo "========================================"
	@echo " Spike SKIPPED"
	@echo " TEST = $(TEST)"
	@echo " Reason = CSR toggle coverage test"
	@echo "========================================"
	@echo ""
endif


# ============================================================
# C COMPARE (Appends comparison results directly to transcript)
# ============================================================

compare:
	@echo ""
	@echo "========================================"
	@echo " RTL vs Spike Verification"
	@echo "========================================"

ifeq ($(filter mip_toggle pmpaddr16_toggle,$(TEST)),)

	@echo " Comparing RTL vs Spike"
	@echo ""
	@set -o pipefail; \
	$(PYTHON) scripts/comparison/compare_logs.py \
		$(RTL_LOG) \
		$(SPIKE_LOG) \
		2>&1 | tee $(CMP_LOG) | tee -a $(C_TRANSCRIPT)

else

	@echo "" | tee -a $(C_TRANSCRIPT)
	@echo ">>> CSR TOGGLE TEST" | tee -a $(C_TRANSCRIPT)
	@echo ">>> TEST = $(TEST)" | tee -a $(C_TRANSCRIPT)
	@echo ">>> RTL coverage collected" | tee -a $(C_TRANSCRIPT)
	@echo ">>> RTL vs Spike comparison SKIPPED" | tee -a $(C_TRANSCRIPT)
	@echo ">>> Reason: CSR is implementation-specific" | tee -a $(C_TRANSCRIPT)
	@echo "" | tee -a $(C_TRANSCRIPT)

endif


# ============================================================
# RISC-V-DV FLOW
# ============================================================

dv: dv_check dv_gen dv_build dv_mem dv_rtl dv_spike dv_compare
	@echo ""
	@echo "========================================"
	@echo " PRAGYA RISC-V-DV VERIFICATION COMPLETE"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	@echo ""

dv_check:
	@test -f $(RISCV_DV_RUN) || (echo "ERROR: $(RISCV_DV_RUN) not found"; exit 1)
	@test -d $(DV_TARGET_DIR) || (echo "ERROR: $(DV_TARGET_DIR) not found"; exit 1)
	@test -f $(DV_TESTLIST) || (echo "ERROR: $(DV_TESTLIST) not found"; exit 1)
	@test -f $(DV_RTL_LD) || (echo "ERROR: $(DV_RTL_LD) not found"; exit 1)
	@test -f $(DV_SPIKE_LD) || (echo "ERROR: $(DV_SPIKE_LD) not found"; exit 1)
	@test -f scripts/comparison/compare_logs.py || (echo "ERROR: compare_logs.py not found"; exit 1)
	@test -f scripts/comparison/compare_irq_logs.py || (echo "ERROR: compare_irq_logs.py not found"; exit 1)
	@test -f scripts/conversion/elf_to_hex.py || (echo "ERROR: scripts/conversion/elf_to_hex.py not found"; exit 1)
	@mkdir -p \
		build/riscv_dv \
		results/logs/core \
		results/logs/spike \
		results/logs/compare \
		$(TRANSCRIPT_C_DIR) \
		$(TRANSCRIPT_DV_DIR) \
		coverage/databases/regression \
		coverage/reports/regression \
		coverage/reports/final_merged

	@echo ""
	@echo "[OK] RISC-V-DV environment"
	@echo ""

dv_gen:
	@echo ""
	@echo "========================================"
	@echo " Generating NEW RISC-V-DV program"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	rm -rf $(DV_OUT)
	$(PYTHON) $(RISCV_DV_RUN) \
		-ct $(DV_TARGET_DIR) \
		-tl $(DV_TESTLIST) \
		-tn $(DV_TEST) \
		-i 1 \
		-si questa \
		--isa $(ISA) \
		-m $(ABI) \
		-o $(DV_OUT) \
		-s gen \
		--seed $(SEED) \
		-v
	@test -f $(DV_ASM) || (echo "ERROR: RISC-V-DV assembly not generated"; exit 1)

dv_build:
	@echo ""
	@echo "========================================"
	@echo " Building RISC-V-DV ELFs"
	@echo "========================================"
	$(CC) $(DV_CFLAGS) -T $(DV_RTL_LD) $(DV_ASM) -o $(DV_RTL_ELF)
	$(CC) $(DV_CFLAGS) -T $(DV_SPIKE_LD) $(DV_ASM) -o $(DV_SPIKE_ELF)
	@test -f $(DV_RTL_ELF) || (echo "ERROR: RTL ELF not generated"; exit 1)
	@test -f $(DV_SPIKE_ELF) || (echo "ERROR: Spike ELF not generated"; exit 1)

dv_mem:
	@echo ""
	@echo "========================================"
	@echo " Creating RISC-V-DV RTL memory"
	@echo "========================================"
	$(OBJCOPY) -O binary -j .text $(DV_RTL_ELF) $(DV_IMEM_BIN)
	$(PYTHON) scripts/conversion/elf_to_hex.py $(DV_IMEM_BIN) $(DV_IMEM_HEX)
	cp $(DV_IMEM_HEX) program.mem

	$(OBJCOPY) -O binary -j .data -j .sdata -j .rodata -j .user_stack -j .kernel_stack $(DV_RTL_ELF) $(DV_DMEM_BIN) || true
	@if [ -s "$(DV_DMEM_BIN)" ]; then \
		$(PYTHON) scripts/conversion/elf_to_dmem.py "$(DV_DMEM_BIN)" "$(DV_DMEM_HEX)"; \
	else \
		: > "$(DV_DMEM_HEX)"; \
	fi
	cp "$(DV_DMEM_HEX)" data.mem

	@echo ""
	@echo "[OK] program.mem created"
	@echo ""

dv_rtl:
	@echo ""
	@echo "========================================"
	@echo " Running RISC-V-DV RTL"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	@mkdir -p $(TRANSCRIPT_DV_DIR)
	rm -rf work
	vlib work
	vlog -64 -sv -mfcu $(COV_SRCS) $(TB)
	vlog -64 -sv -mfcu -cover bcesfx $(RTL_SRCS)
	rm -f $(RTL_LOG)

	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(DV_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=1 \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(DV_TEST)_seed$(SEED).ucdb; quit -f"

	@test -s $(RTL_LOG) || (echo "ERROR: RTL log not generated"; exit 1)
	cp $(RTL_LOG) $(DV_CORE_LOG)

	vcover report \
		-html \
		-details \
		-output coverage/reports/regression/$(DV_TEST)_seed$(SEED)_report \
		coverage/databases/regression/$(DV_TEST)_seed$(SEED).ucdb

	@echo ""
	@echo "[OK] RTL DV log: $(DV_CORE_LOG)"
	@echo "[OK] Transcript log: $(DV_TRANSCRIPT)"
	@echo ""

dv_irq: dv_check dv_gen dv_build dv_mem dv_rtl_irq dv_spike dv_compare_irq
	@echo ""
	@echo "========================================"
	@echo " PRAGYA RISC-V-DV INTERRUPT VERIFICATION COMPLETE"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	@echo ""

dv_rtl_irq:
	@echo ""
	@echo "========================================"
	@echo " Running RISC-V-DV RTL INTERRUPT TEST"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	@mkdir -p $(TRANSCRIPT_DV_DIR)
	rm -rf work
	vlib work
	vlog -64 -sv -mfcu $(COV_SRCS) $(TB)
	vlog -64 -sv -mfcu -cover bcesfx $(RTL_SRCS)
	rm -f $(RTL_LOG)

	vsim -64 -coverage -c work.tb_pragya_top \
		-l $(DV_IRQ_TRANSCRIPT) \
		-onfinish stop \
		-gMAX_CYCLES=$(MAX_CYCLES) \
		-gRISCV_DV_MODE=1 \
		+enable_irq_seq \
		-do "do $(WAIVER_DO); run -all; coverage save coverage/databases/regression/$(DV_TEST)_seed$(SEED)_irq.ucdb; quit -f"

	@test -s $(RTL_LOG) || (echo "ERROR: RTL interrupt log not generated"; exit 1)
	cp $(RTL_LOG) $(DV_IRQ_CORE_LOG)

	vcover report \
		-html \
		-details \
		-output coverage/reports/regression/$(DV_TEST)_seed$(SEED)_irq_report \
		coverage/databases/regression/$(DV_TEST)_seed$(SEED)_irq.ucdb

	@echo ""
	@echo "[OK] RTL interrupt test completed: results/logs/core/$(DV_TEST)_seed$(SEED)_irq.log"
	@echo "[OK] Transcript log: $(DV_IRQ_TRANSCRIPT)"
	@echo ""

dv_spike:
	@echo ""
	@echo "========================================"
	@echo " Running RISC-V-DV Spike"
	@echo "========================================"
	rm -f $(DV_SPIKE_RAW_LOG) $(DV_SPIKE_LOG)

	@$(SPIKE) \
		--isa=$(ISA) \
		--priv=m \
		--disable-dtb \
		--pc=0x80000000 \
		-l \
		--log-commits \
		$(DV_SPIKE_ELF) \
		2> $(DV_SPIKE_RAW_LOG) & \
	SPIKE_PID=$$!; \
	while ! grep -q "mem 0x80008000 0x00000001" $(DV_SPIKE_RAW_LOG); do \
		sleep 0.1; \
	done; \
	kill $$SPIKE_PID; \
	wait $$SPIKE_PID 2>/dev/null || true

	@awk '{ print; if ($$0 ~ /mem 0x80008000 0x00000001/) exit; }' $(DV_SPIKE_RAW_LOG) > $(DV_SPIKE_LOG)
	@test -s $(DV_SPIKE_LOG) || (echo "ERROR: Spike log not generated"; exit 1)
	@grep -q "mem 0x80008000 0x00000001" $(DV_SPIKE_LOG) || (echo "ERROR: Spike never reached tohost=1"; exit 1)

	@echo ""
	@echo "[OK] Spike reached tohost=1"
	@echo ""
	@echo "[OK] Trimmed Spike log: $(DV_SPIKE_LOG)"
	@echo ""

dv_compare:
	@echo ""
	@echo "========================================"
	@echo " Comparing RISC-V-DV RTL vs Spike"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	@set -o pipefail; \
	$(PYTHON) scripts/comparison/compare_logs.py \
		$(RTL_LOG) \
		$(DV_SPIKE_LOG) \
		2>&1 | tee $(DV_CMP_LOG) | tee -a $(DV_TRANSCRIPT)

dv_compare_irq:
	@echo ""
	@echo "========================================"
	@echo " Comparing RISC-V-DV INTERRUPT RTL vs Spike"
	@echo " TEST = $(DV_TEST)"
	@echo " SEED = $(SEED)"
	@echo "========================================"
	@test -s $(DV_IRQ_CORE_LOG) || (echo "ERROR: Interrupt RTL log not found"; exit 1)
	@test -s $(DV_SPIKE_LOG) || (echo "ERROR: Spike log not found"; exit 1)
	@test -f scripts/comparison/compare_irq_logs.py || (echo "ERROR: compare_irq_logs.py not found"; exit 1)
	@set -o pipefail; \
	$(PYTHON) scripts/comparison/compare_irq_logs.py \
		$(DV_IRQ_CORE_LOG) \
		$(DV_SPIKE_LOG) \
		2>&1 | tee $(DV_IRQ_CMP_LOG) | tee -a $(DV_IRQ_TRANSCRIPT)
	@echo "" | tee -a $(DV_IRQ_TRANSCRIPT)
	@echo "========================================" | tee -a $(DV_IRQ_TRANSCRIPT)
	@echo " INTERRUPT RTL vs Spike COMPARISON COMPLETE" | tee -a $(DV_IRQ_TRANSCRIPT)
	@echo "========================================" | tee -a $(DV_IRQ_TRANSCRIPT)
	@echo "" | tee -a $(DV_IRQ_TRANSCRIPT)


# ============================================================
# DISASSEMBLY
# ============================================================

disasm: build
	$(OBJDUMP) -d $(RTL_ELF) | less

dv_disasm:
	$(OBJDUMP) -d $(DV_RTL_ELF) | less


# ============================================================
# MERGE COVERAGE
# ============================================================

coverage_merge:
	@echo ""
	@echo "========================================"
	@echo " Merging UCDB Files"
	@echo "========================================"
	rm -f coverage/databases/final.ucdb
	rm -rf coverage/reports/final_merged
	vcover merge \
		coverage/databases/final.ucdb \
		$(shell find coverage/databases/regression -maxdepth 1 -type f -name "*.ucdb" -print)
	vsim -c -viewcov coverage/databases/final.ucdb \
		-do "do $(WAIVER_DO); coverage report -html -output coverage/reports/final_merged -details; quit -f"
	@echo ""
	@echo "========================================"
	@echo " Coverage Merge Complete"
	@echo "========================================"
	@echo "Merged UCDB : coverage/databases/final.ucdb"
	@echo "HTML Report : coverage/reports/final_merged/index.html"
	@echo ""


# ============================================================
# COMPLETE REGRESSION
# ============================================================

regression:
	@echo ""
	@echo "========================================"
	@echo " Starting Complete Regression"
	@echo "========================================"

	# --------------------------------------------------------
	# Directed C Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=01_alu_test
	$(MAKE) c TEST=02_load_store_test
	$(MAKE) c TEST=03_branch_test
	$(MAKE) c TEST=04_jump_test
	$(MAKE) c TEST=05_lui_auipc_test
	$(MAKE) c TEST=06_shift_test
	$(MAKE) c TEST=07_compare_test
	$(MAKE) c TEST=08_immediate_test
	$(MAKE) c TEST=09_x0_test
	$(MAKE) c TEST=10_register_stress_test
	$(MAKE) c TEST=11_mul_test
	$(MAKE) c TEST=12_mulh_test
	$(MAKE) c TEST=13_div_test
	$(MAKE) c TEST=14_rem_test
	$(MAKE) c TEST=15_mixed_rv32m_test
	$(MAKE) c TEST=16_forwarding_test
	$(MAKE) c TEST=17_load_use_test
	$(MAKE) c TEST=18_pipeline_test
	$(MAKE) c TEST=19_memory_boundary_test
	$(MAKE) c TEST=20_sign_extension_test
	$(MAKE) c TEST=21_factorial_test
	$(MAKE) c TEST=22_fibonacci_test
	$(MAKE) c TEST=23_mac_test
	$(MAKE) c TEST=24_matrix_multiplication_test
	$(MAKE) c TEST=25_prime_test
	$(MAKE) c TEST=26_quick_sort_test
	$(MAKE) c TEST=27_recursive_factorial_test
	$(MAKE) c TEST=28_selection_sort_test
	$(MAKE) c TEST=29_sorted_array_test
	$(MAKE) c TEST=30_convolution_test
	$(MAKE) c TEST=31_register_coverage_test
	$(MAKE) c TEST=32_forwarding_chain_test
	$(MAKE) c TEST=33_dual_forwarding_test
	$(MAKE) c TEST=34_mul_corner_cases_test
	$(MAKE) c TEST=35_div_corner_cases_test
	$(MAKE) c TEST=36_rem_corner_cases_test
	$(MAKE) c TEST=37_branch_taken_not_taken_test
	$(MAKE) c TEST=38_nested_branch_test
	$(MAKE) c TEST=39_branch_loop_stress_test
	$(MAKE) c TEST=40_load_store_size_test
	$(MAKE) c TEST=41_load_store_alignment_test
	$(MAKE) c TEST=42_memory_hazard_test
	$(MAKE) c TEST=43_pipeline_forwarding_test
	$(MAKE) c TEST=44_pipeline_stall_test
	$(MAKE) c TEST=45_csr_read_test
	$(MAKE) c TEST=46_csr_write_test
	$(MAKE) c TEST=47_csr_set_clear_test
	$(MAKE) c TEST=48_csr_stress_test
	$(MAKE) c TEST=49_full_core_stress_test
	$(MAKE) c TEST=51_all_registers_test
	$(MAKE) c TEST=52_all_branch_conditions_test
	$(MAKE) c TEST=53_all_load_store_offsets_test
	$(MAKE) c TEST=54_shift_edge_cases_test
	$(MAKE) c TEST=55_mul_div_special_values_test
	$(MAKE) c TEST=56_pipeline_corner_test
	$(MAKE) c TEST=57_csr_corner_cases_test
	$(MAKE) c TEST=58_memory_random_walk_test
	$(MAKE) c TEST=59_random_instruction_mix_test
	$(MAKE) c TEST=61_load_store_byte_halfword_test
	$(MAKE) c TEST=62_ecall_ebreak_test
	$(MAKE) c TEST=flush_stall
	$(MAKE) c TEST=load
	$(MAKE) c TEST=rv32i_registers
	$(MAKE) c TEST=forward_jump
	$(MAKE) c TEST=branch_jump
	$(MAKE) c TEST=load_store
	$(MAKE) c TEST=rv32m_all
	$(MAKE) c TEST=63_mul
	$(MAKE) c TEST=64_mul
	$(MAKE) c TEST=65_mul
	$(MAKE) c TEST=66_div
	$(MAKE) c TEST=67_branch_jump
	$(MAKE) c TEST=68_pipeline
	$(MAKE) c TEST=69_memory

	# --------------------------------------------------------
	# Cross Coverage Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=cross_instr_imm
	$(MAKE) c TEST=cross_instr_imm1
	$(MAKE) c TEST=cross_instr_imm2
	$(MAKE) c TEST=cp_write
	$(MAKE) c TEST=rv32i_cross_instr_rd
	$(MAKE) c TEST=rv32i_cross_instr_rd2
	$(MAKE) c TEST=rv32i_instr_format_test
	$(MAKE) c TEST=cross_instr_rdwe
	$(MAKE) c TEST=cross_instr_rdwe2
	$(MAKE) c TEST=cross_load_store_rs1
	$(MAKE) c TEST=cross_load_rs1
	$(MAKE) c TEST=cross_memory_rs1
	$(MAKE) c TEST=cross_memory_rs1_2
	$(MAKE) c TEST=cross_rtype_result
	$(MAKE) c TEST=cross_rtype_result1
	$(MAKE) c TEST=cross_store_rs1

	@for i in $$(seq -f "%03g" 1 41); do \
		$(MAKE) c TEST=cross_rtype_regs_$$i; \
	done

	# --------------------------------------------------------
	# CSR Directed Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=csr_missing_addr_test1
	$(MAKE) c TEST=csr_missing_addr_test2
	$(MAKE) c TEST=csr_rw_operations
	$(MAKE) c TEST=csr_access
	$(MAKE) c TEST=csr_mie_enabled
	$(MAKE) c TEST=csr_mip_pending
	$(MAKE) c TEST=csr_addr
	$(MAKE) c TEST=interrupt
	$(MAKE) c TEST=csr_operation
	$(MAKE) c TEST=csr_mtvec

	# --------------------------------------------------------
	# Interrupt Directed Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=external_interrupt
	$(MAKE) c TEST=timer_interrupt
	$(MAKE) c TEST=software_interrupt
	$(MAKE) c TEST=interrupt_mie_disabled
	$(MAKE) c TEST=timer_irq_pending_test
	$(MAKE) c TEST=timer_irq_mtie_disabled_test
	$(MAKE) c TEST=timer_both_disabled_test

	# --------------------------------------------------------
	# Exception Directed Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=exception_cause
	$(MAKE) c TEST=cp_ebreak
	$(MAKE) c TEST=cp_exception_all
	$(MAKE) c TEST=ecall_ebreak
	$(MAKE) c TEST=exception

	# --------------------------------------------------------
	# CSR Toggle Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=csr_toggle
	$(MAKE) c TEST=csr_mstatus_toggle
	$(MAKE) c TEST=csr_mstatus_toggle1
	$(MAKE) c TEST=csr_mie_toggle
	$(MAKE) c TEST=csr_misa_toggle
	$(MAKE) c TEST=csr_mtvec_toggle
	$(MAKE) c TEST=csr_mepc_toggle
	$(MAKE) c TEST=csr_mcause_toggle
	$(MAKE) c TEST=csr_mtval_toggle
	$(MAKE) c TEST=csr_mscratch_toggle
	$(MAKE) c TEST=csr_pmpaddr16_toggle
	$(MAKE) c TEST=csr_mcycle_toggle
	$(MAKE) c TEST=csr_minstret_toggle

	# --------------------------------------------------------
	# IF/ID Pipeline Toggle Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=if_id_pc_toggle
	$(MAKE) c TEST=if_id_branch_toggle
	$(MAKE) c TEST=if_id_ifvalid_toggle
	$(MAKE) c TEST=if_id_stall_toggle
	$(MAKE) c TEST=if_id_flush_toggle
	$(MAKE) c TEST=if_id_stall_flush
	$(MAKE) c TEST=if_id_jump_toggle
	$(MAKE) c TEST=if_id_branch_flush_test
	$(MAKE) c TEST=if_id_jump_flush_test
	$(MAKE) c TEST=if_id_load_use_stall_test
	$(MAKE) c TEST=if_id_store_load_stall_test
	$(MAKE) c TEST=if_id_branch_hazard_test
	$(MAKE) c TEST=if_id_loop_flush_test
	$(MAKE) c TEST=if_id_jalr_test
	$(MAKE) c TEST=if_id_mixed_stress_test

	# --------------------------------------------------------
	# Register File Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=regfile_all_regs_toggle
	$(MAKE) c TEST=regfile_explicit_regs
	$(MAKE) c TEST=regfile_address_patterns
	$(MAKE) c TEST=regfile_x0_toggle
	$(MAKE) c TEST=regfile_data_toggle

	# --------------------------------------------------------
	# Machine Control Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=machine_control_toggle
	$(MAKE) c TEST=machine_illegal_instruction
	$(MAKE) c TEST=machine_mret_test
	$(MAKE) c TEST=machine_ecall_repeat
	$(MAKE) c TEST=machine_ebreak_repeat
	$(MAKE) c TEST=external_interrupt_toggle
	$(MAKE) c TEST=machine_expression_test
	$(MAKE) c TEST=external_interrupt_disabled_test
	$(MAKE) c TEST=software_interrupt_disabled_test
	$(MAKE) c TEST=mip_toggle
	$(MAKE) c TEST=mie_toggle
	$(MAKE) c TEST=pmpaddr16_toggle

	# --------------------------------------------------------
	# Immediate Generator Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=imm_b_type_test
	$(MAKE) c TEST=imm_u_type_test
	$(MAKE) c TEST=imm_j_type_test

	# --------------------------------------------------------
	# ALU Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=alu_toggle_all_test
	$(MAKE) c TEST=alu_toggle_bit
	$(MAKE) c TEST=alu_shift_boundary
	$(MAKE) c TEST=alu_slt_sltu_boundary
	$(MAKE) c TEST=alu_add_sub_stress
	$(MAKE) c TEST=alu_transition_test

	# --------------------------------------------------------
	# Pipeline-2 Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=pipeline_2_reg_2

	# --------------------------------------------------------
	# Core Toggle Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=core_toggle_4

	# --------------------------------------------------------
	# OBI Controller Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=obi_ctrl
	$(MAKE) c TEST=obi_ctrl_1
	$(MAKE) c TEST=obi_ctrl_2
	$(MAKE) c TEST=obi_ctrl_3

	# --------------------------------------------------------
	# Machine Control Expression / Condition Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=machine_mret_rs1
	$(MAKE) c TEST=machine_mret_funct3
	$(MAKE) c TEST=machine_mret_rd
	$(MAKE) c TEST=machine_ecall_funct7
	$(MAKE) c TEST=machine_ebreak_funct7
	$(MAKE) c TEST=machine_control_expression
	$(MAKE) c TEST=decoder_test
	$(MAKE) c TEST=dmem_toggle

	# --------------------------------------------------------
	# Regfile Condition Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=regfile_condition
	$(MAKE) c TEST=regfile_condition1

	# --------------------------------------------------------
	# Machine Condition Tests
	# --------------------------------------------------------
	$(MAKE) c TEST=mie_1
	$(MAKE) c TEST=msie_1

	# ========================================================
	# RISC-V-DV REGRESSION
	# ========================================================
	@echo ""
	@echo "========================================"
	@echo " Running RISC-V-DV Regression"
	@echo "========================================"

	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_arithmetic_basic_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_mem_access_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_misaligned_mem_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_branch_jump_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_csr_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_csr_stress_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_exception_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_exception_stress_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_ecall_ebreak_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv_irq DV_TEST=pragya_interrupt_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv_irq DV_TEST=pragya_interrupt_stress_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_system_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_rv32m_test SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_pipeline_stress SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_memory_stress SEED=$$s; \
	done
	for s in $$(seq 1 2500); do \
		$(MAKE) dv DV_TEST=pragya_branch_stress SEED=$$s; \
	done
	for s in $$(seq 1 3500); do \
		$(MAKE) dv DV_TEST=pragya_random_test SEED=$$s; \
	done
	for s in $$(seq 1 3500); do \
		$(MAKE) dv DV_TEST=pragya_long_random SEED=$$s; \
	done

	@echo ""
	@echo "========================================"
	@echo " Complete Regression Finished"
	@echo "========================================"

	# ========================================================
	# FINAL COVERAGE MERGE
	# ========================================================
	@echo ""
	@echo "========================================"
	@echo " Merging Final Coverage"
	@echo "========================================"

	$(MAKE) coverage_merge

	@echo ""
	@echo "========================================"
	@echo " COMPLETE REGRESSION FINISHED"
	@echo "========================================"
	@echo ""


# ============================================================
# CLEAN
# ============================================================

clean:
	rm -rf work
	rm -f transcript vsim.wlf questa_run.log rtl.log program.mem data.mem
	rm -rf build/elf/* build/bin/* build/hex/* build/riscv_dv/*
	rm -rf results/logs/core/* results/logs/spike/* results/logs/compare/* results/logs/transcripts/*
	@echo ""
	@echo "Clean complete."
	@echo ""
