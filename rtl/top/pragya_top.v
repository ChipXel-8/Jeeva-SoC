`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_top
// Author     : chipXel team
// Description: Top-level integration module for the pragya RISC-V processor.
//              Connects the core processor (pragya_core) to its surrounding
//              subsystems, specifically the Instruction Memory Wrapper and 
//              Data Memory Wrapper, bridging them via OBI signals.
// ============================================================================

module pragya_top(
    input pg_riscv32_mp_clk_in,        // Global clock signal
    input pg_riscv32_mp_rst_in,        // Global reset signal (active high)
    
    // ========================================================
    // Interrupt & Debug Inputs
    // ========================================================
    input pg_riscv32_mp_eirq_in,       // External Interrupt Request
    input pg_riscv32_mp_tirq_in,       // Timer Interrupt Request
    input pg_riscv32_mp_sirq_in,       // Software Interrupt Request
    input pg_riscv32_mp_debug_req_in   // Hardware Debug Request
);
    
    // ========================================================
    // Core to Data Memory Signals
    // ========================================================
    wire [31:0] pg_riscv32_mp_dmdata_out; // Data to write to memory
    wire [31:0] pg_riscv32_mp_dmaddr_out; // Target data memory address
    wire        pg_riscv32_mp_dmreq_out;  // Data memory access request
    wire        pg_riscv32_mp_dmwen_out;  // Data memory write enable
    wire [3:0]  pg_riscv32_mp_dmbe_out;   // Data memory byte enable mask
    
    // ========================================================
    // Core to Instruction Memory Signals
    // ========================================================
    wire [31:0] pg_riscv32_mp_imaddr_out; // Target instruction fetch address (PC)
    wire        pg_riscv32_mp_imreq_out;  // Instruction fetch request
    
    // ========================================================
    // Instruction Commit / RVFI Signals (Trace/Debug outputs)
    // ========================================================
    wire        commit_valid;             // Instruction successfully committed
    wire [31:0] commit_pc;                // PC of committed instruction
    wire [31:0] commit_instr;             // Committed instruction word
    wire [4:0]  commit_rd;                // Destination register updated
    wire [31:0] commit_data;              // Data written to destination register
    wire        commit_instr_valid;       // Instruction retired valid flag
    wire [31:0] commit_rs1_data;          // Source Register 1 data used
    wire [31:0] commit_rs2_data;          // Source Register 2 data used
    
    // ========================================================
    // OBI (Open Bus Interface) Signals - Instruction Memory
    // ========================================================
    wire        instr_gnt_o;              // Grant from IMEM
    wire        instr_rvalid_o;           // Response valid from IMEM
    wire [31:0] instr_rdata_o;            // Fetched instruction data
    
    // ========================================================
    // OBI (Open Bus Interface) Signals - Data Memory
    // ========================================================
    wire        data_gnt_o;               // Grant from DMEM
    wire        data_rvalid_o;            // Response valid from DMEM
    wire [31:0] data_rdata_o;             // Read data from DMEM

    // ========================================================================
    // Core Processor Instantiation
    // ========================================================================
    pragya_core CORE(
        .pg_riscv32_mp_clk_in       (pg_riscv32_mp_clk_in),
        .pg_riscv32_mp_rst_in       (pg_riscv32_mp_rst_in),
        .pg_riscv32_mp_eirq_in      (pg_riscv32_mp_eirq_in),
        .pg_riscv32_mp_tirq_in      (pg_riscv32_mp_tirq_in),
        .pg_riscv32_mp_sirq_in      (pg_riscv32_mp_sirq_in),
        .pg_riscv32_mp_debug_req_in (pg_riscv32_mp_debug_req_in),
        
        // Instruction OBI Inputs
        .pg_riscv32_mp_instr_valid  (instr_rvalid_o),
        .pg_riscv32_mp_instr_gnt    (instr_gnt_o),
        .pg_riscv32_mp_instr_in     (instr_rdata_o),
        
        // Data OBI Inputs
        .pg_riscv32_mp_data_valid   (data_rvalid_o),
        .pg_riscv32_mp_data_gnt     (data_gnt_o),
        .pg_riscv32_mp_dmdata_in    (data_rdata_o),
        
        // Memory Outputs
        .pg_riscv32_mp_dmdata_out   (pg_riscv32_mp_dmdata_out),
        .pg_riscv32_mp_dmaddr_out   (pg_riscv32_mp_dmaddr_out),
        .pg_riscv32_mp_imaddr_out   (pg_riscv32_mp_imaddr_out),
        .pg_riscv32_mp_dmwen_out    (pg_riscv32_mp_dmwen_out),
        .pg_riscv32_mp_dmbe_out     (pg_riscv32_mp_dmbe_out),
        .pg_riscv32_mp_dmreq_out    (pg_riscv32_mp_dmreq_out),
        .pg_riscv32_mp_imreq_out    (pg_riscv32_mp_imreq_out),
        
        // Commit/RVFI Outputs
        .commit_valid               (commit_valid),
        .commit_pc                  (commit_pc),
        .commit_instr               (commit_instr),
        .commit_rd                  (commit_rd),
        .commit_data                (commit_data),
        .commit_instr_valid         (commit_instr_valid),
        .commit_rs1_data            (commit_rs1_data),
        .commit_rs2_data            (commit_rs2_data)
    );
                 
    // ========================================================================
    // Instruction Memory Wrapper Instantiation
    // ========================================================================
    pragya_instr_mem_wrapper I_wrapper(
        .pg_riscv32_mp_clk_in (pg_riscv32_mp_clk_in),
        .pg_riscv32_mp_rst_in (pg_riscv32_mp_rst_in),
                 
        .instr_req_i          (pg_riscv32_mp_imreq_out),
        .instr_addr_i         (pg_riscv32_mp_imaddr_out),
                 
        .instr_gnt_o          (instr_gnt_o),
        .instr_rvalid_o       (instr_rvalid_o),
        .instr_rdata_o        (instr_rdata_o)
    );  
                                   
    // ========================================================================
    // Data Memory Wrapper Instantiation
    // ========================================================================
    pragya_data_mem_wrapper D_wrapper(
        .pg_riscv32_mp_clk_in (pg_riscv32_mp_clk_in),
        .pg_riscv32_mp_rst_in (pg_riscv32_mp_rst_in),
                                   
        .data_req_i           (pg_riscv32_mp_dmreq_out),
        .data_we_i            (pg_riscv32_mp_dmwen_out),
        .data_be_i            (pg_riscv32_mp_dmbe_out),
        .data_addr_i          (pg_riscv32_mp_dmaddr_out),
        .data_wdata_i         (pg_riscv32_mp_dmdata_out),
                                   
        .data_gnt_o           (data_gnt_o),
        .data_rvalid_o        (data_rvalid_o),
        .data_rdata_o         (data_rdata_o)
    );
                 
endmodule
