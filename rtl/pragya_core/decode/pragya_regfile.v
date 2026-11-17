`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_regfile
// Author     : chipXel team
// Description: 32x32-bit Register File for the pragya RISC-V processor.
//              Provides two combinational read ports and one synchronous 
//              write port. Hardwires register x0 to always read as 0, 
//              compliant with the RISC-V ISA specification.
// ============================================================================

module pragya_regfile (
    // ========================================================
    // Global Signals
    // ========================================================
    input  wire        clk_in,
    input  wire        rst_in,

    // ========================================================
    // Control and Address Inputs (from Decode Stage)
    // ========================================================
    input  wire        reg_write_in,   // Register write enable
    input  wire [4:0]  rs_1_addrs_in,  // Source register 1 address
    input  wire [4:0]  rs_2_addrs_in,  // Source register 2 address
    input  wire [4:0]  rd_addrs_in,    // Destination register address

    // ========================================================
    // Data Input (from Writeback Stage)
    // ========================================================
    input  wire [31:0] wb_mux_in,      // Data to be written into the destination register

    // ========================================================
    // Data Outputs (to Execution Stage)
    // ========================================================
    output reg  [31:0] rs_1_out,       // Source register 1 data output (to ALU/MDU/Branch)
    output reg  [31:0] rs_2_out        // Source register 2 data output (to ALU/MDU/Branch)
);

    // ========================================================================
    // Memory Array Definition
    // ========================================================================
    // 32 registers, each 32 bits wide
    reg [31:0] regfile [0:31]; 

    integer i;

    // ========================================================================
    // Synchronous Write & Reset Logic
    // ========================================================================
    always @(posedge clk_in or posedge rst_in) begin
        // 1. Reset: Clear all registers to zero
        if (rst_in) begin
            for (i = 0; i < 32; i = i + 1) begin
                regfile[i] <= 32'b0;
            end
        end
        // 2. Write Operation: Write data if enabled and destination is not x0
        else if (reg_write_in && (rd_addrs_in != 5'b00000)) begin
            regfile[rd_addrs_in] <= wb_mux_in;
        end
    end

    // ========================================================================
    // Combinational Read Logic
    // ========================================================================
    // Reads are asynchronous (combinational) to allow decoding and operand 
    // fetching in the same cycle. Register x0 (address 0) is strictly 
    // hardwired to 32'b0.
    always @(*) begin
        // Source Register 1 Read
        if (rs_1_addrs_in == 5'd0)
            rs_1_out = 32'b0;
        else
            rs_1_out = regfile[rs_1_addrs_in];

        // Source Register 2 Read
        if (rs_2_addrs_in == 5'd0)
            rs_2_out = 32'b0;
        else
            rs_2_out = regfile[rs_2_addrs_in];
    end
    
endmodule
