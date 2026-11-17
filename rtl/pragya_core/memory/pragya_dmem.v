`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_dmem
// Author     : chipXel team
// Description: Data Memory module for the pragya processor.
//              Implements a 64 KB (16384 x 32-bit words) synchronous SRAM 
//              with byte-enable support for granular memory writes (store 
//              byte, half-word, word). Memory is initialized from a file.
// ============================================================================

module pragya_dmem #(
    parameter [31:0] DMEM_BASE = 32'h00008000 // Base address of the data memory
)(
    input             clk_in,       // System clock
    input             dm_req_in,    // Data memory request enable
    input             dm_wen_in,    // Data memory write enable (1 = write, 0 = read)
    input      [3:0]  dm_be_in,     // Byte enables for writing (1 bit per byte)
    input      [31:0] dm_addr_in,   // 32-bit memory address from LSU
    input      [31:0] dm_wdata_in,  // 32-bit data to write
    output reg [31:0] dm_rdata_out  // 32-bit data read from memory
);

    // ========================================================================
    // Memory Array Definition
    // ========================================================================
    // 64 KB data memory, word-addressed (16,384 words x 32 bits)
    reg [31:0] memory [0:16383];

    // ========================================================================
    // Address Translation
    // ========================================================================
    // Subtract the base address and shift right by 2 to convert the byte 
    // address into a 14-bit word index for the memory array.
    wire [13:0] word_addr;
    assign word_addr = (dm_addr_in - DMEM_BASE) >> 2;

    // ========================================================================
    // Memory Initialization
    // ========================================================================
    initial begin
        // Load initial data memory contents from file
        $readmemh("data.mem", memory);
    end

    // ========================================================================
    // Synchronous Read/Write Logic
    // ========================================================================
    always @(posedge clk_in) begin
        // Handle memory writes when requested and write enable is high
        if (dm_req_in && dm_wen_in) begin
            // Byte-enable masking ensures only targeted bytes are updated
            if (dm_be_in[0]) memory[word_addr][7:0]   <= dm_wdata_in[7:0];
            if (dm_be_in[1]) memory[word_addr][15:8]  <= dm_wdata_in[15:8];
            if (dm_be_in[2]) memory[word_addr][23:16] <= dm_wdata_in[23:16];
            if (dm_be_in[3]) memory[word_addr][31:24] <= dm_wdata_in[31:24];
        end
        
        // Output the data at the current word address (Read operation)
        // Note: Read data updates every clock cycle based on the current address
        dm_rdata_out <= memory[word_addr];
    end

endmodule
