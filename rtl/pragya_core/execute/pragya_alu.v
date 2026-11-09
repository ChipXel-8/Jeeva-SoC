`timescale 1ns / 1ps

module pragya_alu(
    input [31:0] rs_1_in,
    input [31:0] rs_2_in,
    input [3:0] alu_control,
    output reg [31:0] alu_result_out
    );


    wire [31:0] and_out = rs_1_in & rs_2_in;                                        // logic
    wire [31:0] or_out  = rs_1_in | rs_2_in;
    wire [31:0] xor_out = rs_1_in ^ rs_2_in;
    wire [31:0] sll_out = rs_1_in << rs_2_in[4:0];                                  // SHIFTER
    wire [31:0] srl_out = rs_1_in >> rs_2_in[4:0];
    wire [31:0] sra_out = $signed(rs_1_in) >>> rs_2_in[4:0];
    wire [31:0] slt_out  = {{(31){1'b0}}, ($signed(rs_1_in) < $signed(rs_2_in))};    // COMPARATOR
    wire [31:0] sltu_out = {{(31){1'b0}}, (rs_1_in < rs_2_in)};
    reg [32:0]  addsub_full;  // WIDTH+1 to capture carry                   // ADD/SUB
    reg [31:0]  addsub_out;

    always @(*) begin
        if (alu_control == 4'd1)
            addsub_full = rs_1_in + ~rs_2_in +  1'b1;
        else
            addsub_full = rs_1_in + rs_2_in;

        addsub_out = addsub_full[31:0];
      //  carry      = addsub_full[32];
    end


    always @(*) begin
        case (alu_control)
            4'd0: alu_result_out = addsub_full;
            4'd1: alu_result_out = addsub_full;
            4'd2: alu_result_out = and_out;
            4'd3: alu_result_out = or_out;
            4'd4: alu_result_out = xor_out;
            4'd5: alu_result_out = sll_out;
            4'd6: alu_result_out = srl_out;
            4'd7: alu_result_out = sra_out;
            4'd8: alu_result_out = slt_out;
            4'd9: alu_result_out = sltu_out;
            default: alu_result_out = {32{1'b0}};
        endcase
    end
endmodule
