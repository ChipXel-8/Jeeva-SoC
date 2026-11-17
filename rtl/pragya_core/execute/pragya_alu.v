`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_alu
// Author     : chipXel team
// Description: Arithmetic Logic Unit (ALU) for the pragya processor.
//              Executes arithmetic, logical, shift, and comparison operations
//              based on the 4-bit alu_control signal.
// ============================================================================

module pragya_alu(
    input [31:0] rs_1_in,           // First source operand
    input [31:0] rs_2_in,           // Second source operand
    input [3:0]  alu_control,       // 4-bit control signal to select operation
    output reg [31:0] alu_result_out// 32-bit computed result
    );

    // ========================================================================
    // Logical Operations
    // ========================================================================
    wire [31:0] and_out = rs_1_in & rs_2_in;                                        // Bitwise AND
    wire [31:0] or_out  = rs_1_in | rs_2_in;                                        // Bitwise OR
    wire [31:0] xor_out = rs_1_in ^ rs_2_in;                                        // Bitwise XOR

    // ========================================================================
    // Shift Operations
    // ========================================================================
    wire [31:0] sll_out = rs_1_in << rs_2_in[4:0];                                  // Shift Left Logical
    wire [31:0] srl_out = rs_1_in >> rs_2_in[4:0];                                  // Shift Right Logical
    wire [31:0] sra_out = $signed(rs_1_in) >>> rs_2_in[4:0];                        // Shift Right Arithmetic

    // ========================================================================
    // Comparison Operations
    // ========================================================================
    wire [31:0] slt_out  = {{(31){1'b0}}, ($signed(rs_1_in) < $signed(rs_2_in))};   // Set Less Than (Signed)
    wire [31:0] sltu_out = {{(31){1'b0}}, (rs_1_in < rs_2_in)};                     // Set Less Than (Unsigned)

    // ========================================================================
    // Arithmetic Operations (ADD / SUB)
    // ========================================================================
    reg [32:0]  addsub_full;  // WIDTH+1 to capture carry                    // ADD/SUB full result
    reg [31:0]  addsub_out;   // 32-bit truncated result
    
    // Add/Sub selection logic based on control signal (4'd1 = SUB)
    always @(*) begin
        if (alu_control == 4'd1)
            addsub_full = rs_1_in + ~rs_2_in +  1'b1; // 2's complement subtraction
        else
            addsub_full = rs_1_in + rs_2_in;          // Normal addition

        addsub_out = addsub_full[31:0];
      //  carry      = addsub_full[32]; // Carry extraction (currently commented out)
    end   
  
    // ========================================================================
    // ALU Result Multiplexer
    // ========================================================================
    always @(*) begin
        case (alu_control)
            4'd0: alu_result_out = addsub_full; // ADD
            4'd1: alu_result_out = addsub_full; // SUB
            4'd2: alu_result_out = and_out;     // AND
            4'd3: alu_result_out = or_out;      // OR
            4'd4: alu_result_out = xor_out;     // XOR
            4'd5: alu_result_out = sll_out;     // SLL
            4'd6: alu_result_out = srl_out;     // SRL
            4'd7: alu_result_out = sra_out;     // SRA
            4'd8: alu_result_out = slt_out;     // SLT
            4'd9: alu_result_out = sltu_out;    // SLTU
            default: alu_result_out = {32{1'b0}}; // Default case (zero out)
        endcase
    end
endmodule




