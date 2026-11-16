#
# Any disclosure about the Cadence Design Systems software or its use
# model to any third party violates the written Non-Disclosure Agreement
# between Cadence Design Systems, Inc. and the customer.
#
# THIS SOFTWARE CONTAINS CONFIDENTIAL INFORMATION AND TRADE SECRETS OF
# CADENCE DESIGN SYSTEMS, INC. USE, DISCLOSURE, OR REPRODUCTION IS
# PROHIBITED WITHOUT THE PRIOR EXPRESS WRITTEN PERMISSION OF CADENCE
# DESIGN SYSTEMS, INC.
#
# Copyright (C) 2000-2022 Cadence Design Systems, Inc. All Rights
# Reserved.  Unpublished -- rights reserved under the copyright laws of
# the United States.
#
# This product includes software developed by others and redistributed
# according to license agreement. See doc/third_party_readme.txt for
# further details.
#
# RESTRICTED RIGHTS LEGEND
#
# Use, duplication, or disclosure by the Government is subject to
# restrictions as set forth in subparagraph (c) (1) (ii) of the Rights in
# Technical Data and Computer Software clause at DFARS 252.227-7013 or
# subparagraphs (c) (1) and (2) of Commercial Computer Software -- Restricted
# Rights at 48 CFR 52.227-19, as applicable.
#
#
#                           Cadence Design Systems, Inc.
#                           2655 Seely Avenue
#                           San Jose, CA 95134
#                           Phone: 408.943.1234
#
# For technical assistance visit http://support.cadence.com.

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 467 -end_line 467 -start_column 13 -end_column 38 -instance { csr_inst } -expression { ~csr_inst.rst_in |-> ~`BIT(64, ({1'b0, csr_inst.mcycle} + {1'b0, 64'b1})) } -tag ASG_AR_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAqHicVY2xDoJAEEQf8R+o7SxoONATAyT+iQG82Gg0dvy9T6FxNzO7M3O5BTbAmURt752JkShPBJrfXumP6qhuOJpddUr3gZNu4OAfOS/eOjdm+eL7pzqxVLbiWxUP01nczbd09PK/V4jolZ23Au0H8ksVZg== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 469 -end_line 469 -start_column 17 -end_column 46 -instance { csr_inst } -expression { (~csr_inst.rst_in & csr_inst.instret_inc_in) |-> ~`BIT(64, ({1'b0, csr_inst.minstret} + {1'b0, 64'b1})) } -tag ASG_AR_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAsHicZY3BDsFQEEWP+AdrOwubvuKpIumfNMpLY4GGbvy907Izk7kz97zJG2AKVCRW5tqeaIjqmUAxzrm80Ud9wda3iyRzPrGTBjb+MaPjKWl5q7X7D33iG5NfDVFy48qdF/240TPnwFH950srem3hzcD+A8OIF2A= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_imm_adder.v} -start_line 19 -end_line 19 -start_column 8 -end_column 50 -instance { imm_adder_inst } -expression { ~`BIT(32, ({1'b0, imm_adder_inst.i_adder_mux_out} + {1'b0, imm_adder_inst.imm_in})) } -tag ASG_AR_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAzHicdYzNDsFAFEaPeAdrextKOkQknsJ2UjXEotqgCW/fM9i6X879/XKBMbCn4EjNWmq7gopAaV7IijlLb5nAhrObUleyD/ozMKHjrvvC2xzdtc6Jb4x+5DjwoKdh+lc7ufqj4qSSf6L+npe1tT69zz6eRkXrje0AFnga3w== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_mdu.v} -start_line 452 -end_line 452 -start_column 17 -end_column 24 -instance { mdu_inst } -expression { ~`BIT(33, ({1'b0, mdu_inst.rem_shifted} - {1'b0, {1'b0, mdu_inst.reg_b}})) } -tag ASG_AR_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAhnicJY07CoAwEESfeAEra48Qv2DnTYL5aKkYLLy9Ex3YYT7LLlACCwM9EwYndsxSkaCsxaszdFKrJog9m5LcjHJRW143ak4u+Z1HbJUd8pEfBf+njIrErS/26xPNC1aKEQk= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 391 -end_line 391 -start_column 46 -end_column 79 -instance { csr_inst } -expression { csr_inst.mtvec_out[0] |-> ~`BIT(32, ({1'b0, {csr_inst.mtvec_base, 2'b0}} + {1'b0, csr_inst.base_offset})) } -tag EXP_AR_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAunicNY29DoJAEIQ/4ztY01lIAf4gdBa8xwX0tDIaJCbG+O5+gO5k92ZmL7PAHDgQ2Yitb6SlcB7JKUe+1m/Vhbpk7+6kk8kbKt2cnRkL7nQ6F17O4P+bOjLV7NdD1by50vMcrwSzGx7ylMRbS3UmPqqV/d8G885i4D3JF7HSGX0= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_alu.v} -start_line 16 -end_line 16 -start_column 17 -end_column 24 -instance { alu_inst } -expression { ~alu_inst.sra_out[31] } -tag ASG_IS_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAhnicLYxLEkBAEEMfLmBl7QgYhtm5yRQKS8pn4fbi06mkku5UAxHQ0lNTYDFixkSHE55dp9zLN6Ihf1FTaWsZpE6NUj8SVjb5mUvqdVuUR74JxPD3Mfvb9GqcHKQ3/EoP6A== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_alu.v} -start_line 33 -end_line 33 -start_column 19 -end_column 48 -instance { alu_inst } -expression { (alu_inst.alu_control == 4'b0) |-> ~alu_inst.addsub_full[32] } -tag ASG_IS_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAsHicLYxRDoJAEEOfege/PYKKgmhMvInZReFnE4jih7fnLTpNJ+20GWAF3IhU7Ckp5JaWQC3yLeij+iQLdjMqjl5LGndt4+CPNQMvdcfXfTfr9U9+s5DLvz6bJz52cv5WJUZdrxrZcJWBh8hZNGnnTuIyAVFRGCk= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_alu.v} -start_line 34 -end_line 34 -start_column 19 -end_column 48 -instance { alu_inst } -expression { (alu_inst.alu_control == 4'b1) |-> ~alu_inst.addsub_full[32] } -tag ASG_IS_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAsHicLYxLCsJAEEQfegfXHiEazU8EbyIzatwMJMS48Pa+iXZRTVVX0cAauBCp2VNRyoKeQCvyLeijupEluwU1R68VN3dr4+CPDSOT+snHfTUb9A9+s/ozT2eeeNvJ+UuVmHWDambLWQbuImfRpF86idMXUZgYKg== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_mdu.v} -start_line 455 -end_line 455 -start_column 24 -end_column 31 -instance { mdu_inst } -expression { ~mdu_inst.s_mul_a[31] } -tag ASG_IS_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAhnicJY07DsJADEQf4gKpUucICwmR6LhJtD9oQCBQityet8pIHntmLBs4AjcmRmYCSU5cnSpF70Q2C5ydolXkzF2nJRdVdSt7o+fDV/1gkxe9t7qy48D+qaHjZ/5i5WmPDH9WLRD2 }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_mdu.v} -start_line 456 -end_line 456 -start_column 24 -end_column 31 -instance { mdu_inst } -expression { ~mdu_inst.s_mul_b[31] } -tag ASG_IS_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAAhnicLYxJDoJQEEQfcAFWrD3CR8TEnTcx/kE2GgnGBbfnGemkqmvoNNAAV04MnAlEOXJRFbJZT7ILHFV3keXEw+TXjLriVfJHx8yin1jlm9lbX/hPJepdt3zsX3x5uiOHDVYXEPY= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_alu.v} -start_line 14 -end_line 14 -start_column 27 -end_column 50 -instance { alu_inst } -expression { (~|{alu_inst.rs_1_in[0], alu_inst.rs_1_in[1], alu_inst.rs_1_in[2], alu_inst.rs_1_in[3], alu_inst.rs_1_in[4], alu_inst.rs_1_in[5], alu_inst.rs_1_in[6], alu_inst.rs_1_in[7], alu_inst.rs_1_in[8], alu_inst.rs_1_in[9], alu_inst.rs_1_in[10], alu_inst.rs_1_in[11], alu_inst.rs_1_in[12], alu_inst.rs_1_in[13], alu_inst.rs_1_in[14], alu_inst.rs_1_in[15], alu_inst.rs_1_in[16], alu_inst.rs_1_in[17], alu_inst.rs_1_in[18], alu_inst.rs_1_in[19], alu_inst.rs_1_in[20], alu_inst.rs_1_in[21], alu_inst.rs_1_in[22], alu_inst.rs_1_in[23], alu_inst.rs_1_in[24], alu_inst.rs_1_in[25], alu_inst.rs_1_in[26], alu_inst.rs_1_in[27], alu_inst.rs_1_in[28], alu_inst.rs_1_in[29], alu_inst.rs_1_in[30], alu_inst.rs_1_in[31]} | (|({64{({32'b0, alu_inst.rs_1_in} << alu_inst.rs_2_in[4:0])}}) & ~|({32{({32'b0, alu_inst.rs_1_in} << alu_inst.rs_2_in[4:0])}}))) } -tag SHF_IS_OVFL -comment { Reviewed by RTL designer.
Overflow is intentional due to fixed-width arithmetic
in the PRAGYA RISC-V core.
Result truncation follows the defined 32-bit
RISC-V arithmetic behavior.
No unintended functional overflow is expected. } -persistency_data { AAAApnicLYxLDoJQEATLeAfWHIGPgHwW3IMYAkaNGyW64vYW+KbTk5mazgBHoGemIqMk1wl3Jmq1scl9dj7rnHRXRSEtudprEyd/RCx8nB+s9tHb2/3Gvw7BWyXyr4lUP3kR06k40CzQwa+N2QvtD0CzFIo= }

