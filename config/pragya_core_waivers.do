coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_csr.v -code b -line 253
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_decoder.v -code s -line 311 348
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_decoder.v -code b -line 311 348
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_machine_control.v -code s -line 186-192
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_machine_control.v -code b -line 184
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_machine_control.v -code e -line 104 106
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_machine_control.v -code c -line 259-264
coverage exclude -src /home/tops1/pragya_verification/rtl/pragya_regfile.v -code c -line 37
coverage exclude -du work.pragya_machine_control -ft curr_state {STATE_OPERATING -> STATE_RESET} {STATE_TRAP_RETURN -> STATE_RESET} {STATE_TRAP_TAKEN -> STATE_RESET}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[0]} {commit_instr[1]} {commit_instr[2]} {commit_instr[3]} {commit_instr[4]} {commit_instr[5]} {commit_instr[6]} {commit_instr[7]} {commit_instr[8]} {commit_instr[9]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[10]} {commit_instr[11]} {commit_instr[12]} {commit_instr[13]} {commit_instr[14]} {commit_instr[15]} {commit_instr[16]} {commit_instr[17]} {commit_instr[18]} {commit_instr[19]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[20]} {commit_instr[21]} {commit_instr[22]} {commit_instr[23]} {commit_instr[24]} {commit_instr[25]} {commit_instr[26]} {commit_instr[27]} {commit_instr[28]} {commit_instr[29]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[30]} {commit_instr[31]} {commit_pc[0]} {commit_pc[1]} {commit_pc[2]} {commit_pc[3]} {commit_pc[4]} {commit_pc[5]} {commit_pc[6]} {commit_pc[7]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_pc[8]} {commit_pc[9]} {commit_pc[10]} {commit_pc[11]} {commit_pc[12]} {commit_pc[13]} {commit_pc[14]} {commit_pc[15]} {commit_pc[16]} {commit_pc[17]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_pc[18]} {commit_pc[19]} {commit_pc[20]} {commit_pc[21]} {commit_pc[22]} {commit_pc[23]} {commit_pc[24]} {commit_pc[25]} {commit_pc[26]} {commit_pc[27]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_pc[28]} {commit_pc[29]} {commit_pc[30]} {commit_pc[31]} {instr_rdata_o[0]} {instr_rdata_o[1]} {pg_riscv32_mp_dmaddr_out[0]} {pg_riscv32_mp_dmaddr_out[1]} {pg_riscv32_mp_imaddr_out[0]} pg_riscv32_mp_imreq_out
coverage exclude -scope /tb_pragya_top/dut/CORE/u_pc_unit -togglenode {normal_pc_next[0]} {pc[0]} {pc_next[0]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_out[0]} {pc_out[1]} {pc_out[15]} {pc_out[16]} {pc_out[17]} {pc_out[18]} {pc_out[19]} {pc_out[20]} {pc_out[21]} {pc_out[22]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_out[23]} {pc_out[24]} {pc_out[25]} {pc_out[26]} {pc_out[27]} {pc_out[28]} {pc_out[29]} {pc_out[30]} {pc_plus_4_pipline1_out[0]} {pc_plus_4_pipline1_out[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_plus_4_pipline1_out[15]} {pc_plus_4_pipline1_out[16]} {pc_plus_4_pipline1_out[17]} {pc_plus_4_pipline1_out[18]} {pc_plus_4_pipline1_out[19]} {pc_plus_4_pipline1_out[20]} {pc_plus_4_pipline1_out[21]} {pc_plus_4_pipline1_out[22]} {pc_plus_4_pipline1_out[23]} {pc_plus_4_pipline1_out[24]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_plus_4_pipline1_out[25]} {pc_plus_4_pipline1_out[26]} {pc_plus_4_pipline1_out[27]} {pc_plus_4_pipline1_out[28]} {pc_plus_4_pipline1_out[29]} {pc_plus_4_pipline1_out[30]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[0]} {i[1]} {i[2]} {i[3]} {i[4]} {i[5]} {i[6]} {i[7]} {i[8]} {i[9]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[10]} {i[11]} {i[12]} {i[13]} {i[14]} {i[15]} {i[16]} {i[17]} {i[18]} {i[19]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[20]} {i[21]} {i[22]} {i[23]} {i[24]} {i[25]} {i[26]} {i[27]} {i[28]} {i[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[30]} {i[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {base_offset[0]} {base_offset[1]} {base_offset[4]} {base_offset[6]} {base_offset[7]} {base_offset[8]} {base_offset[9]} {base_offset[10]} {base_offset[11]} {base_offset[12]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {base_offset[13]} {base_offset[14]} {base_offset[15]} {base_offset[16]} {base_offset[17]} {base_offset[18]} {base_offset[19]} {base_offset[20]} {base_offset[21]} {base_offset[22]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {base_offset[23]} {base_offset[24]} {base_offset[25]} {base_offset[26]} {base_offset[27]} {base_offset[28]} {base_offset[29]} {base_offset[30]} {base_offset[31]} {mcause[4]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mcause[5]} {mcause[6]} {mcause[7]} {mcause[8]} {mcause[9]} {mcause[10]} {mcause[11]} {mcause[12]} {mcause[13]} {mcause[14]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mcause[15]} {mcause[16]} {mcause[17]} {mcause[18]} {mcause[19]} {mcause[20]} {mcause[21]} {mcause[22]} {mcause[23]} {mcause[24]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mcause[25]} {mcause[26]} {mcause[27]} {mcause[28]} {mcause[29]} {mcause[30]} {mepc[0]} {mepc[1]} {mie[0]} {mie[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mie[2]} {mie[4]} {mie[5]} {mie[6]} {mie[8]} {mie[9]} {mie[10]} {mie[12]} {mie[13]} {mie[14]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mie[15]} {mie[16]} {mie[17]} {mie[18]} {mie[19]} {mie[20]} {mie[21]} {mie[22]} {mie[23]} {mie[24]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mie[25]} {mie[26]} {mie[27]} {mie[28]} {mie[29]} {mie[30]} {mie[31]} {misa[0]} {misa[1]} {misa[2]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa[3]} {misa[4]} {misa[5]} {misa[6]} {misa[7]} {misa[8]} {misa[9]} {misa[10]} {misa[11]} {misa[13]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa[14]} {misa[15]} {misa[16]} {misa[17]} {misa[18]} {misa[19]} {misa[20]} {misa[21]} {misa[22]} {misa[23]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa[24]} {misa[25]} {misa[26]} {misa[27]} {misa[28]} {misa[29]} {misa[30]} {misa[31]} {misa_out[0]} {misa_out[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa_out[2]} {misa_out[3]} {misa_out[4]} {misa_out[5]} {misa_out[6]} {misa_out[7]} {misa_out[8]} {misa_out[9]} {misa_out[10]} {misa_out[11]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa_out[13]} {misa_out[14]} {misa_out[15]} {misa_out[16]} {misa_out[17]} {misa_out[18]} {misa_out[19]} {misa_out[20]} {misa_out[21]} {misa_out[22]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa_out[23]} {misa_out[24]} {misa_out[25]} {misa_out[26]} {misa_out[27]} {misa_out[28]} {misa_out[29]} {misa_out[30]} {misa_out[31]} {mstatus_out[0]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mstatus_out[1]} {mstatus_out[2]} {mstatus_out[4]} {mstatus_out[5]} {mstatus_out[6]} {mstatus_out[8]} {mstatus_out[9]} {mstatus_out[10]} {mstatus_out[11]} {mstatus_out[12]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mstatus_out[13]} {mstatus_out[14]} {mstatus_out[15]} {mstatus_out[16]} {mstatus_out[17]} {mstatus_out[18]} {mstatus_out[19]} {mstatus_out[20]} {mstatus_out[21]} {mstatus_out[22]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mstatus_out[23]} {mstatus_out[24]} {mstatus_out[25]} {mstatus_out[26]} {mstatus_out[27]} {mstatus_out[28]} {mstatus_out[29]} {mstatus_out[30]} {mstatus_out[31]} {trap_mux_out[0]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {trap_mux_out[1]} {vec_mux_out[0]} {vec_mux_out[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE/machine_control_inst -togglenode {cause_out[2]} {curr_state[0]} {next_state[0]} {trap_pc_out[0]} {trap_pc_out[1]} {trap_pc_out[15]} {trap_pc_out[16]} {trap_pc_out[17]} {trap_pc_out[18]} {trap_pc_out[19]}
coverage exclude -scope /tb_pragya_top/dut/CORE/machine_control_inst -togglenode {trap_pc_out[20]} {trap_pc_out[21]} {trap_pc_out[22]} {trap_pc_out[23]} {trap_pc_out[24]} {trap_pc_out[25]} {trap_pc_out[26]} {trap_pc_out[27]} {trap_pc_out[28]} {trap_pc_out[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE/machine_control_inst -togglenode {trap_pc_out[30]} {trap_pc_out[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/imm_gen_inst -togglenode {b_type[0]} {j_type[0]} {u_type[0]} {u_type[1]} {u_type[2]} {u_type[3]} {u_type[4]} {u_type[5]} {u_type[6]} {u_type[7]}
coverage exclude -scope /tb_pragya_top/dut/CORE/imm_gen_inst -togglenode {u_type[8]} {u_type[9]} {u_type[10]} {u_type[11]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {slt_out[1]} {slt_out[2]} {slt_out[3]} {slt_out[4]} {slt_out[5]} {slt_out[6]} {slt_out[7]} {slt_out[8]} {slt_out[9]} {slt_out[10]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {slt_out[11]} {slt_out[12]} {slt_out[13]} {slt_out[14]} {slt_out[15]} {slt_out[16]} {slt_out[17]} {slt_out[18]} {slt_out[19]} {slt_out[20]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {slt_out[21]} {slt_out[22]} {slt_out[23]} {slt_out[24]} {slt_out[25]} {slt_out[26]} {slt_out[27]} {slt_out[28]} {slt_out[29]} {slt_out[30]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {slt_out[31]} {sltu_out[1]} {sltu_out[2]} {sltu_out[3]} {sltu_out[4]} {sltu_out[5]} {sltu_out[6]} {sltu_out[7]} {sltu_out[8]} {sltu_out[9]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {sltu_out[10]} {sltu_out[11]} {sltu_out[12]} {sltu_out[13]} {sltu_out[14]} {sltu_out[15]} {sltu_out[16]} {sltu_out[17]} {sltu_out[18]} {sltu_out[19]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {sltu_out[20]} {sltu_out[21]} {sltu_out[22]} {sltu_out[23]} {sltu_out[24]} {sltu_out[25]} {sltu_out[26]} {sltu_out[27]} {sltu_out[28]} {sltu_out[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE/alu_inst -togglenode {sltu_out[30]} {sltu_out[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {instr_reg_out[0]} {instr_reg_out[1]} {pc_plus_4_reg_out[0]} {pc_plus_4_reg_out[1]} {pc_plus_4_reg_out[15]} {pc_plus_4_reg_out[16]} {pc_plus_4_reg_out[17]} {pc_plus_4_reg_out[18]} {pc_plus_4_reg_out[19]} {pc_plus_4_reg_out[20]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {pc_plus_4_reg_out[21]} {pc_plus_4_reg_out[22]} {pc_plus_4_reg_out[23]} {pc_plus_4_reg_out[24]} {pc_plus_4_reg_out[25]} {pc_plus_4_reg_out[26]} {pc_plus_4_reg_out[27]} {pc_plus_4_reg_out[28]} {pc_plus_4_reg_out[29]} {pc_plus_4_reg_out[30]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {pc_plus_4_reg_out[31]} {pc_reg_out[0]} {pc_reg_out[1]} {pc_reg_out[15]} {pc_reg_out[16]} {pc_reg_out[17]} {pc_reg_out[18]} {pc_reg_out[19]} {pc_reg_out[20]} {pc_reg_out[21]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {pc_reg_out[22]} {pc_reg_out[23]} {pc_reg_out[24]} {pc_reg_out[25]} {pc_reg_out[26]} {pc_reg_out[27]} {pc_reg_out[28]} {pc_reg_out[29]} {pc_reg_out[30]} {pc_reg_out[31]}
coverage exclude -scope /tb_pragya_top/dut/I_wrapper/imem -togglenode {instruction_out[0]} {instruction_out[1]}
coverage exclude -src rtl/pragya_core.v -code e -line 873
coverage exclude -src rtl/pragya_csr.v -code b -line 253
coverage exclude -src rtl/pragya_decoder.v -code s -line 311 348
coverage exclude -src rtl/pragya_decoder.v -code b -line 311 348
coverage exclude -src rtl/pragya_machine_control.v -code s -line 186-192
coverage exclude -src rtl/pragya_machine_control.v -code b -line 184
coverage exclude -src rtl/pragya_machine_control.v -code e -line 104 106
coverage exclude -src rtl/pragya_machine_control.v -code c -line 259-264
coverage exclude -src rtl/pragya_mdu.v -code b -line 532 546
coverage exclude -src rtl/pragya_regfile.v -code c -line 37
coverage exclude -du work.pragya_machine_control -ft curr_state {STATE_OPERATING -> STATE_RESET} {STATE_TRAP_RETURN -> STATE_RESET} {STATE_TRAP_TAKEN -> STATE_RESET}
coverage exclude -du work.pragya_mdu -ft state {S_MUL -> S_IDLE} {S_CALC -> S_IDLE}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[0]} {commit_instr[1]} {commit_instr[2]} {commit_instr[3]} {commit_instr[4]} {commit_instr[5]} {commit_instr[6]} {commit_instr[7]} {commit_instr[8]} {commit_instr[9]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[10]} {commit_instr[11]} {commit_instr[12]} {commit_instr[13]} {commit_instr[14]} {commit_instr[15]} {commit_instr[16]} {commit_instr[17]} {commit_instr[18]} {commit_instr[19]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[20]} {commit_instr[21]} {commit_instr[22]} {commit_instr[23]} {commit_instr[24]} {commit_instr[25]} {commit_instr[26]} {commit_instr[27]} {commit_instr[28]} {commit_instr[29]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_instr[30]} {commit_instr[31]} {commit_pc[0]} {commit_pc[1]} {commit_pc[2]} {commit_pc[3]} {commit_pc[4]} {commit_pc[5]} {commit_pc[6]} {commit_pc[7]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_pc[8]} {commit_pc[9]} {commit_pc[10]} {commit_pc[11]} {commit_pc[12]} {commit_pc[13]} {commit_pc[14]} {commit_pc[15]} {commit_pc[16]} {commit_pc[17]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_pc[18]} {commit_pc[19]} {commit_pc[20]} {commit_pc[21]} {commit_pc[22]} {commit_pc[23]} {commit_pc[24]} {commit_pc[25]} {commit_pc[26]} {commit_pc[27]}
coverage exclude -scope /tb_pragya_top/dut -togglenode {commit_pc[28]} {commit_pc[29]} {commit_pc[30]} {commit_pc[31]} pg_riscv32_mp_imreq_out
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {cause_out[2]} {commit_instr_reg[0]} {commit_instr_reg[1]} {commit_pc_reg[0]} {commit_pc_reg[1]} {commit_pc_reg[15]} {commit_pc_reg[16]} {commit_pc_reg[17]} {commit_pc_reg[18]} {commit_pc_reg[19]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {commit_pc_reg[20]} {commit_pc_reg[21]} {commit_pc_reg[22]} {commit_pc_reg[23]} {commit_pc_reg[24]} {commit_pc_reg[25]} {commit_pc_reg[26]} {commit_pc_reg[27]} {commit_pc_reg[28]} {commit_pc_reg[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {commit_pc_reg[30]} {commit_pc_reg[31]} {commit_store_instr[0]} {commit_store_instr[1]} {commit_store_pc[0]} {commit_store_pc[1]} {commit_store_pc[15]} {commit_store_pc[16]} {commit_store_pc[17]} {commit_store_pc[18]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {commit_store_pc[19]} {commit_store_pc[20]} {commit_store_pc[21]} {commit_store_pc[22]} {commit_store_pc[23]} {commit_store_pc[24]} {commit_store_pc[25]} {commit_store_pc[26]} {commit_store_pc[27]} {commit_store_pc[28]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {commit_store_pc[29]} {commit_store_pc[30]} {commit_store_pc[31]} {epc_out[0]} {epc_out[1]} {id_instr[0]} {id_instr[1]} {instr_reg_out[0]} {instr_reg_out[1]} {mdu_instr[2]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {mdu_instr[3]} {mdu_instr[6]} {mdu_instr[26]} {mdu_instr[27]} {mdu_instr[28]} {mdu_instr[29]} {mdu_instr[30]} {mdu_instr[31]} {mdu_pc[0]} {mdu_pc[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {mdu_pc[15]} {mdu_pc[16]} {mdu_pc[17]} {mdu_pc[18]} {mdu_pc[19]} {mdu_pc[20]} {mdu_pc[21]} {mdu_pc[22]} {mdu_pc[23]} {mdu_pc[24]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {mdu_pc[25]} {mdu_pc[26]} {mdu_pc[27]} {mdu_pc[28]} {mdu_pc[29]} {mdu_pc[30]} {opcode_out[0]} {opcode_out[1]} {pc[0]} {pc_out[0]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_out[1]} {pc_out[15]} {pc_out[16]} {pc_out[17]} {pc_out[18]} {pc_out[19]} {pc_out[20]} {pc_out[21]} {pc_out[22]} {pc_out[23]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_out[24]} {pc_out[25]} {pc_out[26]} {pc_out[27]} {pc_out[28]} {pc_out[29]} {pc_out[30]} {pc_plus_4_out[0]} {pc_plus_4_pipline1_out[0]} {pc_plus_4_pipline1_out[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_plus_4_pipline1_out[15]} {pc_plus_4_pipline1_out[16]} {pc_plus_4_pipline1_out[17]} {pc_plus_4_pipline1_out[18]} {pc_plus_4_pipline1_out[19]} {pc_plus_4_pipline1_out[20]} {pc_plus_4_pipline1_out[21]} {pc_plus_4_pipline1_out[22]} {pc_plus_4_pipline1_out[23]} {pc_plus_4_pipline1_out[24]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_plus_4_pipline1_out[25]} {pc_plus_4_pipline1_out[26]} {pc_plus_4_pipline1_out[27]} {pc_plus_4_pipline1_out[28]} {pc_plus_4_pipline1_out[29]} {pc_plus_4_pipline1_out[30]} {pc_plus_4_reg_out[0]} {pc_plus_4_reg_out[1]} {pc_plus_4_reg_out[15]} {pc_plus_4_reg_out[16]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_plus_4_reg_out[17]} {pc_plus_4_reg_out[18]} {pc_plus_4_reg_out[19]} {pc_plus_4_reg_out[20]} {pc_plus_4_reg_out[21]} {pc_plus_4_reg_out[22]} {pc_plus_4_reg_out[23]} {pc_plus_4_reg_out[24]} {pc_plus_4_reg_out[25]} {pc_plus_4_reg_out[26]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_plus_4_reg_out[27]} {pc_plus_4_reg_out[28]} {pc_plus_4_reg_out[29]} {pc_plus_4_reg_out[30]} {pc_plus_4_reg_out[31]} {pc_reg_out[0]} {pc_reg_out[1]} {pc_reg_out[15]} {pc_reg_out[16]} {pc_reg_out[17]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_reg_out[18]} {pc_reg_out[19]} {pc_reg_out[20]} {pc_reg_out[21]} {pc_reg_out[22]} {pc_reg_out[23]} {pc_reg_out[24]} {pc_reg_out[25]} {pc_reg_out[26]} {pc_reg_out[27]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pc_reg_out[28]} {pc_reg_out[29]} {pc_reg_out[30]} {pc_reg_out[31]} {pipe2_instr[0]} {pipe2_instr[1]} {pipe2_pc[0]} {pipe2_pc[1]} {pipe2_pc[15]} {pipe2_pc[16]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pipe2_pc[17]} {pipe2_pc[18]} {pipe2_pc[19]} {pipe2_pc[20]} {pipe2_pc[21]} {pipe2_pc[22]} {pipe2_pc[23]} {pipe2_pc[24]} {pipe2_pc[25]} {pipe2_pc[26]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {pipe2_pc[27]} {pipe2_pc[28]} {pipe2_pc[29]} {pipe2_pc[30]} {trap_address_out[0]} {trap_address_out[1]} {trap_pc_out[0]} {trap_pc_out[1]} {trap_pc_out[15]} {trap_pc_out[16]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {trap_pc_out[17]} {trap_pc_out[18]} {trap_pc_out[19]} {trap_pc_out[20]} {trap_pc_out[21]} {trap_pc_out[22]} {trap_pc_out[23]} {trap_pc_out[24]} {trap_pc_out[25]} {trap_pc_out[26]}
coverage exclude -scope /tb_pragya_top/dut/CORE -togglenode {trap_pc_out[27]} {trap_pc_out[28]} {trap_pc_out[29]} {trap_pc_out[30]} {trap_pc_out[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/u_pc_unit -togglenode {pc[0]} {pc_next[0]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_out[0]} {pc_out[1]} {pc_out[15]} {pc_out[16]} {pc_out[17]} {pc_out[18]} {pc_out[19]} {pc_out[20]} {pc_out[21]} {pc_out[22]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_out[23]} {pc_out[24]} {pc_out[25]} {pc_out[26]} {pc_out[27]} {pc_out[28]} {pc_out[29]} {pc_out[30]} {pc_plus_4_pipline1_out[0]} {pc_plus_4_pipline1_out[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_plus_4_pipline1_out[15]} {pc_plus_4_pipline1_out[16]} {pc_plus_4_pipline1_out[17]} {pc_plus_4_pipline1_out[18]} {pc_plus_4_pipline1_out[19]} {pc_plus_4_pipline1_out[20]} {pc_plus_4_pipline1_out[21]} {pc_plus_4_pipline1_out[22]} {pc_plus_4_pipline1_out[23]} {pc_plus_4_pipline1_out[24]}
coverage exclude -scope /tb_pragya_top/dut/CORE/if_id_reg_inst -togglenode {pc_plus_4_pipline1_out[25]} {pc_plus_4_pipline1_out[26]} {pc_plus_4_pipline1_out[27]} {pc_plus_4_pipline1_out[28]} {pc_plus_4_pipline1_out[29]} {pc_plus_4_pipline1_out[30]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[0]} {i[1]} {i[2]} {i[3]} {i[4]} {i[5]} {i[6]} {i[7]} {i[8]} {i[9]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[10]} {i[11]} {i[12]} {i[13]} {i[14]} {i[15]} {i[16]} {i[17]} {i[18]} {i[19]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[20]} {i[21]} {i[22]} {i[23]} {i[24]} {i[25]} {i[26]} {i[27]} {i[28]} {i[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE/regfile_inst -togglenode {i[30]} {i[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mcause[4]} {mcause[5]} {mcause[6]} {mcause[7]} {mcause[8]} {mcause[9]} {mcause[10]} {mcause[11]} {mcause[12]} {mcause[13]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mcause[14]} {mcause[15]} {mcause[16]} {mcause[17]} {mcause[18]} {mcause[19]} {mcause[20]} {mcause[21]} {mcause[22]} {mcause[23]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mcause[24]} {mcause[25]} {mcause[26]} {mcause[27]} {mcause[28]} {mcause[29]} {mcause[30]} {mepc[0]} {mepc[1]} {mie[0]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mie[1]} {mie[2]} {mie[4]} {mie[5]} {mie[6]} {mie[8]} {mie[9]} {mie[10]} {mie[12]} {mie[13]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mie[14]} {mie[15]} {mie[16]} {mie[17]} {mie[18]} {mie[19]} {mie[20]} {mie[21]} {mie[22]} {mie[23]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {mie[24]} {mie[25]} {mie[26]} {mie[27]} {mie[28]} {mie[29]} {mie[30]} {mie[31]} {misa[0]} {misa[1]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa[2]} {misa[3]} {misa[4]} {misa[5]} {misa[6]} {misa[7]} {misa[8]} {misa[9]} {misa[10]} {misa[11]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa[13]} {misa[14]} {misa[15]} {misa[16]} {misa[17]} {misa[18]} {misa[19]} {misa[20]} {misa[21]} {misa[22]}
coverage exclude -scope /tb_pragya_top/dut/CORE/csr_inst -togglenode {misa[23]} {misa[24]} {misa[25]} {misa[26]} {misa[27]} {misa[28]} {misa[29]} {misa[30]} {misa[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/machine_control_inst -togglenode {cause_out[2]} {curr_state[0]} {next_state[0]} {trap_pc_out[0]} {trap_pc_out[1]} {trap_pc_out[15]} {trap_pc_out[16]} {trap_pc_out[17]} {trap_pc_out[18]} {trap_pc_out[19]}
coverage exclude -scope /tb_pragya_top/dut/CORE/machine_control_inst -togglenode {trap_pc_out[20]} {trap_pc_out[21]} {trap_pc_out[22]} {trap_pc_out[23]} {trap_pc_out[24]} {trap_pc_out[25]} {trap_pc_out[26]} {trap_pc_out[27]} {trap_pc_out[28]} {trap_pc_out[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE/machine_control_inst -togglenode {trap_pc_out[30]} {trap_pc_out[31]}
coverage exclude -scope /tb_pragya_top/dut/CORE/mdu_inst -togglenode {latched_instr[0]} {latched_instr[1]} {latched_instr[2]} {latched_instr[3]} {latched_instr[4]} {latched_instr[5]} {latched_instr[6]} {latched_instr[25]} {latched_instr[26]} {latched_instr[27]}
coverage exclude -scope /tb_pragya_top/dut/CORE/mdu_inst -togglenode {latched_instr[28]} {latched_instr[29]} {latched_instr[30]} {latched_instr[31]} {latched_pc[0]} {latched_pc[1]} {latched_pc[15]} {latched_pc[16]} {latched_pc[17]} {latched_pc[18]}
coverage exclude -scope /tb_pragya_top/dut/CORE/mdu_inst -togglenode {latched_pc[19]} {latched_pc[20]} {latched_pc[21]} {latched_pc[22]} {latched_pc[23]} {latched_pc[24]} {latched_pc[25]} {latched_pc[26]} {latched_pc[27]} {latched_pc[28]}
coverage exclude -scope /tb_pragya_top/dut/CORE/mdu_inst -togglenode {latched_pc[29]} {latched_pc[30]} {latched_pc[31]} {mdu_instr_out[2]} {mdu_instr_out[3]} {mdu_instr_out[6]} {mdu_instr_out[26]} {mdu_instr_out[27]} {mdu_instr_out[28]} {mdu_instr_out[29]}
coverage exclude -scope /tb_pragya_top/dut/CORE/mdu_inst -togglenode {mdu_instr_out[30]} {mdu_instr_out[31]} {mdu_pc_out[0]} {mdu_pc_out[1]} {mdu_pc_out[15]} {mdu_pc_out[16]} {mdu_pc_out[17]} {mdu_pc_out[18]} {mdu_pc_out[19]} {mdu_pc_out[20]}
coverage exclude -scope /tb_pragya_top/dut/CORE/mdu_inst -togglenode {mdu_pc_out[21]} {mdu_pc_out[22]} {mdu_pc_out[23]} {mdu_pc_out[24]} {mdu_pc_out[25]} {mdu_pc_out[26]} {mdu_pc_out[27]} {mdu_pc_out[28]} {mdu_pc_out[29]} {mdu_pc_out[30]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {instr_reg_out[0]} {instr_reg_out[1]} {pc_plus_4_reg_out[0]} {pc_plus_4_reg_out[1]} {pc_plus_4_reg_out[15]} {pc_plus_4_reg_out[16]} {pc_plus_4_reg_out[17]} {pc_plus_4_reg_out[18]} {pc_plus_4_reg_out[19]} {pc_plus_4_reg_out[20]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {pc_plus_4_reg_out[21]} {pc_plus_4_reg_out[22]} {pc_plus_4_reg_out[23]} {pc_plus_4_reg_out[24]} {pc_plus_4_reg_out[25]} {pc_plus_4_reg_out[26]} {pc_plus_4_reg_out[27]} {pc_plus_4_reg_out[28]} {pc_plus_4_reg_out[29]} {pc_plus_4_reg_out[30]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {pc_plus_4_reg_out[31]} {pc_reg_out[0]} {pc_reg_out[1]} {pc_reg_out[15]} {pc_reg_out[16]} {pc_reg_out[17]} {pc_reg_out[18]} {pc_reg_out[19]} {pc_reg_out[20]} {pc_reg_out[21]}
coverage exclude -scope /tb_pragya_top/dut/CORE/pipeline2_inst -togglenode {pc_reg_out[22]} {pc_reg_out[23]} {pc_reg_out[24]} {pc_reg_out[25]} {pc_reg_out[26]} {pc_reg_out[27]} {pc_reg_out[28]} {pc_reg_out[29]} {pc_reg_out[30]} {pc_reg_out[31]}
coverage exclude -scope /tb_pragya_top/dut/I_wrapper/imem -togglenode {instruction_out[0]} {instruction_out[1]}
