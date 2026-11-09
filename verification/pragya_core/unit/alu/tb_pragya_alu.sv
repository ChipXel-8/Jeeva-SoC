`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pragya_alu
// Target Checklist Item: 4.4 (Unit TB for ALU)
// Sign-Off Criteria:
//   - Matches golden reference model across all supported operations.
//   - Covers corner vectors: 0x8000_0000, 0x7FFF_FFFF, 0, -1.
//   - Covers shift amounts: 0, 1, 31, and >31.
//   - Validates signed vs. unsigned comparison semantics.
//   - Exercises unmapped ALU control opcodes to close branch coverage.
// =============================================================================

module tb_pragya_alu;

    // DUT Signals
    reg  [31:0] rs_1_in;
    reg  [31:0] rs_2_in;
    reg  [3:0]  alu_control;
    wire [31:0] alu_result_out;

    // Verification Tracking Counters
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate ALU DUT
    pragya_alu u_pragya_alu (
        .rs_1_in(rs_1_in),
        .rs_2_in(rs_2_in),
        .alu_control(alu_control),
        .alu_result_out(alu_result_out)
    );

    // =========================================================================
    // Golden Reference Model & Checker Task
    // =========================================================================
    task verify_alu(input [31:0] a, input [31:0] b, input [3:0] ctrl, input string desc);
        reg [31:0] expected_result;
        total_tests = total_tests + 1;

        rs_1_in     = a;
        rs_2_in     = b;
        alu_control = ctrl;
        #1; // Wait for combinational logic propagation

        // Reference Computation
        case (ctrl)
            4'd0: expected_result = a + b;
            4'd1: expected_result = a - b;
            4'd2: expected_result = a & b;
            4'd3: expected_result = a | b;
            4'd4: expected_result = a ^ b;
            4'd5: expected_result = a << b[4:0];
            4'd6: expected_result = a >> b[4:0];
            4'd7: expected_result = $signed(a) >>> b[4:0];
            4'd8: expected_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'd9: expected_result = (a < b) ? 32'd1 : 32'd0;
            default: expected_result = 32'd0;
        endcase

        // Verify Output
        if (alu_result_out !== expected_result) begin
            $display("[FAIL] %s | op=%0d A=0x%08h B=0x%08h -> Got: 0x%08h, Expected: 0x%08h",
                     desc, ctrl, a, b, alu_result_out, expected_result);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | op=%0d A=0x%08h B=0x%08h == 0x%08h",
                     desc, ctrl, a, b, alu_result_out);
        end
    endtask

    // Corner Constants
    localparam [31:0] ZERO    = 32'h0000_0000;
    localparam [31:0] MINUS_1 = 32'hFFFF_FFFF;
    localparam [31:0] MAX_POS = 32'h7FFF_FFFF; // +2,147,483,647
    localparam [31:0] MIN_NEG = 32'h8000_0000; // -2,147,483,648

    reg [31:0] corners [0:3] = '{ZERO, MINUS_1, MAX_POS, MIN_NEG};

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    initial begin
        rs_1_in     = 32'd0;
        rs_2_in     = 32'd0;
        alu_control = 4'd0;

        $display("\n=======================================================");
        $display("          STARTING PRAGYA ALU UNIT VERIFICATION        ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // Group 1: Explicit Arithmetic Overflow and Underflow Checks
        // -------------------------------------------------------------
        $display("--- [Group 1] ADD/SUB Boundary, Overflow & Underflow ---");
        // Positive Overflow: MAX_POS + 1 = MIN_NEG
        verify_alu(MAX_POS, 32'd1, 4'd0, "ADD Pos Overflow (MAX_POS + 1)");
        // Negative Overflow: MIN_NEG + (-1) = MAX_POS
        verify_alu(MIN_NEG, MINUS_1, 4'd0, "ADD Neg Overflow (MIN_NEG + -1)");
        // Signed Underflow: MIN_NEG - 1 = MAX_POS
        verify_alu(MIN_NEG, 32'd1, 4'd1, "SUB Underflow (MIN_NEG - 1)");
        // Self-Cancellation: MAX_POS - MAX_POS = 0
        verify_alu(MAX_POS, MAX_POS, 4'd1, "SUB Cancellation to Zero");
        // Zero Subtraction: 0 - 1 = -1
        verify_alu(ZERO, 32'd1, 4'd1, "SUB Underflow from Zero (0 - 1)");

        // -------------------------------------------------------------
        // Group 2: Exhaustive Corner-to-Corner Matrix (ADD, SUB, AND, OR, XOR)
        // -------------------------------------------------------------
        $display("\n--- [Group 2] 4x4 Corner Matrix on Arithmetic & Logic ---");
        for (int op = 0; op <= 4; op = op + 1) begin
            for (int i = 0; i < 4; i = i + 1) begin
                for (int j = 0; j < 4; j = j + 1) begin
                    verify_alu(corners[i], corners[j], op[3:0], "Corner-to-Corner Test");
                end
            end
        end

        // -------------------------------------------------------------
        // Group 3: Barrel Shifter Boundaries (0, 1, 31, and >31)
        // -------------------------------------------------------------
        $display("\n--- [Group 3] Shifter Shifts (0, 1, 31, and >31) ---");
        begin
            // 32 acts as 0 (32 & 5'h1F = 0), 33 acts as 1, 63 acts as 31
            reg [31:0] shift_amounts [0:5] = '{32'd0, 32'd1, 32'd31, 32'd32, 32'd33, 32'd63};
            
            for (int s = 0; s < 6; s = s + 1) begin
                // SLL (Shift Left Logical)
                verify_alu(32'h0000_0001, shift_amounts[s], 4'd5, "SLL Boundary");
                
                // SRL (Shift Right Logical)
                verify_alu(32'h8000_0000, shift_amounts[s], 4'd6, "SRL Boundary");
                
                // SRA on Negative Number (Must maintain sign-extension 1s)
                verify_alu(MIN_NEG, shift_amounts[s], 4'd7, "SRA Negative Sign-Extension");
                
                // SRA on Positive Number (Must insert 0s)
                verify_alu(MAX_POS, shift_amounts[s], 4'd7, "SRA Positive Zero-Fill");
            end
        end

        // -------------------------------------------------------------
        // Group 4: Signed (SLT) vs. Unsigned (SLTU) Comparison Checks
        // -------------------------------------------------------------
        $display("\n--- [Group 4] SLT / SLTU Corner Comparisons ---");
        // Case A: Negative vs Positive (-1 vs 1)
        // Signed: -1 < 1 is TRUE (1)
        // Unsigned: 0xFFFFFFFF < 1 is FALSE (0)
        verify_alu(MINUS_1, 32'd1, 4'd8, "SLT (-1 < 1) -> True");
        verify_alu(MINUS_1, 32'd1, 4'd9, "SLTU (0xFFFFFFFF < 1) -> False");

        // Case B: MIN_NEG vs MAX_POS (-2^31 vs 2^31-1)
        // Signed: MIN_NEG < MAX_POS is TRUE (1)
        // Unsigned: 0x80000000 < 0x7FFFFFFF is FALSE (0)
        verify_alu(MIN_NEG, MAX_POS, 4'd8, "SLT (MIN_NEG < MAX_POS) -> True");
        verify_alu(MIN_NEG, MAX_POS, 4'd9, "SLTU (MIN_NEG < MAX_POS) -> False");

        // Case C: Operands Equal
        verify_alu(MAX_POS, MAX_POS, 4'd8, "SLT Equal Operands -> False");
        verify_alu(MAX_POS, MAX_POS, 4'd9, "SLTU Equal Operands -> False");

        // Case D: Zero comparisons
        verify_alu(ZERO, MINUS_1, 4'd8, "SLT (0 < -1) -> False");
        verify_alu(ZERO, MINUS_1, 4'd9, "SLTU (0 < 0xFFFFFFFF) -> True");

        // -------------------------------------------------------------
        // Group 5: Unmapped Opcodes (Closure for Default Case Statement)
        // -------------------------------------------------------------
        $display("\n--- [Group 5] Unmapped ALU Control Opcodes (Default Branch Closure) ---");
        for (int unmapped_ctrl = 10; unmapped_ctrl <= 15; unmapped_ctrl = unmapped_ctrl + 1) begin
            verify_alu(32'h1234_5678, 32'h9ABC_DEF0, unmapped_ctrl[3:0], "Unmapped Opcode Fallback");
        end

        // -------------------------------------------------------------
        // Summary & Sign-off Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.4)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
