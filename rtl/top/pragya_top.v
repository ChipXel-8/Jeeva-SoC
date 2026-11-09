`timescale 1ns / 1ps

module pragya_top(input pg_riscv32_mp_clk_in,
                  input pg_riscv32_mp_rst_in,
                  input pg_riscv32_mp_eirq_in,
                  input pg_riscv32_mp_tirq_in,
                  input pg_riscv32_mp_sirq_in,
                  input pg_riscv32_mp_debug_req_in
    );
    
    wire [31:0] pg_riscv32_mp_dmdata_out;
    wire [31:0] pg_riscv32_mp_dmaddr_out;
    wire [31:0] pg_riscv32_mp_imaddr_out;
    wire        pg_riscv32_mp_dmreq_out;
    wire        pg_riscv32_mp_dmwen_out;
    wire [3:0]  pg_riscv32_mp_dmbe_out;
    wire        pg_riscv32_mp_imreq_out;
    wire        commit_valid;
    wire [31:0] commit_pc;
    wire [31:0] commit_instr;
    wire [4:0]  commit_rd;
    wire [31:0] commit_data;

wire [31:0] commit_rs1_data;
wire [31:0] commit_rs2_data;
    
    
    //========================================================
    // Instruction OBI Signals
    //========================================================
    
    wire        instr_gnt_o;
    wire        instr_rvalid_o;
    wire [31:0] instr_rdata_o;
    
    //========================================================
    // Data OBI Signals
    //========================================================
    
    wire        data_gnt_o;
    wire        data_rvalid_o;
    wire [31:0] data_rdata_o;

pragya_core CORE(.pg_riscv32_mp_clk_in(pg_riscv32_mp_clk_in),
                 .pg_riscv32_mp_rst_in(pg_riscv32_mp_rst_in),
                 .pg_riscv32_mp_eirq_in(pg_riscv32_mp_eirq_in),
                 .pg_riscv32_mp_tirq_in(pg_riscv32_mp_tirq_in),
                 .pg_riscv32_mp_sirq_in(pg_riscv32_mp_sirq_in),
                 .pg_riscv32_mp_instr_valid(instr_rvalid_o),
                 .pg_riscv32_mp_data_valid(data_rvalid_o),
                 .pg_riscv32_mp_instr_gnt(instr_gnt_o),
                 .pg_riscv32_mp_data_gnt(data_gnt_o),
                 .pg_riscv32_mp_instr_in(instr_rdata_o),
                 .pg_riscv32_mp_dmdata_in(data_rdata_o),
                 .pg_riscv32_mp_debug_req_in(pg_riscv32_mp_debug_req_in),
                 .pg_riscv32_mp_dmdata_out(pg_riscv32_mp_dmdata_out),
                 .pg_riscv32_mp_dmaddr_out(pg_riscv32_mp_dmaddr_out),
                 .pg_riscv32_mp_imaddr_out(pg_riscv32_mp_imaddr_out),
                 .pg_riscv32_mp_dmwen_out(pg_riscv32_mp_dmwen_out),
                 .pg_riscv32_mp_dmbe_out(pg_riscv32_mp_dmbe_out),
                 .pg_riscv32_mp_dmreq_out(pg_riscv32_mp_dmreq_out),
                 .pg_riscv32_mp_imreq_out(pg_riscv32_mp_imreq_out),
                 .commit_valid(commit_valid),
                 .commit_pc(commit_pc),
                 .commit_instr(commit_instr),
                 .commit_rd(commit_rd),
                 .commit_data(commit_data),
                 .commit_instr_valid(commit_instr_valid),
		 .commit_rs1_data(commit_rs1_data),
		 .commit_rs2_data(commit_rs2_data)
                 );
                 
pragya_instr_mem_wrapper I_wrapper(
                     .pg_riscv32_mp_clk_in(pg_riscv32_mp_clk_in),
                     .pg_riscv32_mp_rst_in(pg_riscv32_mp_rst_in),
                 
                     .instr_req_i(pg_riscv32_mp_imreq_out),
                     .instr_addr_i(pg_riscv32_mp_imaddr_out),
                 
                     .instr_gnt_o(instr_gnt_o),
                     .instr_rvalid_o(instr_rvalid_o),
                     .instr_rdata_o(instr_rdata_o)
                 );  
                                   
pragya_data_mem_wrapper D_wrapper(
                                       .pg_riscv32_mp_clk_in(pg_riscv32_mp_clk_in),
                                       .pg_riscv32_mp_rst_in(pg_riscv32_mp_rst_in),
                                   
                                       .data_req_i(pg_riscv32_mp_dmreq_out),
                                       .data_we_i(pg_riscv32_mp_dmwen_out),
                                       .data_be_i(pg_riscv32_mp_dmbe_out),
                                       .data_addr_i(pg_riscv32_mp_dmaddr_out),
                                       .data_wdata_i(pg_riscv32_mp_dmdata_out),
                                   
                                       .data_gnt_o(data_gnt_o),
                                       .data_rvalid_o(data_rvalid_o),
                                       .data_rdata_o(data_rdata_o)
                                   );
                 
                 
endmodule
