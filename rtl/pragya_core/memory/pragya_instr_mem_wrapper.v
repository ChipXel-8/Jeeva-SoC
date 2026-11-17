`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_instr_mem_wrapper
// Author     : chipXel team
// Description: Wrapper module for the Instruction Memory and its OBI 
//              (Open Bus Interface) controller. Integrates the core's 
//              instruction fetch requests with the bus protocol, providing 
//              immediate grant and registered valid signals along with the 
//              fetched instruction data.
// ============================================================================

module pragya_instr_mem_wrapper (
    // ========================================================
    // Global Signals
    // ========================================================
    input         pg_riscv32_mp_clk_in,  // System clock
    input         pg_riscv32_mp_rst_in,  // System reset (active high)

    // ========================================================
    // OBI Instruction Interface (from Core)
    // ========================================================
    input         instr_req_i,           // Instruction memory request valid
    input  [31:0] instr_addr_i,          // Instruction memory fetch address (PC)

    output        instr_gnt_o,           // OBI grant signal (request accepted)
    output        instr_rvalid_o,        // OBI read valid signal (instruction ready)
    output [31:0] instr_rdata_o          // Fetched instruction data
);

    // ========================================================
    // Instruction Memory Instantiation
    // ========================================================
    // Instantiates the physical instruction memory block.
    pragya_imem imem (
        .clk_in          (pg_riscv32_mp_clk_in), // Connect system clock for synchronous read
        .addr_in         (instr_addr_i),         // Connect fetch address
        .instruction_out (instr_rdata_o)         // Connect instruction output
    );

    // ========================================================
    // OBI Controller Instantiation
    // ========================================================
    // Handles the Open Bus Interface handshake protocol.
    // Automatically asserts grant (gnt) and manages the valid (rvalid)
    // response timing for the core's fetch stage.
    obi_ctrl obi (
        .clk    (pg_riscv32_mp_clk_in),
        .rst    (pg_riscv32_mp_rst_in),
        .req    (instr_req_i),           // Input request from core's IF stage

        .gnt    (instr_gnt_o),           // Output grant to core
        .rvalid (instr_rvalid_o)         // Output response valid to core
    );

endmodule
