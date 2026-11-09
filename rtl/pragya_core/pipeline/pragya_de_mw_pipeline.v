`timescale 1ns / 1ps


module pragya_de_mw_pipeline (
    input clk_in,     // Clock
    input rst_in,     // Reset (active high)
    // ===== From DE stage =====
    input        valid_de,    // Instruction valid from previous stage
    input        mem_req_in,     // 1 = memory operation (LOAD/STORE)
    input        mem_write_in,   // 1 = STORE
    input [31:0] mdu_result_in,  // MDU result
    input [31:0] alu_result_in,  // ALU result
    input [31:0] i_adder_in,     // Address calculation
    input [31:0] imm_in,         // Immediate value
    input [31:0] pc_plus_4_in,   // PC + 4
    input [31:0] pc_in,
    input [31:0] instr_in,
    input [31:0] rs_2_in,        // Store data
    input [4:0]  rd_addrs_in,    // Destination register
    input [2:0]  funct3_in,      // Instruction type
    input [2:0]  wb_mux_sel_in,  // Write-back select
    input        reg_write_in,   // Register write enable
    input        csr_wr_en_in,
    input [11:0] csr_addr_in,
    input [2:0]  csr_op_in,
    input [31:0] csr_data_in,
    input [4:0]  csr_imm_in,
    // ===== From Memory =====
    input        rvalid,         // Memory response valid
    input        stall_mw,
    // ===== Control =====
    input        flush,          // Flush pipeline
    // ===== Outputs to MEM + WB =====
    output reg        mem_wb_valid,
    output reg        mem_req_reg_out,
    output reg        mem_write_reg_out,
    output reg [31:0] mdu_result_reg_out,
    output reg [31:0] alu_result_reg_out,
    output reg [31:0] i_adder_reg_out,
    output reg [31:0] imm_reg_out,
    output reg [31:0] pc_plus_4_reg_out,
    output reg [31:0] rs_2_reg_out,
    output reg [4:0]  rd_addrs_reg_out,
    output reg [31:0] pc_reg_out,
    output reg [31:0] instr_reg_out,
    output reg [2:0]  funct3_reg_out,
    output reg [2:0]  wb_mux_sel_reg_out,
    output reg        reg_write_reg_out,
    output reg        csr_wr_en_reg_out,
    output reg [11:0] csr_addr_reg_out,
    output reg [2:0]  csr_op_reg_out,
    output reg [31:0] csr_data_reg_out,
    output reg [4:0]  csr_imm_reg_out
 
);
    
    
    always @(posedge clk_in or posedge rst_in)
    begin
        if (rst_in || flush)
        begin
            mem_wb_valid <= 1'b0;
            mem_req_reg_out      <= 1'b0;
            mem_write_reg_out    <= 1'b0;
            mdu_result_reg_out   <= 32'b0;
            alu_result_reg_out   <= 32'b0;
            i_adder_reg_out      <= 32'b0;
            pc_reg_out    <= 32'b0;
            instr_reg_out <= 32'b0;
            imm_reg_out          <= 32'b0;
            pc_plus_4_reg_out    <= 32'b0;
            rs_2_reg_out         <= 32'b0;
            rd_addrs_reg_out     <= 5'b0;
            funct3_reg_out       <= 3'b0;
            wb_mux_sel_reg_out   <= 3'b0;
            reg_write_reg_out    <= 1'b0;
            csr_wr_en_reg_out <= 1'b0;
            csr_addr_reg_out  <= 12'b0;
            csr_op_reg_out    <= 3'b0;
            csr_data_reg_out  <= 32'b0;
            csr_imm_reg_out   <= 5'b0;
        end

        else if (!stall_mw)
        begin
        if (valid_de)
        begin
            
                mem_wb_valid         <= 1'b1;
                mem_req_reg_out      <= mem_req_in;
                mem_write_reg_out    <= mem_write_in;
                mdu_result_reg_out   <= mdu_result_in;
                alu_result_reg_out   <= alu_result_in;
                i_adder_reg_out      <= i_adder_in;
                imm_reg_out          <= imm_in;
                pc_plus_4_reg_out    <= pc_plus_4_in;
                pc_reg_out    <= pc_in;
                instr_reg_out <= instr_in;
                rs_2_reg_out         <= rs_2_in;
                rd_addrs_reg_out     <= rd_addrs_in;
                funct3_reg_out       <= funct3_in;
                wb_mux_sel_reg_out   <= wb_mux_sel_in;
                reg_write_reg_out    <= reg_write_in;
                csr_wr_en_reg_out <= csr_wr_en_in;
                csr_addr_reg_out  <= csr_addr_in;
                csr_op_reg_out    <= csr_op_in;
                csr_data_reg_out  <= csr_data_in;
                csr_imm_reg_out   <= csr_imm_in;
            end
          else
            begin
                // Insert bubble
                mem_wb_valid        <= 1'b0;
                mem_req_reg_out     <= 1'b0;
                mem_write_reg_out   <= 1'b0;
                reg_write_reg_out   <= 1'b0;
                wb_mux_sel_reg_out  <= 3'b0;
                rd_addrs_reg_out    <= 5'b0;
                funct3_reg_out      <= 3'b0;
                csr_wr_en_reg_out <= 1'b0;
            end

    

      

    end
    end
  
endmodule
