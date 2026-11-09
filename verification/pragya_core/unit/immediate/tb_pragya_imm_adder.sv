`timescale 1ns / 1ps

module tb_pragya_imm_adder;

    // DUT Signals
    reg  [31:0] pc_in;
    reg  [31:0] rs_1_in;
    reg  [31:0] imm_in;
    reg         i_adder_src_in;
    reg         jalr_in;
    wire [31:0] i_adder_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate Immediate Adder DUT
    pragya_imm_adder u_dut (
        .pc_in(pc_in),
        .rs_1_in(rs_1_in),
        .imm_in(imm_in),
        .i_adder_src_in(i_adder_src_in),
        .jalr_in(jalr_in),
        .i_adder_out(i_adder_out)
    );

    // Self-checking verification task
    task check_adder(
        input [31:0] pc_val,
        input [31:0] rs1_val,
        input [31:0] imm_val,
        input        src_sel,
        input        jalr_en,
        input [31:0] exp_out,
        input string desc
    );
        total_tests = total_tests + 1;
        pc_in          = pc_val;
        rs_1_in        = rs1_val;
        imm_in         = imm_val;
        i_adder_src_in = src_sel;
        jalr_in        = jalr_en;
        #1; // Combinational propagation delay

        if (i_adder_out !== exp_out) begin
            $display("[FAIL] %s | src=%b jalr=%b pc=0x%08h rs1=0x%08h imm=0x%08h -> Got: 0x%08h, Exp: 0x%08h",
                     desc, src_sel, jalr_en, pc_val, rs1_val, imm_val, i_adder_out, exp_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Out: 0x%08h", desc, i_adder_out);
        end
    endtask

    // Corner Constants
    localparam [31:0] ZERO    = 32'h0000_0000;
    localparam [31:0] MINUS_1 = 32'hFFFF_FFFF;
    localparam [31:0] MAX_POS = 32'h7FFF_FFFF;
    localparam [31:0] MIN_NEG = 32'h8000_0000;

    initial begin
        pc_in          = 32'd0;
        rs_1_in        = 32'd0;
        imm_in         = 32'd0;
        i_adder_src_in = 1'b0;
        jalr_in        = 1'b0;

        $display("Starting Pragya Immediate Adder Verification...");

        // -------------------------------------------------------------
        // Group 1: Base Multiplexer Routing (PC vs RS1 Selection)
        // -------------------------------------------------------------
        // Select PC (PC-relative: JAL / Branches)
        check_adder(32'h0001_0000, 32'hDEAD_BEEF, 32'h0000_0020, 1'b0, 1'b0, 32'h0001_0020, "Select PC (pc + imm)");

        // Select RS1 (Register-indirect: JALR)
        check_adder(32'hDEAD_BEEF, 32'h2000_0000, 32'h0000_0040, 1'b1, 1'b0, 32'h2000_0040, "Select RS1 (rs1 + imm)");

        // -------------------------------------------------------------
        // Group 2: Unselected Input Isolation
        // -------------------------------------------------------------
        // When src=0 (using PC), modifying rs1 must not affect output
        check_adder(32'h0000_1000, 32'h0000_0000, 32'h0000_0004, 1'b0, 1'b0, 32'h0000_1004, "Isolation: rs1=0 when src=0");
        check_adder(32'h0000_1000, 32'hFFFF_FFFF, 32'h0000_0004, 1'b0, 1'b0, 32'h0000_1004, "Isolation: rs1=FFFFFFFF when src=0");

        // When src=1 (using RS1), modifying PC must not affect output
        check_adder(32'h0000_0000, 32'h0000_2000, 32'h0000_0008, 1'b1, 1'b0, 32'h0000_2008, "Isolation: pc=0 when src=1");
        check_adder(32'hFFFF_FFFF, 32'h0000_2000, 32'h0000_0008, 1'b1, 1'b0, 32'h0000_2008, "Isolation: pc=FFFFFFFF when src=1");

        // -------------------------------------------------------------
        // Group 3: JALR LSB Masking (bit 0 clearing)
        // -------------------------------------------------------------
        // Odd sum with jalr_in = 1 -> Bit 0 cleared
        check_adder(ZERO, 32'h1000_0001, 32'h0000_0002, 1'b1, 1'b1, 32'h1000_0002, "JALR: (0x10000001 + 2) & ~1 -> 0x10000002");
        check_adder(ZERO, 32'h1000_0000, 32'h0000_0003, 1'b1, 1'b1, 32'h1000_0002, "JALR: (0x10000000 + 3) & ~1 -> 0x10000002");

        // Odd sum with jalr_in = 0 -> Bit 0 preserved
        check_adder(ZERO, 32'h1000_0001, 32'h0000_0002, 1'b1, 1'b0, 32'h1000_0003, "No JALR: Odd sum passes unchanged (0x10000003)");

        // Even sum with jalr_in = 1 -> Bit 0 remains 0
        check_adder(ZERO, 32'h1000_0000, 32'h0000_0004, 1'b1, 1'b1, 32'h1000_0004, "JALR: Even sum remains even (0x10000004)");

        // JALR masking with all 1s sum
        check_adder(ZERO, MINUS_1, ZERO, 1'b1, 1'b1, 32'hFFFF_FFFE, "JALR: 0xFFFFFFFF & ~1 -> 0xFFFFFFFE");

        // -------------------------------------------------------------
        // Group 4: 32-Bit Arithmetic Extremes, Overflows & Underflows
        // -------------------------------------------------------------
        // Positive overflow: 0x7FFFFFFF + 1 -> 0x80000000
        check_adder(MAX_POS, ZERO, 32'd1, 1'b0, 1'b0, MIN_NEG, "Arithmetic: Max Pos + 1 = Min Neg");

        // Unsigned address space wrap-around: 0xFFFFFFFC + 0x8 -> 0x00000004
        check_adder(32'hFFFF_FFFC, ZERO, 32'h0000_0008, 1'b0, 1'b0, 32'h0000_0004, "Arithmetic: 32-bit Address Wrap-Around");

        // Backward branch / Negative immediate: 0x00010020 + (-32)
        check_adder(32'h0001_0020, ZERO, -32'd32, 1'b0, 1'b0, 32'h0001_0000, "Arithmetic: Backward Jump (pc - 32)");

        // Underflow below zero: 0x00000004 + (-8) -> 0xFFFFFFFC
        check_adder(32'h0000_0004, ZERO, -32'd8, 1'b0, 1'b0, 32'hFFFF_FFFC, "Arithmetic: Underflow wrap below zero");

        // Cancellation to zero: 0x12345678 + (-0x12345678)
        check_adder(32'h1234_5678, ZERO, -32'h1234_5678, 1'b0, 1'b0, ZERO, "Arithmetic: Self-cancellation to zero");

        // -------------------------------------------------------------
        // Group 5: Alternating Pattern Vectors (0x55555555 & 0xAAAAAAAA)
        // -------------------------------------------------------------
        check_adder(32'h5555_5555, ZERO, 32'h0000_0000, 1'b0, 1'b0, 32'h5555_5555, "Pattern: 0x55555555 on PC");
        check_adder(ZERO, 32'hAAAA_AAAA, 32'h0000_0000, 1'b1, 1'b0, 32'hAAAA_AAAA, "Pattern: 0xAAAAAAAA on RS1");
        check_adder(ZERO, ZERO, 32'h5555_5555, 1'b0, 1'b0, 32'h5555_5555, "Pattern: 0x55555555 on IMM");
        check_adder(32'h5555_5555, ZERO, 32'hAAAA_AAAA, 1'b0, 1'b0, MINUS_1, "Pattern: 0x55555555 + 0xAAAAAAAA = 0xFFFFFFFF");

        // -------------------------------------------------------------
        // Group 6: Walking 1s for Full Toggle Coverage
        // -------------------------------------------------------------
        for (int b = 0; b < 32; b = b + 1) begin
            // Walking 1 on PC
            check_adder((32'h1 << b), ZERO, ZERO, 1'b0, 1'b0, (32'h1 << b), "Walking 1 on PC");

            // Walking 1 on RS1
            check_adder(ZERO, (32'h1 << b), ZERO, 1'b1, 1'b0, (32'h1 << b), "Walking 1 on RS1");

            // Walking 1 on IMM
            check_adder(ZERO, ZERO, (32'h1 << b), 1'b0, 1'b0, (32'h1 << b), "Walking 1 on IMM");
        end

        // -------------------------------------------------------------
        // Summary Verdict
        // -------------------------------------------------------------
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