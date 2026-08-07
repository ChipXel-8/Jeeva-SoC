#!/bin/bash

echo "Creating jeeva-soc directory structure..."

# 1. Create all Directories
mkdir -p rtl/pragya_core/{include,fetch,decode,execute,hazard,pipeline,system}
mkdir -p rtl/{memory,bus/obi,bus/axi,bus/apb,pkg,top}
mkdir -p rtl/peripherals/{uart,gpio,spi,i2c,timer,pwm,watchdog,clint,plic}

mkdir -p verification/common/{interfaces,assertions,models,utilities,packages}
mkdir -p verification/unit/{pc,decoder,regfile,imm_gen,alu,branch,lsu,mdu,csr,machine_control,hazard}
mkdir -p verification/core_sanity/{tb,tests,logs,memory_models}
mkdir -p verification/isa/{asm,c,compliance,riscv_dv,spike,compare}
mkdir -p verification/soc_no_core/{tb,bus_tests,peripheral_tests,register_tests,interrupt_tests}
mkdir -p verification/soc_full/{tb,boot_tests,firmware_tests,peripheral_tests,benchmark_tests,stress_tests}
mkdir -p verification/{coverage,regressions,formal}

mkdir -p software/{startup,linker,examples,benchmarks}
mkdir -p software/drivers/{uart,gpio,spi,i2c,timer,clint,plic}
mkdir -p software/tests/{asm,c}

mkdir -p scripts/{compile,simulation,regression,coverage,compare}
mkdir -p docs/{architecture,verification,memory_map,peripherals,reports,images}
mkdir -p fpga synthesis implementation tapeout third_party

# 2. Create base root files
touch Makefile README.md LICENSE .gitignore

# 3. Create specified RTL files
touch rtl/pragya_core/pragya_core.v
touch rtl/pragya_core/include/pragya_defines.vh
touch rtl/pragya_core/fetch/{pragya_pc.v,if_id_reg.v}
touch rtl/pragya_core/decode/{pragya_decoder.v,pragya_regfile.v,pragya_imm_gen.v,pragya_imm_adder.v}
touch rtl/pragya_core/execute/{pragya_alu.v,pragya_alu_mux.v,pragya_branch_unit.v,pragya_lsu.v,pragya_mdu.v}
touch rtl/pragya_core/hazard/pragya_hazard_unit.v
touch rtl/pragya_core/pipeline/pragya_id_ie_mem_wb_reg.v
touch rtl/pragya_core/system/{pragya_csr.v,machine_control.v}

touch rtl/memory/{mem_core.v,instr_mem_wrapper.v,data_mem_wrapper.v,bootrom.v}
touch rtl/bus/obi/{obi_ctrl.v,obi_demux.v}
touch rtl/bus/axi/obi_to_axi_bridge.v
touch rtl/bus/apb/{axi_lite_to_apb_intf.v,apb_decoder.v}
touch rtl/pkg/{addr_map_pkg.v,jeeva_soc_pkg.v}
touch rtl/top/{pragya_top.v,jeeva_soc_top.v}

# 4. Create specified Software files
touch software/startup/{crt0.S,vectors.S}
touch software/linker/link.ld

# 5. Add .gitkeep to all empty directories so Git tracks them
find . -type d -empty -exec touch {}/.gitkeep \;

echo "Directory structure created successfully!"
