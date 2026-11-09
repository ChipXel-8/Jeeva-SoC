`timescale 1ns / 1ps

module pragya_imm_adder(
    input  [31:0] pc_in,        // from pc
    input  [31:0] rs_1_in,      // from reg file
    input  [31:0] imm_in,       // from imm gen
    input         i_adder_src_in, // from decoder
    output [31:0] i_adder_out,     // to pc
    input         jalr_in
    );

    wire [31:0] i_adder_mux_out;



wire [31:0] sum;

assign i_adder_mux_out = i_adder_src_in ? rs_1_in : pc_in;
assign sum             = i_adder_mux_out + imm_in;
assign i_adder_out =
        jalr_in ? (sum & 32'hFFFFFFFE) : sum;

always @(*) begin
    if (i_adder_src_in) begin
        $display("IMM_ADDER: rs1=%h imm=%h target=%h",
                 rs_1_in, imm_in, i_adder_out);
    end
end
endmodule
