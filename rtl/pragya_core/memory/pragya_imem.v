`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_imem
// Author     : chipXel team
// Description: Instruction Memory module for the pragya processor.
//              Implements a 32 KB (8192 x 32-bit words) synchronous memory.
//              The memory is initialized from a file ("program.mem") and 
//              instructions are fetched synchronously on the clock edge.
// ============================================================================

module pragya_imem (
    input             clk_in,          // System clock
    input      [31:0] addr_in,         // 32-bit instruction address from PC
    output reg [31:0] instruction_out  // 32-bit fetched instruction
);

    // ========================================================================
    // Memory Array Definition
    // ========================================================================
    // 32 KB instruction memory, word-addressed (8192 words x 32 bits)
    reg [31:0] memory [0:8191];

    // ========================================================================
    // Memory Initialization
    // ========================================================================
    initial begin
        // Load initial instruction memory contents from the hex file
        $readmemh("program.mem", memory);
    end

    // ========================================================================
    // Synchronous Read Logic
    // ========================================================================
    always @(posedge clk_in) begin
        // Fetch the instruction at the given word-aligned address.
        // addr_in[14:2] extracts the 13-bit word index for the 8192-word array,
        // ignoring the byte offset (bits 1:0).
        instruction_out <= memory[addr_in[14:2]];
    end

endmodule


