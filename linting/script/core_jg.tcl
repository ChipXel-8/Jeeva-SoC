# ============================================================
# 1. INITIALIZATION & SETUP
# ============================================================
clear -all
check_superlint -init

# ============================================================
# 2. ANALYZE & ELABORATE
# ============================================================
analyze -v2k {*}[glob /home/tops3/Downloads/jeeva_soc/core_rtl/*.v]
elaborate -top pragya_core

# ============================================================
# 3. CLOCKS & RESETS
# ============================================================
clock pg_riscv32_mp_clk_in
reset -expression {pg_riscv32_mp_rst_in == 1}

# ============================================================
# 4. EXTRACT & APPLY WAIVERS
# ============================================================
check_superlint -extract

# Your existing waiver files are correct, we will keep loading them.
source /home/tops3/Downloads/jeeva_soc/linting/script/deadcode_waiver.tcl
source /home/tops3/Downloads/jeeva_soc/linting/script/overflow_waiver.tcl

# ============================================================
# 5. PROVE PROPERTIES
# ============================================================
check_superlint -prove

# ============================================================
# 6. REPORT GENERATION (CLEAN SYNTAX)
# ============================================================
set rpt_dir /home/tops3/Downloads/jeeva_soc/linting/report
file mkdir $rpt_dir

# Report 1: Ultimate Proof (Shows all properties, passed, waived, failed)
check_superlint -report -property -file $rpt_dir/core_all_properties_proof.rpt -force

# Report 2: Waived Dead Code List (Filters strictly for waived covers)
check_superlint -report -waived only -property -type cover -detailed  -file $rpt_dir/core_waived_dead_code.rpt -force

# Report 3: Waived Overflow List (Filters strictly for waived asserts)
check_superlint -report -waived only -property -type assert -detailed  -file $rpt_dir/core_waived_overflow.rpt -force 

# Report 4: Unconnected Pins (Will generate empty because your RTL is clean)
check_superlint -report -violation -tag {.*(UNCON|FLOAT|DRIV|PIN.*NC|NC.*PIN).*} -regexp -file $rpt_dir/core_unconnected_pins.rpt -force

# Report 5: Superlint Summary
check_superlint -report -summary -file $rpt_dir/core_superlint_summary.rpt -force


