`timescale 1ns / 1ps

module pragya_branch_unit(
        input [31:0]    rs_1_in, // from register file
        input [31:0]    rs_2_in, // from register file
        input [4:0]     opcode6_to_2_in, // from decoder
        input [2:0]     funct3_in, // from decoder
        output          branch_taken_out // to pc

        );

        wire     b_eq;
        wire     b_neq;
        wire     b_lt;
        wire     b_ge;
        wire     b_ltu;
        wire     b_geu;
        reg      taken;

        assign b_eq     =     (rs_1_in ==  rs_2_in);
        assign b_neq    =     (rs_1_in !=  rs_2_in);
        assign b_lt     =     (($signed(rs_1_in)) < ($signed(rs_2_in)));
        assign b_ge     =     (($signed(rs_1_in)) >=  ($signed(rs_2_in)));
        assign b_ltu    =     (($unsigned(rs_1_in)) < ($unsigned(rs_2_in)));
        assign b_geu    =     (($unsigned(rs_1_in)) >= ($unsigned(rs_2_in)));


        always @(*) begin
                case (opcode6_to_2_in)
                        5'b11000: begin
                                case(funct3_in)
                                        3'b000:
                                                taken = b_eq;
                                        3'b001:
                                                taken = b_neq;
                                        3'b100:
                                                taken = b_lt ;
                                        3'b101:
                                                taken = b_ge;
                                        3'b110:
                                                taken = b_ltu;
                                        3'b111:
                                                taken = b_geu;

                                        default:
                                                taken =1'b0;
                                endcase
                        end

                        5'b11011 :
                                                taken   =   1'b1;
                        5'b11001:
                                                taken   =   1'b1;

                        default:
                                                taken   =   1'b0;




                endcase
        end

 assign branch_taken_out = taken ;

endmodule
