`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pragya_mdu
// Target: RISC-V RV32M Extension Unit Sign-off
// =============================================================================

module tb_pragya_mdu;

    // DUT Signals
    reg         clk_in;
    reg         rst_in;
    reg         mdu_valid_in;
    reg  [31:0] rs_1_in;
    reg  [31:0] rs_2_in;
    reg  [2:0]  mdu_op_in;
    reg  [4:0]  rd_in;
    reg  [31:0] pc_in;
    reg  [31:0] instr_in;

    wire [31:0] mdu_result_out;
    wire [4:0]  mdu_rd_out;
    wire [31:0] mdu_pc_out;
    wire [31:0] mdu_instr_out;
    wire        mdu_wb_valid_out;
    wire        mdu_stall_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_mdu u_pragya_mdu (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .mdu_valid_in(mdu_valid_in),
        .rs_1_in(rs_1_in),
        .rs_2_in(rs_2_in),
        .mdu_op_in(mdu_op_in),
        .rd_in(rd_in),
        .pc_in(pc_in),
        .instr_in(instr_in),
        .mdu_result_out(mdu_result_out),
        .mdu_rd_out(mdu_rd_out),
        .mdu_pc_out(mdu_pc_out),
        .mdu_instr_out(mdu_instr_out),
        .mdu_wb_valid_out(mdu_wb_valid_out),
        .mdu_stall_out(mdu_stall_out)
    );

    // 100MHz Clock Generation
    always #5 clk_in = ~clk_in;

    // MDU Operation Constants
    localparam [2:0] OP_MUL    = 3'b000;
    localparam [2:0] OP_MULH   = 3'b001;
    localparam [2:0] OP_MULHSU = 3'b010;
    localparam [2:0] OP_MULHU  = 3'b011;
    localparam [2:0] OP_DIV    = 3'b100;
    localparam [2:0] OP_DIVU   = 3'b101;
    localparam [2:0] OP_REM    = 3'b110;
    localparam [2:0] OP_REMU   = 3'b111;

    // Corner Constants
    localparam [31:0] ZERO    = 32'h0000_0000;
    localparam [31:0] MINUS_1 = 32'hFFFF_FFFF;
    localparam [31:0] MAX_POS = 32'h7FFF_FFFF;
    localparam [31:0] MIN_NEG = 32'h8000_0000;

    // =========================================================================
    // Blocking Execution & Checking Task
    // =========================================================================
    task execute_mdu_op(
        input [31:0] op1,
        input [31:0] op2,
        input [2:0]  op_code,
        input [4:0]  target_rd,
        input [31:0] exp_result,
        input string test_name
    );
        integer wait_cycles;
        total_tests = total_tests + 1;
        wait_cycles = 0;

        @(negedge clk_in);
        mdu_valid_in = 1'b1;
        rs_1_in      = op1;
        rs_2_in      = op2;
        mdu_op_in    = op_code;
        rd_in        = target_rd;
        pc_in        = 32'h0001_0000 + (total_tests << 2);
        instr_in     = {7'b0000001, 5'd2, 5'd1, op_code, target_rd, 7'b0110011};

        @(posedge clk_in);
        #1;
        // Check stall asserts immediately
        if (!mdu_stall_out) begin
            $display("[FAIL] %s | Stall was not asserted upon transaction launch!", test_name);
            failed_tests = failed_tests + 1;
        end

        // Deassert valid on next cycle to model single-cycle pipeline dispatch
        @(negedge clk_in);
        mdu_valid_in = 1'b0;

        // Wait for mdu_wb_valid_out pulse while monitoring stall
        while (!mdu_wb_valid_out) begin
            @(posedge clk_in);
            #1;
            wait_cycles = wait_cycles + 1;
            if (wait_cycles > 50) begin
                $display("[FAIL] %s | TIMEOUT! MDU hung and never finished calculation", test_name);
                failed_tests = failed_tests + 1;
                return;
            end
        end

        // Validate Result and Metadata Latching during S_DONE
        if (mdu_result_out !== exp_result || mdu_rd_out !== target_rd) begin
            $display("[FAIL] %s | Result: 0x%08h (Exp: 0x%08h), RD: %0d (Exp: %0d)",
                     test_name, mdu_result_out, exp_result, mdu_rd_out, target_rd);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Result: 0x%08h (Cycles: %0d)", test_name, mdu_result_out, wait_cycles);
        end

        // Check completion pulse length (Must deassert next cycle)
        @(posedge clk_in);
        #1;
        if (mdu_wb_valid_out) begin
            $display("[FAIL] %s | mdu_wb_valid_out did not drop after 1 cycle!", test_name);
            failed_tests = failed_tests + 1;
        end
    endtask

    // =========================================================================
    // Test Vectors
    // =========================================================================
    initial begin
        clk_in       = 1'b0;
        rst_in       = 1'b1;
        mdu_valid_in = 1'b0;
        rs_1_in      = 32'd0;
        rs_2_in      = 32'd0;
        mdu_op_in    = 3'd0;
        rd_in        = 5'd0;
        pc_in        = 32'd0;
        instr_in     = 32'd0;

        #20;
        @(posedge clk_in);
        rst_in = 1'b0;
        @(posedge clk_in);

        $display("\n=======================================================");
        $display("          STARTING PRAGYA MDU VERIFICATION             ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // Group 1: RISC-V Specification Mandatory Division by Zero
        // -------------------------------------------------------------
        $display("--- [Group 1] Division by Zero Corner Cases ---");
        // DIV X / 0 = -1 (0xFFFFFFFF)
        execute_mdu_op(32'd10, ZERO, OP_DIV, 5'd1, MINUS_1, "DIV by 0 (Pos/0)");
        execute_mdu_op(MINUS_1, ZERO, OP_DIV, 5'd2, MINUS_1, "DIV by 0 (Neg/0)");

        // DIVU X / 0 = 2^32 - 1 (0xFFFFFFFF)
        execute_mdu_op(32'd50, ZERO, OP_DIVU, 5'd3, MINUS_1, "DIVU by 0");

        // REM X % 0 = X
        execute_mdu_op(32'd7, ZERO, OP_REM, 5'd4, 32'd7, "REM by 0 (7 % 0 = 7)");
        execute_mdu_op(-32'd7, ZERO, OP_REM, 5'd5, -32'd7, "REM by 0 (-7 % 0 = -7)");

        // REMU X % 0 = X
        execute_mdu_op(32'hDEAD_BEEF, ZERO, OP_REMU, 5'd6, 32'hDEAD_BEEF, "REMU by 0 (DEADBEEF % 0)");

        // -------------------------------------------------------------
        // Group 2: RISC-V Specification Mandatory Signed Overflow
        // -------------------------------------------------------------
        $display("\n--- [Group 2] Signed Overflow Corner Cases (-2^31 / -1) ---");
        // DIV: -2^31 / -1 = -2^31 (Overflow wrap-around)
        execute_mdu_op(MIN_NEG, MINUS_1, OP_DIV, 5'd7, MIN_NEG, "DIV Overflow (0x80000000 / -1)");

        // REM: -2^31 % -1 = 0
        execute_mdu_op(MIN_NEG, MINUS_1, OP_REM, 5'd8, ZERO, "REM Overflow (0x80000000 % -1)");

        // -------------------------------------------------------------
        // Group 3: Regular Signed and Unsigned Division/Remainder
        // -------------------------------------------------------------
        $display("\n--- [Group 3] Standard Division & Remainder Paths ---");
        // Positive / Positive
        execute_mdu_op(32'd20, 32'd3, OP_DIV, 5'd9, 32'd6, "DIV (20 / 3)");
        execute_mdu_op(32'd20, 32'd3, OP_REM, 5'd10, 32'd2, "REM (20 % 3)");

        // Negative / Positive
        execute_mdu_op(-32'd20, 32'd3, OP_DIV, 5'd11, -32'd6, "DIV (-20 / 3 = -6)");
        execute_mdu_op(-32'd20, 32'd3, OP_REM, 5'd12, -32'd2, "REM (-20 % 3 = -2)");

        // Positive / Negative
        execute_mdu_op(32'd20, -32'd3, OP_DIV, 5'd13, -32'd6, "DIV (20 / -3 = -6)");
        execute_mdu_op(32'd20, -32'd3, OP_REM, 5'd14, 32'd2, "REM (20 % -3 = 2)");

        // Negative / Negative
        execute_mdu_op(-32'd20, -32'd3, OP_DIV, 5'd15, 32'd6, "DIV (-20 / -3 = 6)");
        execute_mdu_op(-32'd20, -32'd3, OP_REM, 5'd16, -32'd2, "REM (-20 % -3 = -2)");

        // DIVU / REMU
        execute_mdu_op(32'hFFFF_FFF6, 32'd2, OP_DIVU, 5'd17, 32'h7FFF_FFFB, "DIVU Unsigned High");
        execute_mdu_op(32'hFFFF_FFF7, 32'd2, OP_REMU, 5'd18, 32'd1, "REMU Unsigned Remainder");

        // -------------------------------------------------------------
        // Group 4: Multiplier Operations (MUL, MULH, MULHSU, MULHU)
        // -------------------------------------------------------------
        $display("\n--- [Group 4] Multiplier Sign & Cross Boundary Checks ---");
        // MUL (Lower 32-bits)
        execute_mdu_op(32'd1000, 32'd2000, OP_MUL, 5'd19, 32'd2000000, "MUL Basic");
        execute_mdu_op(MINUS_1, 32'd5, OP_MUL, 5'd20, -32'd5, "MUL (-1 * 5)");

        // MULH (Signed x Signed Upper 32-bits)
        // (-1) * (-1) = +1 -> 64-bit: 0x0000_0000_0000_0001 -> Upper: 0
        execute_mdu_op(MINUS_1, MINUS_1, OP_MULH, 5'd21, ZERO, "MULH (-1 * -1)");
        // (-1) * 1 = -1 -> 64-bit: 0xFFFF_FFFF_FFFF_FFFF -> Upper: 0xFFFFFFFF
        execute_mdu_op(MINUS_1, 32'd1, OP_MULH, 5'd22, MINUS_1, "MULH (-1 * 1)");
        // Max Pos * Max Pos
        execute_mdu_op(MAX_POS, MAX_POS, OP_MULH, 5'd23, 32'h3FFF_FFFF, "MULH (MAX_POS * MAX_POS)");
        // Min Neg * Min Neg
        execute_mdu_op(MIN_NEG, MIN_NEG, OP_MULH, 5'd24, 32'h4000_0000, "MULH (MIN_NEG * MIN_NEG)");

        // MULHSU (Signed x Unsigned Upper 32-bits)
        // (-1 signed) * (2 unsigned) = -2 (64-bit sign extended: 0xFFFF_FFFF_FFFF_FFFE -> Upper: 0xFFFFFFFF)
        execute_mdu_op(MINUS_1, 32'd2, OP_MULHSU, 5'd25, MINUS_1, "MULHSU (-1 * 2u)");
        // (1 signed) * (0xFFFFFFFF unsigned) = 0x0000_0000_FFFF_FFFF -> Upper: 0
        execute_mdu_op(32'd1, MINUS_1, OP_MULHSU, 5'd26, ZERO, "MULHSU (1 * 0xFFFFFFFFu)");

        // MULHU (Unsigned x Unsigned Upper 32-bits)
        // 0xFFFFFFFF * 0xFFFFFFFF = 0xFFFF_FFFE_0000_0001 -> Upper: 0xFFFFFFFE
        execute_mdu_op(MINUS_1, MINUS_1, OP_MULHU, 5'd27, 32'hFFFF_FFFE, "MULHU (All 1s * All 1s)");
        execute_mdu_op(32'h8000_0000, 32'd2, OP_MULHU, 5'd28, 32'd1, "MULHU (0x80000000 * 2)");

        // -------------------------------------------------------------
        // Group 5: Back-to-Back Pipeline Sequencing (No Bubbles)
        // -------------------------------------------------------------
        $display("\n--- [Group 5] Backpressure & Back-to-Back Sequencing ---");
        // Issue MUL and right when it completes, issue DIV without an idle clock
        execute_mdu_op(32'd6, 32'd7, OP_MUL, 5'd29, 32'd42, "Back-to-Back Phase 1 (MUL)");
        execute_mdu_op(32'd42, 32'd7, OP_DIV, 5'd30, 32'd6, "Back-to-Back Phase 2 (DIV)");

        // -------------------------------------------------------------
        // Summary & Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.6)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule