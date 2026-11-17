`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_lsu
// Author     : chipXel team
// Description: Load Store Unit (LSU) for the pragya RISC-V processor.
//              Handles generation of memory requests (read/write), aligns
//              and formats store data with appropriate byte enables, and
//              extracts/sign-extends read data from memory based on the 
//              target address alignment and instruction type (LB, LH, LW, etc.).
// ============================================================================

module pragya_lsu (
    input wire         clk_in,                   // System clock
    input wire         rst_in,                   // System reset (active high)
    
    // ========================================================
    // Inputs from Decode/Execute Stage
    // ========================================================
    input wire         mem_req_in,               // Memory operation request active
    input wire         mem_write_in,             // 1 = Write (Store), 0 = Read (Load)
    input wire [2:0]   funct3_in,                // Data width and sign extension selector
    input wire [31:0]  i_adder_in,               // Target memory address
    input wire [31:0]  rs_2_in,                  // Data to be stored

    // ========================================================
    // Inputs from Memory / OBI Interface
    // ========================================================
    input wire         dm_rvalid_in,             // Data memory response valid
    input wire [31:0]  dm_rdata_in,              // Raw data read from memory

    // ========================================================
    // Outputs to Memory / OBI Interface
    // ========================================================
    output wire        pg_riscv32_mp_dmreq_out,  // Data memory request
    output wire        pg_riscv32_mp_dmwen_out,  // Data memory write enable
    output wire [3:0]  pg_riscv32_mp_dmbe_out,   // Data memory byte enable mask
    output wire [31:0] pg_riscv32_mp_dmaddr_out, // Word-aligned data memory address
    output wire [31:0] pg_riscv32_mp_dmdata_out, // Formatted and aligned store data

    // ========================================================
    // Output to Writeback Stage
    // ========================================================
    output reg [31:0]  load_data_out             // Formatted load data held for WB cycle
);

    // =========================================================================
    // 1. Combinational Memory Request (Cycle 1 - MEM Stage)
    // =========================================================================
    
    // Forward memory request and write enable signals directly
    assign pg_riscv32_mp_dmreq_out  = mem_req_in;
    assign pg_riscv32_mp_dmwen_out  = mem_req_in && mem_write_in;
    
    // Ensure memory address is strictly word-aligned by masking out the bottom 2 bits
    assign pg_riscv32_mp_dmaddr_out = {i_adder_in[31:2], 2'b00};

    // Variables for formatting Store Data and Byte Enables
    reg [31:0] store_data;
    reg [3:0]  be;

    // Data Alignment and Byte Enable Generation
    always @(*) begin
        store_data = 32'b0;
        be         = 4'b0000;
        
        case (funct3_in)
            // Store Byte (SB)
            3'b000: begin
                // Shift the byte to the correct position based on the address offset
                case (i_adder_in[1:0])
                    2'b00: begin store_data = {24'b0, rs_2_in[7:0]};        be = 4'b0001; end
                    2'b01: begin store_data = {16'b0, rs_2_in[7:0], 8'b0};  be = 4'b0010; end
                    2'b10: begin store_data = {8'b0, rs_2_in[7:0], 16'b0};  be = 4'b0100; end
                    2'b11: begin store_data = {rs_2_in[7:0], 24'b0};        be = 4'b1000; end
                endcase
            end
            
            // Store Halfword (SH)
            3'b001: begin
                // Align to upper or lower halfword based on address bit 1
                if (i_adder_in[1]) begin
                    store_data = {rs_2_in[15:0], 16'b0}; be = 4'b1100;
                end else begin
                    store_data = {16'b0, rs_2_in[15:0]}; be = 4'b0011;
                end
            end
            
            // Store Word (SW)
            3'b010: begin
                store_data = rs_2_in; be = 4'b1111;
            end
            
            // Default Case (Prevent latches)
            default: begin
                store_data = 32'b0; be = 4'b0000;
            end
        endcase

        // Ensure byte enables are zeroed out if it's not a write operation
        if (!mem_write_in) be = 4'b0000;
    end

    // Output assignments for Store operation
    assign pg_riscv32_mp_dmdata_out = (mem_write_in) ? store_data : 32'b0;
    assign pg_riscv32_mp_dmbe_out   = be;

    // =========================================================================
    // 2. Combinational Load Data Formatting (Read)
    // =========================================================================
    // Combinational formatting prevents a 1-cycle penalty compared to registering
    // the control signals. Extract the target byte/halfword directly from the 
    // raw 32-bit response.
    
    wire [1:0]  addr_offset  = i_adder_in[1:0];
    
    // Shift the requested data to the least significant byte position
    wire [31:0] shifted_data = dm_rdata_in >> (8 * addr_offset);
    wire [7:0]  byte_data    = shifted_data[7:0];
    wire [15:0] half_data    = shifted_data[15:0];

    reg [31:0] formatted_load_data;
    
    // Sign extension or zero extension based on load type (LB, LH, LW, LBU, LHU)
    always @(*) begin
        case (funct3_in)
            3'b000: formatted_load_data = {{24{byte_data[7]}}, byte_data};   // LB  (Sign Extend)
            3'b001: formatted_load_data = {{16{half_data[15]}}, half_data};  // LH  (Sign Extend)
            3'b010: formatted_load_data = dm_rdata_in;                       // LW  (Full Word)
            3'b100: formatted_load_data = {24'b0, byte_data};                // LBU (Zero Extend)
            3'b101: formatted_load_data = {16'b0, half_data};                // LHU (Zero Extend)
            default: formatted_load_data = 32'b0;
        endcase
    end

    // =========================================================================
    // 3. Pipeline Register to Writeback Stage
    // =========================================================================
    // Captures the successfully formatted data when the memory interface
    // signals that the response is valid. This holds the data steady 
    // for the register file write in the next cycle.
    
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in)
            load_data_out <= 0;
        else if (dm_rvalid_in)
            load_data_out <= formatted_load_data;
    end

endmodule
