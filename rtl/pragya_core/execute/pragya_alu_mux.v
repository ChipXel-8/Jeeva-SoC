`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_alu_mux
// Author     : chipXel team
// Description: ALU Multiplexer for the pragya processor.
//              Selects the second operand for the ALU between the register 
//              file output (rs_2_in) and the sign-extended immediate value 
//              (imm_in) based on the alu_src_in control signal.
// ============================================================================

module pragya_alu_mux ( 
    input   [31:0]     rs_2_in,          // Operand from register file (rs2)
    input   [31:0]     imm_in,           // Sign-extended immediate from immediate generator
    input              alu_src_in,       // Control signal from decoder (0: rs2, 1: imm)
    output  [31:0]     op_2_out          // Selected operand 2 routed to the ALU 
);

    // ========================================================================
    // Operand 2 Selection Logic
    // ========================================================================
    // If alu_src_in is HIGH (1), the immediate value is passed to the ALU.
    // If alu_src_in is LOW (0), the register file data (rs_2_in) is passed.
    assign op_2_out = alu_src_in ? imm_in : rs_2_in;

endmodule
