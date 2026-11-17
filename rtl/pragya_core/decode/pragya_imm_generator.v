`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_imm_generator
// Author     : chipXel team
// Description: Immediate Generator for the pragya RISC-V processor.
//              Extracts and sign-extends immediate values from the 
//              instruction payload (bits [31:7]) based on the instruction 
//              format (I-type, S-type, B-type, U-type, J-type) indicated 
//              by the imm_src control signal.
// ============================================================================

module pragya_imm_generator (
    input  [31:7] imm_gen_in, // Instruction payload from decoder
    input  [2:0]  imm_src,    // Immediate format selector from decoder
    output [31:0] imm_out     // 32-bit sign-extended immediate output (to adder/pipeline)
);
 
    // ========================================================================
    // Internal Signals for Immediate Types
    // ========================================================================
    wire [31:0] i_type; // I-type immediate (Loads, ALU immediate, JALR)
    wire [31:0] s_type; // S-type immediate (Stores)
    wire [31:0] b_type; // B-type immediate (Branches)
    wire [31:0] u_type; // U-type immediate (LUI, AUIPC)
    wire [31:0] j_type; // J-type immediate (JAL)
    
    reg  [31:0] imm;    // Selected immediate value

    // ========================================================================
    // Immediate Extraction and Sign-Extension
    // ========================================================================
    
    // I-type: 12-bit immediate [31:20], sign-extended to 32 bits
    assign i_type = {{20{imm_gen_in[31]}}, imm_gen_in[31:20]};
    
    // S-type: 12-bit immediate split across [31:25] and [11:7], sign-extended
    assign s_type = {{20{imm_gen_in[31]}}, imm_gen_in[31:25], imm_gen_in[11:7]};
    
    // B-type: 13-bit immediate (even multiples of 2), split and sign-extended
    assign b_type = {{20{imm_gen_in[31]}}, imm_gen_in[7], imm_gen_in[30:25], imm_gen_in[11:8], 1'b0};
    
    // U-type: 20-bit immediate [31:12], padded with 12 zeros at the LSB
    assign u_type = {imm_gen_in[31:12], 12'b0};
    
    // J-type: 21-bit immediate (even multiples of 2), split and sign-extended
    assign j_type = {{12{imm_gen_in[31]}}, imm_gen_in[19:12], imm_gen_in[20], imm_gen_in[30:21], 1'b0};

    // ========================================================================
    // Immediate Selection Multiplexer
    // ========================================================================
    always @(*) begin
        case(imm_src)
            3'b000:  imm = i_type; // I-type (ALU/JALR/Load)
            3'b001:  imm = i_type; // I-type (Alternative mapping/Default)
            3'b010:  imm = s_type; // S-type (Store)
            3'b011:  imm = b_type; // B-type (Branch)
            3'b100:  imm = u_type; // U-type (LUI/AUIPC)
            3'b101:  imm = j_type; // J-type (JAL)
            default: imm = i_type; // Default fallback
        endcase
    end

    // Assign the selected immediate to the output port
    assign imm_out = imm;
       
endmodule
