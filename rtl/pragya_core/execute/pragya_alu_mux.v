`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/01/2026 04:30:51 PM
// Design Name:
// Module Name: pragya_alu_mux
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module pragya_alu_mux ( input   [31:0]     rs_2_in,           // from register file
                        input   [31:0]     imm_in,           // from immediate generator
                        input              alu_src_in,       // from decoder
                        output  [31:0]     op_2_out          // operand 2 connected to alu


);

assign op_2_out     =       alu_src_in ? imm_in  :  rs_2_in;

endmodule
