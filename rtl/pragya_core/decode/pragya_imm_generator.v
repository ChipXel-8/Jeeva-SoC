`timescale 1ns / 1ps

module pragya_imm_generator(
       input  [31:7] imm_gen_in, // from decoder
       input  [2:0]  imm_src, // from decoder
       output [31:0] imm_out  // to immediate adder. to pipeline2
       );

       wire [31:0]i_type;
       wire [31:0]s_type;
       wire [31:0]b_type;
       wire [31:0]u_type;
       wire [31:0]j_type;
       reg  [31:0]imm;


       assign i_type={{20{imm_gen_in[31]}},imm_gen_in[31:20]};
       assign s_type={{20{imm_gen_in[31]}},imm_gen_in[31:25], imm_gen_in[11:7]};
       assign b_type={{20{imm_gen_in[31]}},imm_gen_in[7],imm_gen_in[30:25], imm_gen_in[11:8],1'b0};
       assign u_type={imm_gen_in[31:12],12'b0};
       assign j_type={{12{imm_gen_in[31]}},imm_gen_in[19:12], imm_gen_in[20], imm_gen_in[30:21], 1'b0};



       always @(*) begin
              case(imm_src)
                     3'b000: imm=i_type;
                     3'b001: imm=i_type;
                     3'b010: imm=s_type;
                     3'b011: imm=b_type;
                     3'b100: imm=u_type;
                     3'b101: imm=j_type;
                     default: imm=i_type;

              endcase
       end

	assign imm_out = imm;

endmodule
