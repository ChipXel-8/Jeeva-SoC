`timescale 1ns / 1ps

module tb_pragya_alu_mux;

    // DUT Signals
    reg  [31:0] rs_2_in;
    reg  [31:0] imm_in;
    reg         alu_src_in;
    wire [31:0] op_2_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_alu_mux u_dut (
        .rs_2_in(rs_2_in),
        .imm_in(imm_in),
        .alu_src_in(alu_src_in),
        .op_2_out(op_2_out)
    );

    // Self-checking verification task
    task check_mux(
        input [31:0] rs2_val,
        input [31:0] imm_val,
        input        sel,
        input [31:0] exp_out,
        input string desc
    );
        total_tests = total_tests + 1;
        rs_2_in    = rs2_val;
        imm_in     = imm_val;
        alu_src_in = sel;
        #1; // Combinational propagation delay

        if (op_2_out !== exp_out) begin
            $display("[FAIL] %s | sel=%b rs2=0x%08h imm=0x%08h -> Got: 0x%08h, Expected: 0x%08h",
                     desc, sel, rs2_val, imm_val, op_2_out, exp_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | sel=%b -> Out: 0x%08h", desc, sel, op_2_out);
        end
    endtask

    initial begin
        rs_2_in    = 32'd0;
        imm_in     = 32'd0;
        alu_src_in = 1'b0;

        $display("Starting Pragya ALU Mux Verification...");

        // -------------------------------------------------------------
        // Group 1: Basic Path Selection (R-type vs I-type)
        // -------------------------------------------------------------
        // sel = 0 -> rs_2_in selected
        check_mux(32'hDEAD_BEEF, 32'h1234_5678, 1'b0, 32'hDEAD_BEEF, "Select rs_2_in (sel=0)");

        // sel = 1 -> imm_in selected
        check_mux(32'hDEAD_BEEF, 32'h1234_5678, 1'b1, 32'h1234_5678, "Select imm_in (sel=1)");

        // -------------------------------------------------------------
        // Group 2: Unselected Input Isolation (Glitch / Don't Care Check)
        // -------------------------------------------------------------
        // When sel=0, modifying imm_in must NOT alter output
        check_mux(32'hCAFE_BABE, 32'h0000_0000, 1'b0, 32'hCAFE_BABE, "Isolation: imm=0 when sel=0");
        check_mux(32'hCAFE_BABE, 32'hFFFF_FFFF, 1'b0, 32'hCAFE_BABE, "Isolation: imm=FFFFFFFF when sel=0");

        // When sel=1, modifying rs_2_in must NOT alter output
        check_mux(32'h0000_0000, 32'hBAAD_F00D, 1'b1, 32'hBAAD_F00D, "Isolation: rs2=0 when sel=1");
        check_mux(32'hFFFF_FFFF, 32'hBAAD_F00D, 1'b1, 32'hBAAD_F00D, "Isolation: rs2=FFFFFFFF when sel=1");

        // -------------------------------------------------------------
        // Group 3: Extreme Data Vector Boundaries
        // -------------------------------------------------------------
        // All zeros
        check_mux(32'h0000_0000, 32'hFFFF_FFFF, 1'b0, 32'h0000_0000, "Boundary: All 0s on rs2");
        check_mux(32'hFFFF_FFFF, 32'h0000_0000, 1'b1, 32'h0000_0000, "Boundary: All 0s on imm");

        // All ones
        check_mux(32'hFFFF_FFFF, 32'h0000_0000, 1'b0, 32'hFFFF_FFFF, "Boundary: All 1s on rs2");
        check_mux(32'h0000_0000, 32'hFFFF_FFFF, 1'b1, 32'hFFFF_FFFF, "Boundary: All 1s on imm");

        // Alternating patterns (0x55555555 and 0xAAAAAAAA)
        check_mux(32'h5555_5555, 32'hAAAA_AAAA, 1'b0, 32'h5555_5555, "Alternating: 0x55555555 on rs2");
        check_mux(32'h5555_5555, 32'hAAAA_AAAA, 1'b1, 32'hAAAA_AAAA, "Alternating: 0xAAAAAAAA on imm");

        // -------------------------------------------------------------
        // Group 4: Walking 1s for Full 32-bit Toggle Closure
        // -------------------------------------------------------------
        for (int b = 0; b < 32; b = b + 1) begin
            // Walk 1 through rs_2_in while sel=0
            check_mux((32'h1 << b), 32'h0000_0000, 1'b0, (32'h1 << b), "Walking 1 on rs2");

            // Walk 1 through imm_in while sel=1
            check_mux(32'h0000_0000, (32'h1 << b), 1'b1, (32'h1 << b), "Walking 1 on imm");
        end

        // -------------------------------------------------------------
        // Summary & Verdict
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