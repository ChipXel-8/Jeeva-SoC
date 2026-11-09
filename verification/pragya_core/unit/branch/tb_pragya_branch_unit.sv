`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pragya_branch_unit
// Target Checklist Item: 4.5 (Unit TB for Branch Unit)
// Scope:
//   - Full comparison matrix (rs1 < rs2, rs1 == rs2, rs1 > rs2)
//   - Signed vs. unsigned boundary polarity checks (0x80000000, 0x7FFFFFFF, -1, 0)
//   - Unconditional jump assertions (JAL, JALR)
//   - Reserved funct3 and default opcode branches for 100% coverage closure
// =============================================================================

module tb_pragya_branch_unit;

    // DUT Signals
    reg  [31:0] rs_1_in;
    reg  [31:0] rs_2_in;
    reg  [4:0]  opcode6_to_2_in;
    reg  [2:0]  funct3_in;
    wire        branch_taken_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate Branch Unit DUT
    pragya_branch_unit u_pragya_branch_unit (
        .rs_1_in(rs_1_in),
        .rs_2_in(rs_2_in),
        .opcode6_to_2_in(opcode6_to_2_in),
        .funct3_in(funct3_in),
        .branch_taken_out(branch_taken_out)
    );

    // Self-Checking Verification Task
    task check_branch(
        input [31:0] a,
        input [31:0] b,
        input [4:0]  op,
        input [2:0]  f3,
        input        exp_taken,
        input string name
    );
        total_tests = total_tests + 1;
        rs_1_in         = a;
        rs_2_in         = b;
        opcode6_to_2_in = op;
        funct3_in       = f3;
        #1; // Combinational propagation delay

        if (branch_taken_out !== exp_taken) begin
            $display("[FAIL] %s | A=0x%08h B=0x%08h op=%b f3=%b -> Got: %b, Expected: %b",
                     name, a, b, op, f3, branch_taken_out, exp_taken);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | A=0x%08h B=0x%08h -> taken = %b",
                     name, a, b, branch_taken_out);
        end
    endtask

    // Opcode & Funct3 Constants
    localparam [4:0] OP_BRANCH = 5'b11000;
    localparam [4:0] OP_JAL    = 5'b11011;
    localparam [4:0] OP_JALR   = 5'b11001;

    localparam [2:0] F3_BEQ    = 3'b000;
    localparam [2:0] F3_BNE    = 3'b001;
    localparam [2:0] F3_BLT    = 3'b100;
    localparam [2:0] F3_BGE    = 3'b101;
    localparam [2:0] F3_BLTU   = 3'b110;
    localparam [2:0] F3_BGEU   = 3'b111;

    // Corner Constants
    localparam [31:0] ZERO     = 32'h0000_0000;
    localparam [31:0] MINUS_1  = 32'hFFFF_FFFF;
    localparam [31:0] MAX_POS  = 32'h7FFF_FFFF;
    localparam [31:0] MIN_NEG  = 32'h8000_0000;

    initial begin
        rs_1_in         = 32'd0;
        rs_2_in         = 32'd0;
        opcode6_to_2_in = 5'd0;
        funct3_in       = 3'd0;

        $display("\n=======================================================");
        $display("     STARTING PRAGYA BRANCH UNIT VERIFICATION SUITE   ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // Group 1: BEQ & BNE Matrix (Equal, Less, Greater)
        // -------------------------------------------------------------
        $display("--- [Group 1] BEQ & BNE Verification ---");
        // Equal
        check_branch(32'd50, 32'd50, OP_BRANCH, F3_BEQ, 1'b1, "BEQ Equal (50 == 50)");
        check_branch(32'd50, 32'd50, OP_BRANCH, F3_BNE, 1'b0, "BNE Equal (50 == 50)");
        // Not Equal (rs1 < rs2)
        check_branch(32'd20, 32'd50, OP_BRANCH, F3_BEQ, 1'b0, "BEQ Less (20 != 50)");
        check_branch(32'd20, 32'd50, OP_BRANCH, F3_BNE, 1'b1, "BNE Less (20 != 50)");
        // Not Equal (rs1 > rs2)
        check_branch(32'd90, 32'd50, OP_BRANCH, F3_BEQ, 1'b0, "BEQ Greater (90 != 50)");
        check_branch(32'd90, 32'd50, OP_BRANCH, F3_BNE, 1'b1, "BNE Greater (90 != 50)");

        // -------------------------------------------------------------
        // Group 2: BLT & BGE Signed Comparison Matrix
        // -------------------------------------------------------------
        $display("\n--- [Group 2] BLT & BGE Signed Matrix ---");
        // rs1 < rs2
        check_branch(32'd10, 32'd20, OP_BRANCH, F3_BLT, 1'b1, "BLT Positive (10 < 20)");
        check_branch(32'd10, 32'd20, OP_BRANCH, F3_BGE, 1'b0, "BGE Positive (10 >= 20)");
        // rs1 == rs2
        check_branch(32'd20, 32'd20, OP_BRANCH, F3_BLT, 1'b0, "BLT Equal (20 < 20)");
        check_branch(32'd20, 32'd20, OP_BRANCH, F3_BGE, 1'b1, "BGE Equal (20 >= 20)");
        // rs1 > rs2
        check_branch(32'd30, 32'd20, OP_BRANCH, F3_BLT, 1'b0, "BLT Greater (30 < 20)");
        check_branch(32'd30, 32'd20, OP_BRANCH, F3_BGE, 1'b1, "BGE Greater (30 >= 20)");

        // -------------------------------------------------------------
        // Group 3: BLTU & BGEU Unsigned Comparison Matrix
        // -------------------------------------------------------------
        $display("\n--- [Group 3] BLTU & BGEU Unsigned Matrix ---");
        // rs1 < rs2
        check_branch(32'h0000_0005, 32'h0000_000A, OP_BRANCH, F3_BLTU, 1'b1, "BLTU Unsigned (5 < 10)");
        check_branch(32'h0000_0005, 32'h0000_000A, OP_BRANCH, F3_BGEU, 1'b0, "BGEU Unsigned (5 >= 10)");
        // rs1 == rs2
        check_branch(32'h0000_000A, 32'h0000_000A, OP_BRANCH, F3_BLTU, 1'b0, "BLTU Equal (10 < 10)");
        check_branch(32'h0000_000A, 32'h0000_000A, OP_BRANCH, F3_BGEU, 1'b1, "BGEU Equal (10 >= 10)");
        // rs1 > rs2
        check_branch(32'h0000_0010, 32'h0000_000A, OP_BRANCH, F3_BLTU, 1'b0, "BLTU Greater (16 < 10)");
        check_branch(32'h0000_0010, 32'h0000_000A, OP_BRANCH, F3_BGEU, 1'b1, "BGEU Greater (16 >= 10)");

        // -------------------------------------------------------------
        // Group 4: Signed vs. Unsigned Boundary Inversion Corners
        // -------------------------------------------------------------
        $display("\n--- [Group 4] Critical Signed vs. Unsigned Polarities ---");
        // Test -1 (0xFFFFFFFF) vs +1 (0x00000001)
        // Signed: -1 < 1 is TRUE
        check_branch(MINUS_1, 32'd1, OP_BRANCH, F3_BLT,  1'b1, "BLT: -1 < 1 (True)");
        check_branch(MINUS_1, 32'd1, OP_BRANCH, F3_BGE,  1'b0, "BGE: -1 >= 1 (False)");
        // Unsigned: 0xFFFFFFFF < 1 is FALSE
        check_branch(MINUS_1, 32'd1, OP_BRANCH, F3_BLTU, 1'b0, "BLTU: 0xFFFFFFFF < 1 (False)");
        check_branch(MINUS_1, 32'd1, OP_BRANCH, F3_BGEU, 1'b1, "BGEU: 0xFFFFFFFF >= 1 (True)");

        // Test Min Neg (0x80000000) vs Max Pos (0x7FFFFFFF)
        // Signed: -2^31 < 2^31-1 is TRUE
        check_branch(MIN_NEG, MAX_POS, OP_BRANCH, F3_BLT,  1'b1, "BLT: MinNeg < MaxPos (True)");
        check_branch(MIN_NEG, MAX_POS, OP_BRANCH, F3_BGE,  1'b0, "BGE: MinNeg >= MaxPos (False)");
        // Unsigned: 0x80000000 < 0x7FFFFFFF is FALSE
        check_branch(MIN_NEG, MAX_POS, OP_BRANCH, F3_BLTU, 1'b0, "BLTU: 0x80000000 < 0x7FFFFFFF (False)");
        check_branch(MIN_NEG, MAX_POS, OP_BRANCH, F3_BGEU, 1'b1, "BGEU: 0x80000000 >= 0x7FFFFFFF (True)");

        // Boundary comparison against ZERO
        check_branch(MIN_NEG, ZERO, OP_BRANCH, F3_BLT,  1'b1, "BLT: MinNeg < 0 (True)");
        check_branch(MIN_NEG, ZERO, OP_BRANCH, F3_BLTU, 1'b0, "BLTU: MinNeg < 0 (False, 0x80000000 > 0)");

        // -------------------------------------------------------------
        // Group 5: Unconditional Jumps (JAL / JALR)
        // -------------------------------------------------------------
        $display("\n--- [Group 5] Unconditional Jumps (JAL & JALR) ---");
        check_branch(32'h0, 32'h0, OP_JAL,  3'b000, 1'b1, "JAL taken unconditionally");
        check_branch(32'h1, 32'h2, OP_JAL,  3'b111, 1'b1, "JAL taken with arbitrary f3");
        check_branch(32'h0, 32'h0, OP_JALR, 3'b000, 1'b1, "JALR taken unconditionally");
        check_branch(32'h5, 32'h6, OP_JALR, 3'b010, 1'b1, "JALR taken with arbitrary f3");

        // -------------------------------------------------------------
        // Group 6: Coverage Closure (Reserved Funct3 & Non-Branch Opcodes)
        // -------------------------------------------------------------
        $display("\n--- [Group 6] Reserved Funct3 & Fallthrough Branches ---");
        // Reserved funct3 in branch opcode (3'b010 and 3'b011)
        check_branch(32'd10, 32'd10, OP_BRANCH, 3'b010, 1'b0, "Reserved funct3 3'b010 -> Not taken");
        check_branch(32'd10, 32'd10, OP_BRANCH, 3'b011, 1'b0, "Reserved funct3 3'b011 -> Not taken");

        // Non-branch / default opcodes (ALU, Load, Store)
        check_branch(32'd10, 32'd10, 5'b01100, 3'b000, 1'b0, "OP-ALU opcode -> Not taken");
        check_branch(32'd10, 32'd10, 5'b00000, 3'b000, 1'b0, "Load opcode -> Not taken");
        check_branch(32'd10, 32'd10, 5'b11111, 3'b111, 1'b0, "Unknown opcode -> Not taken");

        // -------------------------------------------------------------
        // Summary & Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.5)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule