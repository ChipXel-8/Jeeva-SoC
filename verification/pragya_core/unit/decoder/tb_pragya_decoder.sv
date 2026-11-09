`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pragya_decoder
// Target Checklist Item: 4.2 (Unit TB for decoder / control)
// =============================================================================

module tb_pragya_decoder;

    // Inputs to DUT
    reg  [31:0] instr_in;

    // Outputs from DUT
    wire [4:0]  rs_1_addrs_out;
    wire [4:0]  rs_2_addrs_out;
    wire [4:0]  rd_addrs_out;
    wire [24:0] instr_out;
    wire [2:0]  funct3_out;
    wire [6:0]  funct7_out;
    wire [6:0]  opcode_out;
    wire [2:0]  mdu_op_out;
    wire [3:0]  alu_control_out;
    wire        reg_write_out;
    wire [2:0]  imm_src_out;
    wire        alu_src_out;
    wire        mem_write_out;
    wire        mem_req_out;
    wire [2:0]  wb_mux_sel_out;
    wire        i_adder_src_out;
    wire        jalr_out;
    wire [6:2]  opcode6_to_2_out;
    wire [11:0] csr_addr_out;
    wire        csr_wr_en_out;
    wire [2:0]  csr_op_out;
    wire        illegal_instr_out;
    wire        is_dret_out;
    wire        is_mret_out;
    wire        is_ecall_out;
    wire        is_ebreak_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_decoder u_pragya_decoder (
        .instr_in(instr_in),
        .rs_1_addrs_out(rs_1_addrs_out),
        .rs_2_addrs_out(rs_2_addrs_out),
        .rd_addrs_out(rd_addrs_out),
        .instr_out(instr_out),
        .funct3_out(funct3_out),
        .funct7_out(funct7_out),
        .opcode_out(opcode_out),
        .mdu_op_out(mdu_op_out),
        .alu_control_out(alu_control_out),
        .reg_write_out(reg_write_out),
        .imm_src_out(imm_src_out),
        .alu_src_out(alu_src_out),
        .mem_write_out(mem_write_out),
        .mem_req_out(mem_req_out),
        .wb_mux_sel_out(wb_mux_sel_out),
        .i_adder_src_out(i_adder_src_out),
        .jalr_out(jalr_out),
        .opcode6_to_2_out(opcode6_to_2_out),
        .csr_addr_out(csr_addr_out),
        .csr_wr_en_out(csr_wr_en_out),
        .csr_op_out(csr_op_out),
        .illegal_instr_out(illegal_instr_out),
        .is_dret_out(is_dret_out),
        .is_mret_out(is_mret_out),
        .is_ecall_out(is_ecall_out),
        .is_ebreak_out(is_ebreak_out)
    );

    // =========================================================================
    // Functional Coverage: opcode x funct3 x funct7 Cross Coverage
    // =========================================================================
    covergroup decoder_cg;
        option.per_instance = 1;

        cp_opcode: coverpoint opcode_out {
            bins op_r       = {7'b0110011};
            bins op_i       = {7'b0010011};
            bins load       = {7'b0000011};
            bins store      = {7'b0100011};
            bins branch     = {7'b1100011};
            bins jal        = {7'b1101111};
            bins jalr       = {7'b1100111};
            bins lui        = {7'b0110111};
            bins auipc      = {7'b0010111};
            bins system     = {7'b1110011};
            bins illegal_op = default;
        }

        cp_funct3: coverpoint funct3_out;
        cp_funct7: coverpoint funct7_out {
            bins std_r   = {7'b0000000};
            bins sub_sra = {7'b0100000};
            bins m_ext   = {7'b0000001};
            bins others  = default;
        }

        // Checklist Item 4.2: opcode x funct3 x funct7 cross-coverage closed
        cross_op_f3_f7: cross cp_opcode, cp_funct3, cp_funct7;
    endgroup

    decoder_cg cg_inst = new();

    // =========================================================================
    // Self-Checking Verification Tasks
    // =========================================================================
    task check_instr(
        input [31:0] test_instruction,
        input        exp_illegal,
        input        exp_reg_write,
        input [3:0]  exp_alu_ctrl,
        input [2:0]  exp_wb_mux,
        input [2:0]  exp_mdu_op,
        input        exp_mem_req,
        input        exp_mem_wr,
        input string name
    );
        total_tests = total_tests + 1;
        instr_in = test_instruction;
        #1; // Combinational propagation delay
        cg_inst.sample();

        if (illegal_instr_out !== exp_illegal     ||
            reg_write_out     !== exp_reg_write   ||
            alu_control_out   !== exp_alu_ctrl    ||
            wb_mux_sel_out    !== exp_wb_mux      ||
            mdu_op_out        !== exp_mdu_op      ||
            mem_req_out       !== exp_mem_req     ||
            mem_write_out     !== exp_mem_wr) begin
            $display("[FAIL] %s (0x%08h) -> Got: Ill=%b RegWr=%b ALU=%b WB=%b MDU=%b MemReq=%b MemWr=%b | Expected: Ill=%b RegWr=%b ALU=%b WB=%b MDU=%b MemReq=%b MemWr=%b",
                     name, test_instruction,
                     illegal_instr_out, reg_write_out, alu_control_out, wb_mux_sel_out, mdu_op_out, mem_req_out, mem_write_out,
                     exp_illegal, exp_reg_write, exp_alu_ctrl, exp_wb_mux, exp_mdu_op, exp_mem_req, exp_mem_wr);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s (0x%08h)", name, test_instruction);
        end
    endtask

    task check_priv(
        input [31:0] test_instruction,
        input exp_ecall,
        input exp_ebreak,
        input exp_mret,
        input exp_dret,
        input string name
    );
        total_tests = total_tests + 1;
        instr_in = test_instruction;
        #1;
        cg_inst.sample();

        if (is_ecall_out  !== exp_ecall  ||
            is_ebreak_out !== exp_ebreak ||
            is_mret_out   !== exp_mret   ||
            is_dret_out   !== exp_dret   ||
            illegal_instr_out !== 1'b0) begin
            $display("[FAIL] %s Priv -> Got: ECALL=%b EBREAK=%b MRET=%b DRET=%b Ill=%b",
                     name, is_ecall_out, is_ebreak_out, is_mret_out, is_dret_out, illegal_instr_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s Verified", name);
        end
    endtask

    // Instruction Field Formatter Helpers
    function [31:0] r_type(input [6:0] f7, input [4:0] rs2, input [4:0] rs1, input [2:0] f3, input [4:0] rd, input [6:0] op);
        return {f7, rs2, rs1, f3, rd, op};
    endfunction

    function [31:0] i_type(input [11:0] imm, input [4:0] rs1, input [2:0] f3, input [4:0] rd, input [6:0] op);
        return {imm, rs1, f3, rd, op};
    endfunction

    function [31:0] s_type(input [11:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] f3, input [6:0] op);
        return {imm[11:5], rs2, rs1, f3, imm[4:0], op};
    endfunction

    function [31:0] b_type(input [11:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] f3, input [6:0] op);
        return {imm[11], imm[9:4], rs2, rs1, f3, imm[3:0], imm[10], op};
    endfunction

    // =========================================================================
    // Test Vectors
    // =========================================================================
    initial begin
        instr_in = 32'h00000013; // NOP (ADDI x0, x0, 0)
        #5;

        $display("\n=======================================================");
        $display("     STARTING PRAGYA DECODER VERIFICATION SUITE       ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // Group 1: RV32I ALU Register-Immediate Instructions
        // -------------------------------------------------------------
        $display("--- [Group 1] RV32I OP-IMM Instructions ---");
        //                      inst                                 ill regwr  alu    wb    mdu   mreq  mwr
        check_instr(i_type(12'd10, 5'd1, 3'b000, 5'd2, 7'b0010011), 1'b0, 1'b1, 4'b0000, 3'b000, 3'b000, 1'b0, 1'b0, "ADDI");
        check_instr(i_type(12'd5,  5'd2, 3'b010, 5'd3, 7'b0010011), 1'b0, 1'b1, 4'b1000, 3'b000, 3'b000, 1'b0, 1'b0, "SLTI");
        check_instr(i_type(12'd8,  5'd3, 3'b011, 5'd4, 7'b0010011), 1'b0, 1'b1, 4'b1001, 3'b000, 3'b000, 1'b0, 1'b0, "SLTIU");
        check_instr(i_type(12'd15, 5'd4, 3'b100, 5'd5, 7'b0010011), 1'b0, 1'b1, 4'b0100, 3'b000, 3'b000, 1'b0, 1'b0, "XORI");
        check_instr(i_type(12'd7,  5'd5, 3'b110, 5'd6, 7'b0010011), 1'b0, 1'b1, 4'b0011, 3'b000, 3'b000, 1'b0, 1'b0, "ORI");
        check_instr(i_type(12'd3,  5'd6, 3'b111, 5'd7, 7'b0010011), 1'b0, 1'b1, 4'b0010, 3'b000, 3'b000, 1'b0, 1'b0, "ANDI");
        check_instr({7'b0000000, 5'd4, 5'd1, 3'b001, 5'd2, 7'b0010011}, 1'b0, 1'b1, 4'b0101, 3'b000, 3'b000, 1'b0, 1'b0, "SLLI");
        check_instr({7'b0000000, 5'd4, 5'd1, 3'b101, 5'd2, 7'b0010011}, 1'b0, 1'b1, 4'b0110, 3'b000, 3'b000, 1'b0, 1'b0, "SRLI");
        check_instr({7'b0100000, 5'd4, 5'd1, 3'b101, 5'd2, 7'b0010011}, 1'b0, 1'b1, 4'b0111, 3'b000, 3'b000, 1'b0, 1'b0, "SRAI");

        // -------------------------------------------------------------
        // Group 2: RV32I ALU Register-Register Instructions
        // -------------------------------------------------------------
        $display("\n--- [Group 2] RV32I OP Register-Register Instructions ---");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b000, 3'b000, 1'b0, 1'b0, "ADD");
        check_instr(r_type(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "SUB");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0101, 3'b000, 3'b000, 1'b0, 1'b0, "SLL");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b1000, 3'b000, 3'b000, 1'b0, 1'b0, "SLT");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b011, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b1001, 3'b000, 3'b000, 1'b0, 1'b0, "SLTU");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0100, 3'b000, 3'b000, 1'b0, 1'b0, "XOR");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b101, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0110, 3'b000, 3'b000, 1'b0, 1'b0, "SRL");
        check_instr(r_type(7'b0100000, 5'd2, 5'd1, 3'b101, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0111, 3'b000, 3'b000, 1'b0, 1'b0, "SRA");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0011, 3'b000, 3'b000, 1'b0, 1'b0, "OR");
        check_instr(r_type(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0010, 3'b000, 3'b000, 1'b0, 1'b0, "AND");

        // -------------------------------------------------------------
        // Group 3: RV32M Hardware Multiplier & Divider (funct7 = 0000001)
        // -------------------------------------------------------------
        $display("\n--- [Group 3] RV32M Extension Instructions ---");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b000, 1'b0, 1'b0, "MUL");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b001, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b001, 1'b0, 1'b0, "MULH");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b010, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b010, 1'b0, 1'b0, "MULHSU");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b011, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b011, 1'b0, 1'b0, "MULHU");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b100, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b100, 1'b0, 1'b0, "DIV");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b101, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b101, 1'b0, 1'b0, "DIVU");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b110, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b110, 1'b0, 1'b0, "REM");
        check_instr(r_type(7'b0000001, 5'd2, 5'd1, 3'b111, 5'd3, 7'b0110011), 1'b0, 1'b1, 4'b0000, 3'b101, 3'b111, 1'b0, 1'b0, "REMU");

        // -------------------------------------------------------------
        // Group 4: Memory Operations (Loads & Stores)
        // -------------------------------------------------------------
        $display("\n--- [Group 4] Memory Instructions ---");
        check_instr(i_type(12'd4, 5'd1, 3'b000, 5'd2, 7'b0000011), 1'b0, 1'b1, 4'b0000, 3'b001, 3'b000, 1'b1, 1'b0, "LB");
        check_instr(i_type(12'd4, 5'd1, 3'b001, 5'd2, 7'b0000011), 1'b0, 1'b1, 4'b0000, 3'b001, 3'b000, 1'b1, 1'b0, "LH");
        check_instr(i_type(12'd4, 5'd1, 3'b010, 5'd2, 7'b0000011), 1'b0, 1'b1, 4'b0000, 3'b001, 3'b000, 1'b1, 1'b0, "LW");
        check_instr(i_type(12'd4, 5'd1, 3'b100, 5'd2, 7'b0000011), 1'b0, 1'b1, 4'b0000, 3'b001, 3'b000, 1'b1, 1'b0, "LBU");
        check_instr(i_type(12'd4, 5'd1, 3'b101, 5'd2, 7'b0000011), 1'b0, 1'b1, 4'b0000, 3'b001, 3'b000, 1'b1, 1'b0, "LHU");

        check_instr(s_type(12'd8, 5'd2, 5'd1, 3'b000, 7'b0100011), 1'b0, 1'b0, 4'b0000, 3'b000, 3'b000, 1'b1, 1'b1, "SB");
        check_instr(s_type(12'd8, 5'd2, 5'd1, 3'b001, 7'b0100011), 1'b0, 1'b0, 4'b0000, 3'b000, 3'b000, 1'b1, 1'b1, "SH");
        check_instr(s_type(12'd8, 5'd2, 5'd1, 3'b010, 7'b0100011), 1'b0, 1'b0, 4'b0000, 3'b000, 3'b000, 1'b1, 1'b1, "SW");

        // -------------------------------------------------------------
        // Group 5: Control Flow (Branches and Jumps)
        // -------------------------------------------------------------
        $display("\n--- [Group 5] Control Flow Instructions ---");
        check_instr(b_type(12'd8, 5'd2, 5'd1, 3'b000, 7'b1100011), 1'b0, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "BEQ");
        check_instr(b_type(12'd8, 5'd2, 5'd1, 3'b001, 7'b1100011), 1'b0, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "BNE");
        check_instr(b_type(12'd8, 5'd2, 5'd1, 3'b100, 7'b1100011), 1'b0, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "BLT");
        check_instr(b_type(12'd8, 5'd2, 5'd1, 3'b101, 7'b1100011), 1'b0, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "BGE");
        check_instr(b_type(12'd8, 5'd2, 5'd1, 3'b110, 7'b1100011), 1'b0, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "BLTU");
        check_instr(b_type(12'd8, 5'd2, 5'd1, 3'b111, 7'b1100011), 1'b0, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "BGEU");

        check_instr({20'd100, 5'd1, 7'b1101111}, 1'b0, 1'b1, 4'b0000, 3'b010, 3'b000, 1'b0, 1'b0, "JAL");
        check_instr(i_type(12'd16, 5'd2, 3'b000, 5'd1, 7'b1100111), 1'b0, 1'b1, 4'b0000, 3'b010, 3'b000, 1'b0, 1'b0, "JALR");

        // -------------------------------------------------------------
        // Group 6: Upper Immediate (LUI / AUIPC)
        // -------------------------------------------------------------
        $display("\n--- [Group 6] Upper Immediate Instructions ---");
        check_instr({20'h12345, 5'd1, 7'b0110111}, 1'b0, 1'b1, 4'b0000, 3'b011, 3'b000, 1'b0, 1'b0, "LUI");
        check_instr({20'h12345, 5'd1, 7'b0010111}, 1'b0, 1'b1, 4'b0000, 3'b100, 3'b000, 1'b0, 1'b0, "AUIPC");

        // -------------------------------------------------------------
        // Group 7: SYSTEM Privileged Instructions
        // -------------------------------------------------------------
        $display("\n--- [Group 7] SYSTEM Instructions ---");
        check_priv(32'h00000073, 1'b1, 1'b0, 1'b0, 1'b0, "ECALL");
        check_priv(32'h00100073, 1'b0, 1'b1, 1'b0, 1'b0, "EBREAK");
        check_priv(32'h30200073, 1'b0, 1'b0, 1'b1, 1'b0, "MRET");
        check_priv(32'h7B200073, 1'b0, 1'b0, 1'b0, 1'b1, "DRET");

        // -------------------------------------------------------------
        // Group 8: CSR Access Instructions
        // -------------------------------------------------------------
        $display("\n--- [Group 8] CSR Read/Write Instructions ---");
        // CSRRW on mstatus (0x300)
        check_instr(i_type(12'h300, 5'd1, 3'b001, 5'd2, 7'b1110011), 1'b0, 1'b1, 4'b0000, 3'b110, 3'b000, 1'b0, 1'b0, "CSRRW (mstatus)");
        if (!csr_wr_en_out) begin
            $display("[FAIL] CSRRW wr_en should be asserted!");
            failed_tests = failed_tests + 1;
        end else total_tests = total_tests + 1;

        // CSRRS with rs1 == 0 (Read-only condition: csr_wr_en_out must stay 0)
        check_instr(i_type(12'h300, 5'd0, 3'b010, 5'd2, 7'b1110011), 1'b0, 1'b1, 4'b0000, 3'b110, 3'b000, 1'b0, 1'b0, "CSRRS (rs1=0 read-only)");
        if (csr_wr_en_out) begin
            $display("[FAIL] CSRRS with rs1=0 should NOT assert wr_en!");
            failed_tests = failed_tests + 1;
        end else total_tests = total_tests + 1;

        // -------------------------------------------------------------
        // Group 9: Illegal Instruction Boundary Conditions
        // -------------------------------------------------------------
        $display("\n--- [Group 9] Illegal Instruction Corner Cases ---");
        // Unknown opcode
        check_instr(32'h00000000, 1'b1, 1'b0, 4'b0000, 3'b000, 3'b000, 1'b0, 1'b0, "Illegal Opcode (All 0s)");
        check_instr(32'hFFFFFFFF, 1'b1, 1'b0, 4'b0000, 3'b000, 3'b000, 1'b0, 1'b0, "Illegal Opcode (All 1s)");

        // Reserved funct3 on Load
        check_instr(i_type(12'd4, 5'd1, 3'b011, 5'd2, 7'b0000011), 1'b1, 1'b1, 4'b0000, 3'b001, 3'b000, 1'b1, 1'b0, "Illegal Load funct3 (3'b011)");

        // Reserved funct3 on Store
        check_instr(s_type(12'd4, 5'd1, 5'd2, 3'b011, 7'b0100011), 1'b1, 1'b0, 4'b0000, 3'b000, 3'b000, 1'b1, 1'b1, "Illegal Store funct3 (3'b011)");

        // Reserved funct3 on Branch
        check_instr(b_type(12'd4, 5'd1, 5'd2, 3'b010, 7'b1100011), 1'b1, 1'b0, 4'b0001, 3'b000, 3'b000, 1'b0, 1'b0, "Illegal Branch funct3 (3'b010)");

        // Invalid CSR address access
        check_instr(i_type(12'h999, 5'd1, 3'b001, 5'd2, 7'b1110011), 1'b1, 1'b1, 4'b0000, 3'b110, 3'b000, 1'b0, 1'b0, "Illegal CSR Address (0x999)");

        // Invalid funct7 on OP-IMM SLLI
        check_instr({7'b0100000, 5'd4, 5'd1, 3'b001, 5'd2, 7'b0010011}, 1'b1, 1'b1, 4'b0101, 3'b000, 3'b000, 1'b0, 1'b0, "Illegal SLLI funct7");

        // -------------------------------------------------------------
        // Group 10: Randomized Cross-Coverage Sweep
        // -------------------------------------------------------------
        $display("\n--- [Group 10] Cross-Coverage & Toggle Sweep (2000 Cycles) ---");
        for (int i = 0; i < 2000; i++) begin
            instr_in = $urandom();
            #1;
            cg_inst.sample();
        end

        // -------------------------------------------------------------
        // Summary & Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.2)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule