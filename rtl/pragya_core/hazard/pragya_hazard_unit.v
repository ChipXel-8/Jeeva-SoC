`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_hazard_unit
// Author     : chipXel team
// Description: Hazard Detection and Forwarding Unit for the pragya processor.
//              Resolves data hazards by forwarding data from the Memory/Writeback 
//              (MW) stage to the Decode/Execute (DE) stage. Also detects structural 
//              and control hazards, generating appropriate pipeline stalls (stallD) 
//              and flushes (flush_DE). Handles WFI (Wait for Interrupt) stalls.
// ============================================================================

module pragya_hazard_unit (
    // ========================================================
    // Inputs from Decode/Execute (DE) Stage
    // ========================================================
    input  [4:0] rs1_DE,        // Source Register 1 address currently in DE
    input  [4:0] rs2_DE,        // Source Register 2 address currently in DE
    input  [4:0] rd_DE,         // Destination Register address currently in DE
    input  [2:0] wb_sel_DE,     // Write-back selection from DE
    input        mem_req_DE,    // Memory request active in DE
    
    // ========================================================
    // Stall Request Inputs
    // ========================================================
    input        wait_for_mem,  // Stall request from LSU (waiting for memory response)
    input        mdu_stall,     // Stall request from MDU (multi-cycle operation pending)
    input        wfi_stall,     // Stall request from Machine Control (Wait For Interrupt)

    // ========================================================
    // Inputs from Instruction Fetch (IF) and Memory/Writeback (MW)
    // ========================================================
    input  [31:0] instr_IF,     // Instruction currently in IF stage
    input  [4:0]  rd_MW,        // Destination Register address currently in MW stage
    input         reg_write_MW, // Register write enable signal in MW stage
    input         branch_taken, // Branch taken decision from DE stage

    // ========================================================
    // Hazard Control Outputs
    // ========================================================
    output        forward_a,    // Forward data to ALU operand A (rs1)
    output        forward_b,    // Forward data to ALU operand B (rs2)
    output        stallD,       // Stall IF/ID pipeline registers and PC
    output        flush_DE,     // Flush IF/ID pipeline register (insert bubble in DE)
    output        flush_de_mw   // Flush DE/MW pipeline register (insert bubble in MW)
);

    // Extract source registers from the instruction currently in the IF stage
    // (Used for advanced load-use hazard detection if implemented)
    wire [4:0] rs1_IF = instr_IF[19:15];
    wire [4:0] rs2_IF = instr_IF[24:20];

    // ========================================================================
    // Data Forwarding Logic (MW to DE)
    // ========================================================================
    // Forward data if the MW stage is writing to a register (reg_write_MW),
    // the destination register is not x0 (rd_MW != 5'd0), and the destination
    // matches the source register required in the DE stage.
    assign forward_a = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs1_DE);
    assign forward_b = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs2_DE);

    // ========================================================================
    // Stall Logic
    // ========================================================================
    // Generate a stall if there is a pending memory operation in DE
    wire stall_mem_op = mem_req_DE;

    // Stall the pipeline (freeze PC and IF/ID registers) if:
    // 1. A memory operation is issued (stall_mem_op)
    // 2. Waiting for a memory response (wait_for_mem)
    // 3. MDU is busy calculating (mdu_stall)
    // 4. Core is in Wait For Interrupt state (wfi_stall)
    assign stallD = stall_mem_op | wait_for_mem | mdu_stall | wfi_stall; 

    // ========================================================================
    // Flush Logic (Control Hazards)
    // ========================================================================
    // Flush the instruction in the decode stage if a branch is taken,
    // as the sequentially fetched instruction is incorrect.
    assign flush_DE = branch_taken;
    
    // Currently, there are no conditions defined that require flushing the MW stage
    assign flush_de_mw = 1'b0;

endmodule
