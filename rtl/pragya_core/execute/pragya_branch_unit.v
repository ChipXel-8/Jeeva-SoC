`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_branch_unit
// Author     : chipXel team
// Description: Branch evaluation unit for the pragya processor.
//              Evaluates branch conditions and unconditional jumps (JAL, JALR) 
//              based on the opcode, funct3, and register values to determine 
//              if a branch should be taken.
// ============================================================================

module pragya_branch_unit(  
        input [31:0]    rs_1_in,         // Source register 1 data from register file
        input [31:0]    rs_2_in,         // Source register 2 data from register file
        input [4:0]     opcode6_to_2_in, // Opcode bits [6:2] from decoder
        input [2:0]     funct3_in,       // Funct3 bits from decoder
        output          branch_taken_out // Branch taken decision signal routed to PC unit

        );

        // ====================================================================
        // Internal condition flags
        // ====================================================================
        wire     b_eq;  // Branch if Equal
        wire     b_neq; // Branch if Not Equal
        wire     b_lt;  // Branch if Less Than (Signed)
        wire     b_ge;  // Branch if Greater than or Equal (Signed)
        wire     b_ltu; // Branch if Less Than (Unsigned)
        wire     b_geu; // Branch if Greater than or Equal (Unsigned)
        reg      taken; // Internal register to hold the taken decision

        // ====================================================================
        // Condition Evaluation Logic
        // ====================================================================
        assign b_eq     =     (rs_1_in ==  rs_2_in);
        assign b_neq    =     (rs_1_in !=  rs_2_in);
        assign b_lt     =     (($signed(rs_1_in)) < ($signed(rs_2_in)));
        assign b_ge     =     (($signed(rs_1_in)) >=  ($signed(rs_2_in)));
        assign b_ltu    =     (($unsigned(rs_1_in)) < ($unsigned(rs_2_in)));
        assign b_geu    =     (($unsigned(rs_1_in)) >= ($unsigned(rs_2_in)));

        // ====================================================================
        // Branch/Jump Decision MUX
        // ====================================================================
        always @(*) begin
                case (opcode6_to_2_in)
                        // BRANCH instructions opcode (B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU)
                        5'b11000: begin
                                case(funct3_in)
                                        3'b000: // BEQ
                                                taken = b_eq;
                                        3'b001: // BNE
                                                taken = b_neq;
                                        3'b100: // BLT
                                                taken = b_lt ;
                                        3'b101: // BGE
                                                taken = b_ge;
                                        3'b110: // BLTU
                                                taken = b_ltu;    
                                        3'b111: // BGEU
                                                taken = b_geu;

                                        default:
                                                taken =1'b0;        
                                endcase
                        end
    
                        // JAL instruction opcode (J-type) - Unconditional Jump
                        5'b11011 :
                                                taken   =   1'b1;
                        
                        // JALR instruction opcode (I-type) - Unconditional Jump Register
                        5'b11001:
                                                taken   =   1'b1;

                        // Default case for non-branching instructions
                        default:
                                                taken   =   1'b0;

                endcase
        end

 // Assign the internally resolved decision to the output port
 assign branch_taken_out = taken ;

endmodule
