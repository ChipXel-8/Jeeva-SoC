`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_de_mw_pipeline
// Author     : chipXel team
// Description: Decode/Execute to Memory/Writeback Pipeline Register.
//              Isolates the execute stage from the memory/writeback stage.
//              Latches all execution results (ALU, MDU, CSR) and control 
//              signals. Handles pipeline stalls (stall_mw) and flushes (flush)
//              to insert bubbles when necessary.
// ============================================================================

module pragya_de_mw_pipeline (
    input clk_in,     // System Clock
    input rst_in,     // System Reset (active high)
    
    // ========================================================
    // Inputs from Decode/Execute (DE) Stage
    // ========================================================
    input        valid_de,      // 1 = Valid instruction from DE stage
    input        mem_req_in,    // 1 = Memory operation requested (LOAD/STORE)
    input        mem_write_in,  // 1 = Memory write operation (STORE)
    input [31:0] mdu_result_in, // Computed result from MDU
    input [31:0] alu_result_in, // Computed result from ALU
    input [31:0] i_adder_in,    // Computed address (for memory or branch)
    input [31:0] imm_in,        // Sign-extended immediate value
    input [31:0] pc_plus_4_in,  // Sequential PC (PC + 4)
    input [31:0] pc_in,         // Current Program Counter
    input [31:0] instr_in,      // Current Instruction
    input [31:0] rs_2_in,       // Source Register 2 data (for STORE operations)
    input [4:0]  rd_addrs_in,   // Destination Register address
    input [2:0]  funct3_in,     // Instruction type (funct3 field)
    input [2:0]  wb_mux_sel_in, // Write-back multiplexer selection
    input        reg_write_in,  // Register file write enable
    
    // CSR Inputs
    input        csr_wr_en_in,  // CSR write enable
    input [11:0] csr_addr_in,   // CSR target address
    input [2:0]  csr_op_in,     // CSR operation type
    input [31:0] csr_data_in,   // Data to write to CSR
    input [4:0]  csr_imm_in,    // Immediate value for CSR operations
    
    // ========================================================
    // Inputs from Memory / Hazard Unit
    // ========================================================
    input        rvalid,        // 1 = Memory response is valid (from data bus)
    input        stall_mw,      // 1 = Stall the MW stage (e.g., waiting for memory)
    
    // ========================================================
    // Pipeline Control Inputs
    // ========================================================
    input        flush,         // 1 = Flush pipeline (insert bubble)
    
    // ========================================================
    // Outputs to Memory (MEM) and Writeback (WB) Stages
    // ========================================================
    output reg        mem_wb_valid,       // 1 = Pipeline register holds valid instruction
    output reg        mem_req_reg_out,    // Registered memory request
    output reg        mem_write_reg_out,  // Registered memory write enable
    output reg [31:0] mdu_result_reg_out, // Registered MDU result
    output reg [31:0] alu_result_reg_out, // Registered ALU result
    output reg [31:0] i_adder_reg_out,    // Registered address calculation
    output reg [31:0] imm_reg_out,        // Registered immediate
    output reg [31:0] pc_plus_4_reg_out,  // Registered PC + 4
    output reg [31:0] rs_2_reg_out,       // Registered Store data
    output reg [4:0]  rd_addrs_reg_out,   // Registered Destination address
    output reg [31:0] pc_reg_out,         // Registered PC
    output reg [31:0] instr_reg_out,      // Registered Instruction
    output reg [2:0]  funct3_reg_out,     // Registered funct3
    output reg [2:0]  wb_mux_sel_reg_out, // Registered Write-back select
    output reg        reg_write_reg_out,  // Registered Register write enable
    
    // Registered CSR Outputs
    output reg        csr_wr_en_reg_out, 
    output reg [11:0] csr_addr_reg_out,
    output reg [2:0]  csr_op_reg_out,
    output reg [31:0] csr_data_reg_out,
    output reg [4:0]  csr_imm_reg_out
);
    
    // ========================================================================
    // Pipeline Register Update Logic
    // ========================================================================
    always @(posedge clk_in or posedge rst_in)
    begin
        // 1. Reset or Flush condition: Clear all registers to insert a bubble
        if (rst_in || flush)
        begin
            mem_wb_valid       <= 1'b0;
            mem_req_reg_out    <= 1'b0;
            mem_write_reg_out  <= 1'b0;
            mdu_result_reg_out <= 32'b0;
            alu_result_reg_out <= 32'b0;
            i_adder_reg_out    <= 32'b0;
            pc_reg_out         <= 32'b0;
            instr_reg_out      <= 32'b0;
            imm_reg_out        <= 32'b0;
            pc_plus_4_reg_out  <= 32'b0;
            rs_2_reg_out       <= 32'b0;
            rd_addrs_reg_out   <= 5'b0;
            funct3_reg_out     <= 3'b0;
            wb_mux_sel_reg_out <= 3'b0;
            reg_write_reg_out  <= 1'b0;
            csr_wr_en_reg_out  <= 1'b0;
            csr_addr_reg_out   <= 12'b0;
            csr_op_reg_out     <= 3'b0;
            csr_data_reg_out   <= 32'b0;
            csr_imm_reg_out    <= 5'b0;
        end
        // 2. Normal Operation: Update registers if MW stage is not stalled
        else if (!stall_mw)
        begin
            // 2A. Valid Instruction: Pass all data and control signals forward
            if (valid_de)
            begin
                mem_wb_valid       <= 1'b1;
                mem_req_reg_out    <= mem_req_in;
                mem_write_reg_out  <= mem_write_in;
                mdu_result_reg_out <= mdu_result_in;
                alu_result_reg_out <= alu_result_in;
                i_adder_reg_out    <= i_adder_in;
                imm_reg_out        <= imm_in;
                pc_plus_4_reg_out  <= pc_plus_4_in;
                pc_reg_out         <= pc_in;
                instr_reg_out      <= instr_in;
                rs_2_reg_out       <= rs_2_in;
                rd_addrs_reg_out   <= rd_addrs_in;
                funct3_reg_out     <= funct3_in;
                wb_mux_sel_reg_out <= wb_mux_sel_in;
                reg_write_reg_out  <= reg_write_in;
                csr_wr_en_reg_out  <= csr_wr_en_in;
                csr_addr_reg_out   <= csr_addr_in;
                csr_op_reg_out     <= csr_op_in;
                csr_data_reg_out   <= csr_data_in;
                csr_imm_reg_out    <= csr_imm_in;
            end
            // 2B. Invalid Instruction: Insert bubble by clearing critical control signals
            else
            begin
                mem_wb_valid       <= 1'b0;
                mem_req_reg_out    <= 1'b0;
                mem_write_reg_out  <= 1'b0;
                reg_write_reg_out  <= 1'b0;
                wb_mux_sel_reg_out <= 3'b0;
                rd_addrs_reg_out   <= 5'b0;
                funct3_reg_out     <= 3'b0;
                csr_wr_en_reg_out  <= 1'b0;
            end
        end
    end
  
endmodule
