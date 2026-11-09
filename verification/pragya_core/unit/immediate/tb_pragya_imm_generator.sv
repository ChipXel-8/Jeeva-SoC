`timescale 1ns / 1ps

module tb_pragya_imm_generator;

    // DUT Signals
    reg  [31:7] imm_gen_in;
    reg  [2:0]  imm_src;
    wire [31:0] imm_out;

    // Pass / Fail Counters
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_imm_generator u_dut (
        .imm_gen_in(imm_gen_in),
        .imm_src(imm_src),
        .imm_out(imm_out)
    );

    // Simple Verification Task
    task test_instruction(
        input [31:0] full_instruction,
        input [2:0]  format_type,
        input [31:0] expected_imm,
        input string test_name
    );
        total_tests = total_tests + 1;

        // Feed bits [31:7] of the instruction into the module
        imm_gen_in = full_instruction[31:7];
        imm_src    = format_type;
        #1; // Wait 1ns for combinational output to settle

        if (imm_out !== expected_imm) begin
            $display("[FAIL] %s | Got: 0x%08h, Expected: 0x%08h", test_name, imm_out, expected_imm);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Extracted: %0d (0x%08h)", test_name, $signed(imm_out), imm_out);
        end
    endtask

    // Instruction Type Constants (from decoder)
    localparam [2:0] IMM_I = 3'b000;
    localparam [2:0] IMM_S = 3'b010;
    localparam [2:0] IMM_B = 3'b011;
    localparam [2:0] IMM_U = 3'b100;
    localparam [2:0] IMM_J = 3'b101;

    initial begin
        imm_gen_in = 25'd0;
        imm_src    = 3'd0;

        $display("Starting Pragya Immediate Generator Verification...");

        // =============================================================
        // 1. I-TYPE INSTRUCTIONS (e.g., ADDI, LW)
        // =============================================================
        test_instruction(32'h00A08113, IMM_I, 32'd10, "I-type: addi +10");
        test_instruction(32'hFFB08113, IMM_I, -32'd5, "I-type: addi -5");
        test_instruction(32'h7FF08113, IMM_I, 32'd2047, "I-type: Max positive (+2047)");
        test_instruction(32'h80008113, IMM_I, -32'd2048, "I-type: Min negative (-2048)");

        // =============================================================
        // 2. S-TYPE INSTRUCTIONS (e.g., SW, SB)
        // =============================================================
        test_instruction(32'h0020A823, IMM_S, 32'd16, "S-type: sw +16");
        test_instruction(32'hFE20AA23, IMM_S, -32'd12, "S-type: sw -12");
        test_instruction(32'h7E20AFA3, IMM_S, 32'd2047, "S-type: Max positive (+2047)");
        test_instruction(32'h80208023, IMM_S, -32'd2048, "S-type: Min negative (-2048)");

        // =============================================================
        // 3. B-TYPE INSTRUCTIONS (e.g., BEQ, BNE)
        // =============================================================
        test_instruction(32'h00208463, IMM_B, 32'd8, "B-type: beq +8");
        test_instruction(32'hFE208CE3, IMM_B, -32'd8, "B-type: beq -8");
        test_instruction(32'h7E208FE3, IMM_B, 32'd4094, "B-type: Max positive (+4094)");
        test_instruction(32'h80208063, IMM_B, -32'd4096, "B-type: Min negative (-4096)");

        // =============================================================
        // 4. U-TYPE INSTRUCTIONS (e.g., LUI, AUIPC)
        // =============================================================
        test_instruction(32'h123450B7, IMM_U, 32'h1234_5000, "U-type: lui 0x12345");
        test_instruction(32'hFFFFF0B7, IMM_U, 32'hFFFF_F000, "U-type: Max lui (0xFFFFF000)");
        test_instruction(32'h000010B7, IMM_U, 32'h0000_1000, "U-type: Min lui (0x00001000)");

        // =============================================================
        // 5. J-TYPE INSTRUCTIONS (e.g., JAL)
        // =============================================================
        test_instruction(32'h064000EF, IMM_J, 32'd100, "J-type: jal +100");
        test_instruction(32'hF9DFF0EF, IMM_J, -32'd100, "J-type: jal -100");
        test_instruction(32'h7FFFF0EF, IMM_J, 32'd1048574, "J-type: Max positive jump");
        test_instruction(32'h800000EF, IMM_J, -32'd1048576, "J-type: Min negative jump");

        // =============================================================
        // 6. DEFAULT / FALLBACK BRANCH COVERAGE
        // =============================================================
        test_instruction(32'h00A08113, 3'b110, 32'd10, "Default case (3'b110): fallback to I-type");
        test_instruction(32'h00A08113, 3'b111, 32'd10, "Default case (3'b111): fallback to I-type");

        // =============================================================
        // SUMMARY
        // =============================================================
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule