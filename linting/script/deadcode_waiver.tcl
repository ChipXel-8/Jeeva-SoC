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

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pc_unit.v} -start_line 179 -end_line 179 -start_column 17 -end_column 42 -instance { u_pc_unit } -expression { 1'b0 } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAqHicVYxBDoJAEAQr8gfOPAFWlDWGhJ8YQPSiaIwH/L2FcmE2PZvprhkgARoGKvb0nLnQquibvUhH0C91Izk7thQcZIN/a1roB2+kPHnpXPnYT+48nAf+tVk0V5DsJUbTiTcZtRp//N3dm9maOH4BEzkXZQ== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_alu.v} -start_line 43 -end_line 43 -start_column 22 -end_column 50 -instance { alu_inst } -expression { ~|{(alu_inst.alu_control == 4'b0), (alu_inst.alu_control == 4'b1), (alu_inst.alu_control == 4'b10), (alu_inst.alu_control == 4'b11), (alu_inst.alu_control == 4'b100), (alu_inst.alu_control == 4'b101), (alu_inst.alu_control == 4'b110), (alu_inst.alu_control == 4'b111), (alu_inst.alu_control == 4'b1000), (alu_inst.alu_control == 4'b1001)} } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAArnicLY3LCoJgEIW/6B1ct3Prpbwggm8SKuVGMMoWEr1731/NcA7nzBlmgD3QMVCSUZCLhCs9tR1mvX5QVyIn/XbJyWnBKNduHL0RceOuntjks9miv/Cr3R+hKvOZpzshf6hmVt2iWjnQipe/Mjkl9nvC224+FPoW4A== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 522 -end_line 522 -start_column 32 -end_column 91 -instance { csr_inst } -expression { (~csr_inst.rst_in & csr_inst.csr_do_write & ~csr_inst.set_cause_in & (csr_inst.csr_addr_in == 12'b11110110000)) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAA7nicbY7BDsFQEEWP+AfrfoBFH1pVJP6jkaatxpIgQcS/O7QWEjOZOzP3zrw3wBDY0DLVZ+aWmlRsCGSfeiJf26f2GXO1nUxsXbGQDSS+MeLISWbPXSydP9i3dDbo42039xvOqtGPr1iLj14ruTpXcTEKbwvk/rZl7Mx3v/CG3As69t9eoh6rP1kSvQBETCCf }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 523 -end_line 523 -start_column 32 -end_column 56 -instance { csr_inst } -expression { (~csr_inst.rst_in & csr_inst.csr_do_write & ~csr_inst.set_cause_in & (csr_inst.csr_addr_in == 12'b11110110001)) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAApnicXYxNDoJgDEQf4Q6sPQL/QpSEmxDALy4laGK4vU90RZtOOzNtgRjoCRRmaQ9M1OJMRrPPufokr+UNZ72bSuo80qpmVP5IWFhV7mzi4P5DHvhF9K9vpN4v+qdDXunEmad3A2+3Rl7W5QOV3RSo }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 524 -end_line 524 -start_column 32 -end_column 56 -instance { csr_inst } -expression { (~csr_inst.rst_in & csr_inst.csr_do_write & ~csr_inst.set_cause_in & (csr_inst.csr_addr_in == 12'b11110110010)) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAApnicLYxbDoJADEWPcQ9+swQQRQiYsBPDY4J/GiQx7J4zYpu57X10gCPQEsjtizPQU4gDGeVvP6v38kJectMbVVL3jko14+ofJ97MKhOr+DD/kgf2OvxfrNT7j35ML86nSmI33MVBb/b+ayr6HfUGzfIWLQ== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_csr.v} -start_line 525 -end_line 525 -start_column 32 -end_column 56 -instance { csr_inst } -expression { (~csr_inst.rst_in & csr_inst.csr_do_write & ~csr_inst.set_cause_in & (csr_inst.csr_addr_in == 12'b11110110011)) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAApnicLYxbDoJQDESPcQ9+swQQRQiYsBPD4wb/NEhi2D3nim06bWemBY5ASyA3L/ZATyEOZJS/+SzfuxfuJTe1USZ17qhkM67+OPFmlplYxYf+l3tgj8O/YqTef9Sje7E//ZCYDXdxUJu9/+qKeke9Ac4RFi4= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_de_mw_pipeline.v} -start_line 85 -end_line 85 -start_column 13 -end_column 34 -instance { pipeline2_inst } -expression { (~pipeline2_inst.rst_in & pipeline2_inst.flush) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAoHicJY3BCoJQEEUP+Q+u2wWu1LQMDfoTsdIIEqVF0d97Xs7izsyZyx0gAi4cGbhRUdCR0dtTSvvBLcx3eaB7Tlyd878O3ktZYUbMzFv24Ke2pk3uPWttWD+FShjlo56vKS0f/S+e/tjScFYzdl5S6gVUihS/ }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_decoder.v} -start_line 682 -end_line 682 -start_column 22 -end_column 37 -instance { decoder_inst } -expression { 1'b0 } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAlHicJY09D0BgDISf8B+MYrPiJYhIDFYxmcX3SGz+vXvppdf22uYAF2hYiUjZySiVifqVmIJJSKVELF/NpZXqjfZWMeJdl+Bxcev64BGP0k/NG384/E42fDpaBnp9BNRKQ8gsD4vqBRjXEUM= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_decoder.v} -start_line 719 -end_line 719 -start_column 30 -end_column 51 -instance { decoder_inst } -expression { 1'b0 } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAoHicLY3BCoJgEIQ/yGfw3C3wpPlHSghGV6+eozK7hEZ06e37THeZ3dnZgQFWQE1HSqBnRym28o6MgosdVFJu/71XK+W5/0nJnb1OiHnx1v3g6zyrj9535ppSooUnHGloOekY+OgaebKmEoENV9PmPvwADwcToA== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_imm_generator.v} -start_line 33 -end_line 33 -start_column 31 -end_column 42 -instance { imm_gen_inst } -expression { ~|{(imm_gen_inst.imm_src == 3'b0), (imm_gen_inst.imm_src == 3'b1), (imm_gen_inst.imm_src == 3'b10), (imm_gen_inst.imm_src == 3'b11), (imm_gen_inst.imm_src == 3'b100), (imm_gen_inst.imm_src == 3'b101)} } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAjHicLYxRCoNADEQf7B16DutqqUjBmyxq3dKPUpH+eHuf2oRJMpNJgAB0FNwouZJFKet5UjEyEGXZKTo36g0Td7N2v7NCVP64MLOovFityYuvfOKM8AeH883HfNgTP/2zvnYDozMR0A== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_machine_control.v} -start_line 430 -end_line 430 -start_column 21 -end_column 44 -instance { machine_control_inst } -expression { ((machine_control_inst.curr_state == 5'b10) & ~(((machine_control_inst.ebreak | machine_control_inst.ecall | machine_control_inst.exception) & machine_control_inst.id_valid_in) | (machine_control_inst.ip & machine_control_inst.mie_in)) & ~(machine_control_inst.mret & machine_control_inst.id_valid_in) & machine_control_inst.wfi) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAApnicLYxBDoJQDEQfegfXHAE1Cokx0YUmrjVhaYD/cadGXcjteaBtZtrOtAWmwI6KloyGYC2omcuBnDiqy3GOLKyNarBbmWud4aL2x4wnL//c6OSrew/nyC8SMfn3GXf1Lx+33nIlIilbcebCXhz0So6c2JD2E6EWQw== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_machine_control.v} -start_line 437 -end_line 437 -start_column 21 -end_column 50 -instance { machine_control_inst } -expression { ((machine_control_inst.curr_state == 5'b10000) & machine_control_inst.ip) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAsHicLY3NDgFBEIS/ROIR9uwRWPETIrEH2bgguMvuznBDcODtfTvMpKq6qnt6gA6wpOJMn4agTqkZyIEJMaXD5CO52pgGq5F3bKd9Ubsj487DPRc+8sm5mz7yO+0v3X8942r+5uXUU65EpMdCHDhSiJW9LTt1n/yaDSXzLwArF/Y= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_machine_control.v} -start_line 439 -end_line 439 -start_column 21 -end_column 44 -instance { machine_control_inst } -expression { ((machine_control_inst.curr_state == 5'b10000) & ~machine_control_inst.ip) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAApnicLYzLDoJQDERP9B9c8wmo8ZEQE1howhoTlwa4F3dC1IX+vQe0zUzbmbbAHMip6UhpCdY9DUs5sCNO6nqaIytrqxrsNuZWZ7xo/LFg4OGfGx/56l7vHPnF7I8xUu7qb15uPeVaRBIOouJMIY56F06UZCRfE94WRA== }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_machine_control.v} -start_line 449 -end_line 449 -start_column 17 -end_column 46 -instance { machine_control_inst } -expression { ~|{(machine_control_inst.curr_state == 5'b1), (machine_control_inst.curr_state == 5'b10), (machine_control_inst.curr_state == 5'b10000), (machine_control_inst.curr_state == 5'b100), (machine_control_inst.curr_state == 5'b1000)} } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAsHicLYzLDgFBFERPIvEJs/YJjHiESMxCJjYI9jIz3ewQLPh7Z5rbqaquug+gAyypONOnIahTagZyYEJM6TD5SK42psHfyDe2027U3si48/DOhY98cu6mj/yq+0dbM67mb15OPeVKRHosxIEjhVjZ27JT98mv2VAy/wIBABf5 }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_machine_control.v} -start_line 475 -end_line 475 -start_column 17 -end_column 43 -instance { machine_control_inst } -expression { (machine_control_inst.curr_state == 5'b10000) } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAqnicTY07DsJADESf4A6pOQIk/CSEhBSljSgo6BDZXSiD+BTcnrdJgy17bM/YBqbAgSs35gSiuKVjYY5sSMO0GvpEKQan0Wqlr2XyRueNggdP79z5mi/qevvEaBPGT9mWKoOKl3zGng9vZn++N47Uci0NZ07sfljmFiY= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_machine_control.v} -start_line 502 -end_line 502 -start_column 17 -end_column 43 -instance { machine_control_inst } -expression { ~|{(machine_control_inst.curr_state == 5'b1), (machine_control_inst.curr_state == 5'b10), (machine_control_inst.curr_state == 5'b10000), (machine_control_inst.curr_state == 5'b100), (machine_control_inst.curr_state == 5'b1000)} } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAqnicTYy5DsJADESflH+gzidwhENCSEiINkqRgg6R3YUyEUfB3/M2UGDLHntmbKAA9ly4MiUQxQ0dM3tkTRrZxbgn5mKQjU5Lc6WSLzp/TBi4++fG237W17snvlH8KkelM+h4qGfsefGk/Mud1XBQqzlyomX7AVknFic= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_mdu.v} -start_line 532 -end_line 532 -start_column 38 -end_column 57 -instance { mdu_inst } -expression { 1'b0 } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAnHicLY1LCsJQDEWPuIeOO6rTflSQVnAnYl9fdaAolg66e89TA7nJ/ZAAa+DEloY9Jb3Yc3CLDGoVQa+kdrvYgxgYVZKzk0VTwRsZL97yK4t4VnvKI79a/TtVwYOZu5nkT9+Z03EUGz9tuHm//QDzMBPq }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_mdu.v} -start_line 546 -end_line 546 -start_column 26 -end_column 42 -instance { mdu_inst } -expression { 1'b0 } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAlnicLYzBCoJQFEQP+A+t/QTNDMQCF7YI2vUBos9ny8Lc+PceqYEZ7szce4EEaDhRcCZjUAcqp8holhPsMo5OvRzVwGSyN6UuuhX8ceDDrH+xqp3ZWx/5IflzR8qXxZ3FNuXCVX16caflwY16A3OLEu0= }

check_superlint -waiver -add -source_file {/home/tops3/Downloads/jeeva_soc/core_rtl/pragya_wb_mux.v} -start_line 32 -end_line 32 -start_column 41 -end_column 59 -instance { wb_mux_inst } -expression { ~|{(wb_mux_inst.wb_mux_sel_in == 3'b0), (wb_mux_inst.wb_mux_sel_in == 3'b1), (wb_mux_inst.wb_mux_sel_in == 3'b10), (wb_mux_inst.wb_mux_sel_in == 3'b11), (wb_mux_inst.wb_mux_sel_in == 3'b100), (wb_mux_inst.wb_mux_sel_in == 3'b101), (wb_mux_inst.wb_mux_sel_in == 3'b110)} } -tag BLK_NO_RCHB -comment { Reviewed by RTL designer.
Intentional default assignments in PRAGYA CORE  RISC-V RTL.
These statements are reported as unreachable by
automatically generated formal dead-code checks. } -persistency_data { AAAAmnicLY1BDoJQDEQf8Q6uWZi4/YDCN8bEmxDAH5cSAiHe3ifaSaftTJsCO+BOR+DBhZ5EyVlE64mCxj5QUetHkdQK9xt3hw3RHvaMTOpP3nKr/nJO/CL75zcOrN62+gszubhtnPul5KgXuH4AlAgSZA== }

