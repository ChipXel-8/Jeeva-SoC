`timescale 1ns / 1ps

module pragya_decoder (

    input  [31:0]  instr_in,  // from memory
    output [4:0]   rs_1_addrs_out  , // to reg file
    output [4:0]   rs_2_addrs_out  , // to reg file
    output [4:0]   rd_addrs_out  , // to reg file
    output [24:0]  instr_out, // to imme gen
    output [2:0]   funct3_out, // to machine control, to lsu, to branch 
    output [6:0]   funct7_out, // to machine control
    output [6:0]   opcode_out,
    output [2:0]   mdu_op_out, // to mdu
    output [3:0]   alu_control_out, // to alu
    output         reg_write_out, // to reg file
    output [2:0]   imm_src_out, //to imm gen
    output         alu_src_out, // to alu
    output         mem_write_out, // to lsu
    output         mem_req_out, // to lsu
    output [2:0]   wb_mux_sel_out, // to wb_mux
    output         i_adder_src_out,  // to imm adder
    output         jalr_out,
    output [6:2]        opcode6_to_2_out, // machine control
    output [11:0]  csr_addr_out, // to csr
    output         csr_wr_en_out, // to csr
    output [2:0]   csr_op_out,    // to csr
    output         illegal_instr_out // to machine control
          );
          
    reg is_op;
    reg is_mul;
    reg is_op_imm;
    reg is_load;
    reg is_store;
    reg is_branch;
    reg is_jal;
    reg is_jalr;
    reg is_lui;
    reg is_auipc;
    reg is_system;
    reg [2:0] wb_mux_sel;
    reg [2:0] MDUOp;
    reg [3:0] ALUControl;
    wire is_csr;

            assign rs_1_addrs_out      =       instr_in [19:15];
            assign rs_2_addrs_out      =       instr_in [24:20];
            assign rd_addrs_out        =       instr_in [11:7];
            assign instr_out           =       instr_in [31:7];
            assign csr_addr_out        =       instr_in [31:20];
            assign funct3_out          =       instr_in [14:12];
            assign funct7_out          =       instr_in [31:25];
            assign opcode_out          =       instr_in [6:0];
            assign opcode6_to_2_out    =       instr_in [6:2];

    always @ (*) begin
                                        is_op       =   1'b0;
                                        is_mul      =   1'b0;
                                        is_op_imm   =   1'b0;  
                                        is_load     =   1'b0;
                                        is_store    =   1'b0;
                                        is_branch   =   1'b0;
                                        is_jal      =   1'b0;
                                        is_jalr     =   1'b0;
                                        is_lui      =   1'b0;
                                        is_auipc    =   1'b0;
                                        is_system   =   1'b0;    
                                           
    case (opcode_out[6:2])

                    5'b011_00:      if(funct7_out == 7'b0000001)
                                         is_mul      =   1'b1;
                                    else
                                         is_op       =   1'b1;  
                    5'b001_00:                      is_op_imm   =   1'b1; 
                    5'b000_00:                      is_load     =   1'b1;
                    5'b010_00:                      is_store    =   1'b1;
                    5'b110_00:                      is_branch   =   1'b1;
                    5'b110_11:                      is_jal      =   1'b1;
                    5'b110_01:                      is_jalr     =   1'b1;
                    5'b011_01:                      is_lui      =   1'b1;
                    5'b001_01:                      is_auipc    =   1'b1;
                    5'b111_00:                      is_system   =   1'b1;   

    endcase
end



assign  reg_write_out    =      is_op | is_op_imm | is_load | is_jal | is_jalr | is_lui | is_auipc | is_csr|is_mul;  

assign  imm_src_out [0]  =      is_op_imm|is_load|is_jalr|is_branch|is_jal;
assign  imm_src_out [1]  =     is_store|is_branch;
assign  imm_src_out [2]  =     is_lui|is_auipc|is_jal;

assign mem_req_out       =      is_load | is_store;
assign mem_write_out     =       is_store;


assign alu_src_out = (is_op | is_branch) ? 1'b0 : 1'b1;   // IMM vs RS2

//assign wb_mux_sel_out [0]  =    is_load | is_mul;
//assign wb_mux_sel_out [1]  =    is_jal | is_jalr | is_csr ;
//assign wb_mux_sel_out [2]  =    is_auipc  | is_csr | is_mul;
always @(*) begin

    if (is_load)
        wb_mux_sel = 3'b001;

    else if (is_jal | is_jalr)
        wb_mux_sel = 3'b010;

    else if (is_lui)
        wb_mux_sel = 3'b011;

    else if (is_auipc)
        wb_mux_sel = 3'b100;

    else if (is_mul)
        wb_mux_sel = 3'b101;

    else if (is_csr)
        wb_mux_sel = 3'b110;

    else
        wb_mux_sel = 3'b000;     // ALU
end

assign wb_mux_sel_out = wb_mux_sel;
    
assign i_adder_src_out = (is_load | is_store | is_jalr) ? 1'b1 : 1'b0;
assign is_csr          = is_system & (|funct3_out);

assign csr_wr_en_out   = is_csr;
assign csr_op_out      = funct3_out;

assign illegal_instr_out = ~(
    is_op | is_op_imm | is_load | is_store |
    is_branch | is_jal | is_jalr |
    is_lui | is_auipc | is_system | is_mul
);

   
always @(*) begin
    if (is_mul) begin
        case (funct3_out)
            3'b000: MDUOp = 3'b000; // MUL
            3'b001: MDUOp = 3'b001; // MULH
            3'b010: MDUOp = 3'b010; // MULHSU
            3'b011: MDUOp = 3'b011; // MULHU
            3'b100: MDUOp = 3'b100; // DIV
            3'b101: MDUOp = 3'b101; // DIVU
            3'b110: MDUOp = 3'b110; // REM
            3'b111: MDUOp = 3'b111; // REMU
            default: MDUOp = 3'b000;
        endcase
    end
    else begin
        MDUOp = 3'b000;
    end
end
  
  
    always @(*)begin
        if (is_load | is_store | is_jalr | is_auipc)
                ALUControl = 4'b0000; // ADD

        else if(is_branch)
                ALUControl = 4'b0001; // SUB / compare

        else if (is_op | is_op_imm) begin
                case (funct3_out)
                    3'b000: begin
                        if (opcode_out[5] && funct7_out[5])
                            ALUControl = 4'b0001; // SUB
                        else
                            ALUControl = 4'b0000; // ADD / ADDI
                    end
                    3'b111: ALUControl = 4'b0010; // AND / ANDI
                    3'b110: ALUControl = 4'b0011; // OR / ORI
                    3'b100: ALUControl = 4'b0100; // XOR / XORI
                    3'b001: ALUControl = 4'b0101; // SLL / SLLI
                    3'b010: ALUControl = 4'b1000; // SLT / SLTI
                    3'b011: ALUControl = 4'b1001; // SLTU/ SLTUI
                    3'b101: 
                    begin
                        if (funct7_out[5])
                            ALUControl = 4'b0111; // SRA / SRAI
                        else
                            ALUControl = 4'b0110; // SRL / SRLI
                    end
                    default: ALUControl = 4'b0000;
                endcase
    end
    else
                ALUControl  =   4'b0000;

  end
      
    assign  mdu_op_out       =   MDUOp;
    assign  alu_control_out  =   ALUControl;
    assign  jalr_out         =   is_jalr;

endmodule
