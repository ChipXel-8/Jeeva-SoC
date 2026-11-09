/*`timescale 1ns / 1ps

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
    wire system_legal;
    wire csr_addr_valid;
    wire op_legal;
    wire op_imm_legal;
    wire load_legal;
    wire store_legal;
    wire branch_legal;
    wire jalr_legal;
    wire csr_op_legal;


            assign rs_1_addrs_out      =       instr_in [19:15];
            assign rs_2_addrs_out      =       instr_in [24:20];
            assign rd_addrs_out        =       instr_in [11:7];
            assign instr_out           =       instr_in [31:7];
            assign csr_addr_out        =       instr_in [31:20];
            assign funct3_out          =       instr_in [14:12];
            assign funct7_out          =       instr_in [31:25];
            assign opcode_out          =       instr_in [6:0];
            assign opcode6_to_2_out    =       instr_in [6:2];
            assign csr_addr_valid =
       (csr_addr_out == 12'hC00) ||
       (csr_addr_out == 12'hC02) ||
       (csr_addr_out == 12'hC80) ||
       (csr_addr_out == 12'hC82) ||

       (csr_addr_out == 12'h300) ||
       (csr_addr_out == 12'h301) ||
       (csr_addr_out == 12'h304) ||
       (csr_addr_out == 12'h305) ||

       (csr_addr_out == 12'h340) ||
       (csr_addr_out == 12'h341) ||
       (csr_addr_out == 12'h342) ||
       (csr_addr_out == 12'h343) ||
       (csr_addr_out == 12'h344) ||

       (csr_addr_out == 12'hB00) ||
       (csr_addr_out == 12'hB02) ||
       (csr_addr_out == 12'hB80) ||
       (csr_addr_out == 12'hB82) ||
       (csr_addr_out == 12'h3c0) ||
       (csr_addr_out == 12'hF11) ||
       (csr_addr_out == 12'hF12) ||
       (csr_addr_out == 12'hF13) ||
       (csr_addr_out == 12'hF14);
       assign system_legal =
       (instr_in == 32'h00000073) ||  // ECALL
       (instr_in == 32'h00100073) ||  // EBREAK
       (instr_in == 32'h30200073);    // MRET
assign op_imm_legal =
       // ADDI
       (funct3_out == 3'b000) ||

       // SLTI
       (funct3_out == 3'b010) ||

       // SLTIU
       (funct3_out == 3'b011) ||

       // XORI
       (funct3_out == 3'b100) ||

       // ORI
       (funct3_out == 3'b110) ||

       // ANDI
       (funct3_out == 3'b111) ||

       // SLLI
       ((funct3_out == 3'b001) &&
        (funct7_out == 7'b0000000)) ||

       // SRLI / SRAI
       ((funct3_out == 3'b101) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000)));

assign op_legal =
       ((funct3_out == 3'b000) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000))) ||

       ((funct3_out == 3'b001) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b010) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b011) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b100) && (funct7_out == 7'b0000000)) ||

       ((funct3_out == 3'b101) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000))) ||

       ((funct3_out == 3'b110) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b111) && (funct7_out == 7'b0000000));

assign load_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010) ||
       (funct3_out == 3'b100) ||
       (funct3_out == 3'b101);

assign store_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010);

assign branch_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b100) ||
       (funct3_out == 3'b101) ||
       (funct3_out == 3'b110) ||
       (funct3_out == 3'b111);

assign jalr_legal =
       (funct3_out == 3'b000);

assign csr_op_legal =
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010) ||
       (funct3_out == 3'b011) ||
       (funct3_out == 3'b101) ||
       (funct3_out == 3'b110) ||
       (funct3_out == 3'b111);

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
assign is_csr          = (opcode_out == 7'b1110011) && csr_op_legal;

assign csr_wr_en_out =
        is_csr &&
        csr_addr_valid &&
        (
            (csr_op_out == 3'b001) || // CSRRW
            (csr_op_out == 3'b101) || // CSRRWI

            ((csr_op_out == 3'b010) && (rs_1_addrs_out != 5'd0)) || // CSRRS
            ((csr_op_out == 3'b011) && (rs_1_addrs_out != 5'd0)) || // CSRRC

            ((csr_op_out == 3'b110) && (rs_1_addrs_out != 5'd0)) || // CSRRSI
            ((csr_op_out == 3'b111) && (rs_1_addrs_out != 5'd0))    // CSRRCI
        );
assign csr_op_out      = funct3_out;

//assign illegal_instr_out = ~(
  //  is_op | is_op_imm | is_load | is_store |
    //is_branch | is_jal | is_jalr |
    //is_lui | is_auipc | is_system | is_mul) | (is_csr && !csr_addr_valid) | (is_system && !is_csr && !system_legal);
assign illegal_instr_out =
       ~(
          is_op      |
          is_op_imm  |
          is_load    |
          is_store   |
          is_branch  |
          is_jal     |
          is_jalr    |
          is_lui     |
          is_auipc   |
          is_system  |
          is_mul
        )
       |
       (is_op      && !op_legal)
       |
       (is_op_imm  && !op_imm_legal)
       |
       (is_load    && !load_legal)
       |
       (is_store   && !store_legal)
       |
       (is_branch  && !branch_legal)
       |
       (is_jalr    && !jalr_legal)
       |
       (is_csr     && !csr_addr_valid)
       |
       (is_system  && !is_csr && !system_legal);


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
*/



/*
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
    output         illegal_instr_out, // to machine control
    output         is_dret_out,
    output         is_mret_out,
    output         is_ecall_out,
    output         is_ebreak_out
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
    wire system_legal;
    wire csr_addr_valid;
    wire op_legal;
    wire op_imm_legal;
    wire load_legal;
    wire store_legal;
    wire branch_legal;
    wire jalr_legal;
    wire csr_op_legal;


            assign rs_1_addrs_out      =       instr_in [19:15];
            assign rs_2_addrs_out      =       instr_in [24:20];
            assign rd_addrs_out        =       instr_in [11:7];
            assign instr_out           =       instr_in [31:7];
            assign csr_addr_out        =       instr_in [31:20];
            assign funct3_out          =       instr_in [14:12];
            assign funct7_out          =       instr_in [31:25];
            assign opcode_out          =       instr_in [6:0];
            assign opcode6_to_2_out    =       instr_in [6:2];
            assign csr_addr_valid =
       (csr_addr_out == 12'hC00) ||
       (csr_addr_out == 12'hC02) ||
       (csr_addr_out == 12'hC80) ||
       (csr_addr_out == 12'hC82) ||

       (csr_addr_out == 12'h300) ||
       (csr_addr_out == 12'h301) ||
       (csr_addr_out == 12'h304) ||
       (csr_addr_out == 12'h305) ||

       (csr_addr_out == 12'h340) ||
       (csr_addr_out == 12'h341) ||
       (csr_addr_out == 12'h342) ||
       (csr_addr_out == 12'h343) ||
       (csr_addr_out == 12'h344) ||

       (csr_addr_out == 12'hB00) ||
       (csr_addr_out == 12'hB02) ||
       (csr_addr_out == 12'hB80) ||
       (csr_addr_out == 12'hB82) ||
       (csr_addr_out == 12'h3c0) ||
       (csr_addr_out == 12'hF11) ||
       (csr_addr_out == 12'hF12) ||
       (csr_addr_out == 12'hF13) ||
       (csr_addr_out == 12'hF14);
       assign system_legal =
       (instr_in == 32'h00000073) ||  // ECALL
       (instr_in == 32'h00100073) ||  // EBREAK
       (instr_in == 32'h30200073);    // MRET
assign op_imm_legal =
       // ADDI
       (funct3_out == 3'b000) ||

       // SLTI
       (funct3_out == 3'b010) ||

       // SLTIU
       (funct3_out == 3'b011) ||

       // XORI
       (funct3_out == 3'b100) ||

       // ORI
       (funct3_out == 3'b110) ||

       // ANDI
       (funct3_out == 3'b111) ||

       // SLLI
       ((funct3_out == 3'b001) &&
        (funct7_out == 7'b0000000)) ||

       // SRLI / SRAI
       ((funct3_out == 3'b101) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000)));

assign op_legal =
       ((funct3_out == 3'b000) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000))) ||

       ((funct3_out == 3'b001) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b010) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b011) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b100) && (funct7_out == 7'b0000000)) ||

       ((funct3_out == 3'b101) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000))) ||

       ((funct3_out == 3'b110) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b111) && (funct7_out == 7'b0000000));

assign load_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010) ||
       (funct3_out == 3'b100) ||
       (funct3_out == 3'b101);

assign store_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010);

assign branch_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b100) ||
       (funct3_out == 3'b101) ||
       (funct3_out == 3'b110) ||
       (funct3_out == 3'b111);

assign jalr_legal =
       (funct3_out == 3'b000);

assign csr_op_legal =
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010) ||
       (funct3_out == 3'b011) ||
       (funct3_out == 3'b101) ||
       (funct3_out == 3'b110) ||
       (funct3_out == 3'b111);

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
assign is_csr          = (opcode_out == 7'b1110011) && csr_op_legal;

assign csr_wr_en_out =
        is_csr &&
        csr_addr_valid &&
        (
            (csr_op_out == 3'b001) || // CSRRW
            (csr_op_out == 3'b101) || // CSRRWI

            ((csr_op_out == 3'b010) && (rs_1_addrs_out != 5'd0)) || // CSRRS
            ((csr_op_out == 3'b011) && (rs_1_addrs_out != 5'd0)) || // CSRRC

            ((csr_op_out == 3'b110) && (rs_1_addrs_out != 5'd0)) || // CSRRSI
            ((csr_op_out == 3'b111) && (rs_1_addrs_out != 5'd0))    // CSRRCI
        );
assign csr_op_out      = funct3_out;

//assign illegal_instr_out = ~(
  //  is_op | is_op_imm | is_load | is_store |
    //is_branch | is_jal | is_jalr |
    //is_lui | is_auipc | is_system | is_mul) | (is_csr && !csr_addr_valid) | (is_system && !is_csr && !system_legal);
assign illegal_instr_out =
       ~(
          is_op      |
          is_op_imm  |
          is_load    |
          is_store   |
          is_branch  |
          is_jal     |
          is_jalr    |
          is_lui     |
          is_auipc   |
          is_system  |
          is_mul
        )
       |
       (is_op      && !op_legal)
       |
       (is_op_imm  && !op_imm_legal)
       |
       (is_load    && !load_legal)
       |
       (is_store   && !store_legal)
       |
       (is_branch  && !branch_legal)
       |
       (is_jalr    && !jalr_legal)
       |
       (is_csr     && !csr_addr_valid)
       |
       (is_system  && !is_csr && !system_legal);


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

// =========================================================================
    // SYSTEM Instruction Decoding (Environment Calls and Returns)
    // SYSTEM opcode = 7'b1110011. funct3 = 3'b000.
    // The top 12 bits (funct12) determine the exact operation.
    // =========================================================================

    wire is_system_priv = is_system & (funct3_out == 3'b000);

    assign is_ecall_out  = is_system_priv & (csr_addr_out == 12'h000);
    assign is_ebreak_out = is_system_priv & (csr_addr_out == 12'h001);
    assign is_mret_out   = is_system_priv & (csr_addr_out == 12'h302);

    // NEW: Debug Return (Exits the Debugger Sandbox)
    assign is_dret_out   = is_system_priv & (csr_addr_out == 12'h7B2);

    // Optional: Upgrade illegal instruction check to catch invalid SYSTEM commands
    // assign illegal_instr_out = ~( ... ) | (is_system_priv & !(is_ecall_out | is_ebreak_out | is_mret_out | is_dret_out));


endmodule*/


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
    output         illegal_instr_out, // to machine control
    output         is_dret_out,
    output         is_mret_out,
    output         is_ecall_out,
    output         is_ebreak_out
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
    wire system_legal;
    wire csr_addr_valid;
    wire op_legal;
    wire op_imm_legal;
    wire load_legal;
    wire store_legal;
    wire branch_legal;
    wire jalr_legal;
    wire csr_op_legal;


            assign rs_1_addrs_out      =       instr_in [19:15];
            assign rs_2_addrs_out      =       instr_in [24:20];
            assign rd_addrs_out        =       instr_in [11:7];
            assign instr_out           =       instr_in [31:7];
            assign csr_addr_out        =       instr_in [31:20];
            assign funct3_out          =       instr_in [14:12];
            assign funct7_out          =       instr_in [31:25];
            assign opcode_out          =       instr_in [6:0];
            assign opcode6_to_2_out    =       instr_in [6:2];
            assign csr_addr_valid =
       (csr_addr_out == 12'hC00) ||
       (csr_addr_out == 12'hC02) ||
       (csr_addr_out == 12'hC80) ||
       (csr_addr_out == 12'hC82) ||

       (csr_addr_out == 12'h300) ||
       (csr_addr_out == 12'h301) ||
       (csr_addr_out == 12'h304) ||
       (csr_addr_out == 12'h305) ||

       (csr_addr_out == 12'h340) ||
       (csr_addr_out == 12'h341) ||
       (csr_addr_out == 12'h342) ||
       (csr_addr_out == 12'h343) ||
       (csr_addr_out == 12'h344) ||

       (csr_addr_out == 12'hB00) ||
       (csr_addr_out == 12'hB02) ||
       (csr_addr_out == 12'hB80) ||
       (csr_addr_out == 12'hB82) ||
       (csr_addr_out == 12'h3c0) ||
       (csr_addr_out == 12'hF11) ||
       (csr_addr_out == 12'hF12) ||
       (csr_addr_out == 12'hF13) ||
       (csr_addr_out == 12'hF14) ||
       // --- NEW DEBUG CSRs ---
       (csr_addr_out == 12'h7B0) || // dcsr
       (csr_addr_out == 12'h7B1) || // dpc
       (csr_addr_out == 12'h7B2) || // dscratch0
       (csr_addr_out == 12'h7B3);
       assign system_legal =
       (instr_in == 32'h00000073) ||  // ECALL
       (instr_in == 32'h00100073) ||  // EBREAK
       (instr_in == 32'h30200073) ||    // MRET
       (instr_in == 32'h7b200073);    //DRET
assign op_imm_legal =
       // ADDI
       (funct3_out == 3'b000) ||

       // SLTI
       (funct3_out == 3'b010) ||

       // SLTIU
       (funct3_out == 3'b011) ||

       // XORI
       (funct3_out == 3'b100) ||

       // ORI
       (funct3_out == 3'b110) ||

       // ANDI
       (funct3_out == 3'b111) ||

       // SLLI
       ((funct3_out == 3'b001) &&
        (funct7_out == 7'b0000000)) ||

       // SRLI / SRAI
       ((funct3_out == 3'b101) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000)));

assign op_legal =
       ((funct3_out == 3'b000) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000))) ||

       ((funct3_out == 3'b001) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b010) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b011) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b100) && (funct7_out == 7'b0000000)) ||

       ((funct3_out == 3'b101) &&
        ((funct7_out == 7'b0000000) ||
         (funct7_out == 7'b0100000))) ||

       ((funct3_out == 3'b110) && (funct7_out == 7'b0000000)) ||
       ((funct3_out == 3'b111) && (funct7_out == 7'b0000000));

assign load_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010) ||
       (funct3_out == 3'b100) ||
       (funct3_out == 3'b101);

assign store_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010);

assign branch_legal =
       (funct3_out == 3'b000) ||
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b100) ||
       (funct3_out == 3'b101) ||
       (funct3_out == 3'b110) ||
       (funct3_out == 3'b111);

assign jalr_legal =
       (funct3_out == 3'b000);

assign csr_op_legal =
       (funct3_out == 3'b001) ||
       (funct3_out == 3'b010) ||
       (funct3_out == 3'b011) ||
       (funct3_out == 3'b101) ||
       (funct3_out == 3'b110) ||
       (funct3_out == 3'b111);

/*    always @ (*) begin
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
*/

always @ (*) begin
        is_op       = 1'b0;
        is_mul      = 1'b0;
        is_op_imm   = 1'b0;
        is_load     = 1'b0;
        is_store    = 1'b0;
        is_branch   = 1'b0;
        is_jal      = 1'b0;
        is_jalr     = 1'b0;
        is_lui      = 1'b0;
        is_auipc    = 1'b0;
        is_system   = 1'b0;

        if (opcode_out[1:0] == 2'b11) begin
            case (opcode_out[6:2])
                5'b011_00: begin
                    if (funct7_out == 7'b0000001)
                        is_mul = 1'b1;
                    else
                        is_op  = 1'b1;
                end
                5'b001_00: is_op_imm = 1'b1;
                5'b000_00: is_load   = 1'b1;
                5'b010_00: is_store  = 1'b1;
                5'b110_00: is_branch = 1'b1;
                5'b110_11: is_jal    = 1'b1;
                5'b110_01: is_jalr   = 1'b1;
                5'b011_01: is_lui    = 1'b1;
                5'b001_01: is_auipc  = 1'b1;
                5'b111_00: is_system = 1'b1;
                default: ;
            endcase
        end
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
assign is_csr          = (opcode_out == 7'b1110011) && csr_op_legal;

assign csr_wr_en_out =
        is_csr &&
        csr_addr_valid &&
        (
            (csr_op_out == 3'b001) || // CSRRW
            (csr_op_out == 3'b101) || // CSRRWI

            ((csr_op_out == 3'b010) && (rs_1_addrs_out != 5'd0)) || // CSRRS
            ((csr_op_out == 3'b011) && (rs_1_addrs_out != 5'd0)) || // CSRRC

            ((csr_op_out == 3'b110) && (rs_1_addrs_out != 5'd0)) || // CSRRSI
            ((csr_op_out == 3'b111) && (rs_1_addrs_out != 5'd0))    // CSRRCI
        );
assign csr_op_out      = funct3_out;

//assign illegal_instr_out = ~(
  //  is_op | is_op_imm | is_load | is_store |
    //is_branch | is_jal | is_jalr |
    //is_lui | is_auipc | is_system | is_mul) | (is_csr && !csr_addr_valid) | (is_system && !is_csr && !system_legal);
assign illegal_instr_out =
       ~(
          is_op      |
          is_op_imm  |
          is_load    |
          is_store   |
          is_branch  |
          is_jal     |
          is_jalr    |
          is_lui     |
          is_auipc   |
          is_system  |
          is_mul
        )
       |
       (is_op      && !op_legal)
       |
       (is_op_imm  && !op_imm_legal)
       |
       (is_load    && !load_legal)
       |
       (is_store   && !store_legal)
       |
       (is_branch  && !branch_legal)
       |
       (is_jalr    && !jalr_legal)
       |
       (is_csr     && !csr_addr_valid)
       |
       (is_system  && !is_csr && !system_legal);


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

// =========================================================================
    // SYSTEM Instruction Decoding (Environment Calls and Returns)
    // SYSTEM opcode = 7'b1110011. funct3 = 3'b000.
    // The top 12 bits (funct12) determine the exact operation.
    // =========================================================================

    wire is_system_priv = is_system & (funct3_out == 3'b000);

    assign is_ecall_out  = is_system_priv & (csr_addr_out == 12'h000);
    assign is_ebreak_out = is_system_priv & (csr_addr_out == 12'h001);
    assign is_mret_out   = is_system_priv & (csr_addr_out == 12'h302);

    // NEW: Debug Return (Exits the Debugger Sandbox)
    assign is_dret_out   = is_system_priv & (csr_addr_out == 12'h7B2);

    // Optional: Upgrade illegal instruction check to catch invalid SYSTEM commands
    // assign illegal_instr_out = ~( ... ) | (is_system_priv & !(is_ecall_out | is_ebreak_out | is_mret_out | is_dret_out));


endmodule
