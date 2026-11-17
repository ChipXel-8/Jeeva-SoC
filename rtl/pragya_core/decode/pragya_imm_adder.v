`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_imm_adder
// Author     : chipXel team
// Description: Immediate Adder Unit for the pragya processor.
//              Computes target addresses for branches, jumps (JAL/JALR), 
//              and memory operations (Load/Store) by adding the generated 
//              immediate to either the Program Counter (PC) or a base register.
//              Enforces address alignment specifically for JALR instructions.
// ============================================================================

module pragya_imm_adder (
    input  [31:0] pc_in,          // Current Program Counter (from PC unit)
    input  [31:0] rs_1_in,        // Source Register 1 data (from Register File)
    input  [31:0] imm_in,         // Sign-extended immediate (from Immediate Generator)
    input         i_adder_src_in, // Base address selector (0: PC, 1: rs1) (from Decoder)
    input         jalr_in,        // JALR instruction flag (from Decoder)
    output [31:0] i_adder_out     // Computed target address (to PC unit / LSU)
);

    // ========================================================================
    // Internal Signals
    // ========================================================================
    wire [31:0] i_adder_mux_out;  // Selected base address for the addition
    wire [31:0] sum;              // Raw computed sum

    // ========================================================================
    // Base Address Selection
    // ========================================================================
    // If i_adder_src_in is HIGH (1), select rs_1_in as the base (used for Loads, Stores, JALR).
    // If i_adder_src_in is LOW (0), select PC as the base (used for Branches, JAL, AUIPC).
    assign i_adder_mux_out = i_adder_src_in ? rs_1_in : pc_in;

    // ========================================================================
    // Address Computation
    // ========================================================================
    // Add the sign-extended immediate to the selected base address.
    assign sum = i_adder_mux_out + imm_in;

    // ========================================================================
    // JALR Alignment Correction
    // ========================================================================
    // The RISC-V specification dictates that for the JALR instruction, the 
    // least significant bit (LSB) of the calculated target address must be 
    // cleared (set to 0). For all other operations, the raw sum is used.
    assign i_adder_out = jalr_in ? (sum & 32'hFFFFFFFE) : sum;

endmodule
