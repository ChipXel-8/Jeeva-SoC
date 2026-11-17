`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_data_mem_wrapper
// Author     : chipXel team
// Description: Wrapper module for the Data Memory and its OBI (Open Bus Interface)
//              controller. It integrates the core's data memory requests with the 
//              bus protocol, providing immediate grant and registered valid signals
//              along with memory read/write access.
// ============================================================================

module pragya_data_mem_wrapper (
    // ========================================================
    // Global Signals
    // ========================================================
    input         pg_riscv32_mp_clk_in,  // System clock
    input         pg_riscv32_mp_rst_in,  // System reset (active high)

    // ========================================================
    // OBI Data Interface (from Core)
    // ========================================================
    input         data_req_i,            // Data memory request valid
    input         data_we_i,             // Data memory write enable
    input  [3:0]  data_be_i,             // Data memory byte enable
    input  [31:0] data_addr_i,           // Data memory address
    input  [31:0] data_wdata_i,          // Data memory write data

    output        data_gnt_o,            // OBI grant signal (request accepted)
    output        data_rvalid_o,         // OBI read valid signal (data is ready)
    output [31:0] data_rdata_o           // Data memory read data
);

    // ========================================================
    // Data Memory Instantiation
    // ========================================================
    // Instantiates the physical data memory block. The base address
    // is parameterizable and set to 0x80008000 for this configuration.
    pragya_dmem #(
        .DMEM_BASE(32'h80008000)
    ) dmem (
        .clk_in       (pg_riscv32_mp_clk_in),

        .dm_req_in    (data_req_i),      // Connect request signal
        .dm_wen_in    (data_we_i),       // Connect write enable
        .dm_be_in     (data_be_i),       // Connect byte enables

        .dm_addr_in   (data_addr_i),     // Connect target address
        .dm_wdata_in  (data_wdata_i),    // Connect write data

        .dm_rdata_out (data_rdata_o)     // Connect read data output
    );

    // ========================================================
    // OBI Controller Instantiation
    // ========================================================
    // Handles the Open Bus Interface handshake protocol.
    // Automatically asserts grant (gnt) and manages the valid (rvalid)
    // response timing for the core's LSU.
    obi_ctrl obi (
        .clk    (pg_riscv32_mp_clk_in),
        .rst    (pg_riscv32_mp_rst_in),
        .req    (data_req_i),            // Input request from core

        .gnt    (data_gnt_o),            // Output grant to core
        .rvalid (data_rvalid_o)          // Output response valid to core
    );

endmodule
