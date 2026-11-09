`timescale 1ns / 1ps


module pragya_wb_mux (  
        input   [31:0]      alu_result_in,      // from alu 
        input   [31:0]      load_data_in,       // from load unit
        input   [31:0]      pc_plus4_in,        // next pc addr for jal /jalr
        input   [31:0]      imm_in,             // from immediate generator for lui 
        input   [31:0]      i_adder_in,          //  from immediate addr for auipc; (pc+ upper imm)
        input   [31:0]      mdu_result_in,      // from mdu unit
        input   [31:0]      csr_data_in,        //from csr
        input   [2:0]       wb_mux_sel_in,      // from decoder
        output  [31:0]      wb_mux_out


);



        reg [31:0]     wb_out;

        always @ (*) begin

                case ( wb_mux_sel_in)
                    3'b000:             wb_out  =   alu_result_in;
                    3'b001:             wb_out  =   load_data_in;
                    3'b010:             wb_out  =   pc_plus4_in;
                    3'b011:             wb_out  =   imm_in;
                    3'b100:             wb_out  =   i_adder_in;
                    3'b101:             wb_out  =   mdu_result_in;
                    3'b110:             wb_out  =   csr_data_in;
                    default:            wb_out  =   32'b0;

                endcase
        end

        assign wb_mux_out   =   wb_out;
endmodule
