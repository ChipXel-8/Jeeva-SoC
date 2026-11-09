`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pragya_regfile
// Target Checklist Item: 4.3 (Unit TB for Register File)
// Verification Scope:
//   - Architectural invariance of x0 hardwired zero (write-suppression)
//   - Dual-port simultaneous read independence across all 32 registers
//   - Same-cycle read/write hazard timing (RAW boundary verification)
//   - Write-enable gating deassertion
//   - Full toggle closure via walking 1s and walking 0s
// =============================================================================

module tb_pragya_regfile;

    // DUT Interface Signals
    reg         clk_in;
    reg         rst_in;
    reg         reg_write_in;
    reg  [4:0]  rs_1_addrs_in;
    reg  [4:0]  rs_2_addrs_in;
    reg  [4:0]  rd_addrs_in;
    reg  [31:0] wb_mux_in;

    wire [31:0] rs_1_out;
    wire [31:0] rs_2_out;

    // Test Tracking Counters
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate Register File DUT
    pragya_regfile u_pragya_regfile (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .reg_write_in(reg_write_in),
        .rs_1_addrs_in(rs_1_addrs_in),
        .rs_2_addrs_in(rs_2_addrs_in),
        .rd_addrs_in(rd_addrs_in),
        .wb_mux_in(wb_mux_in),
        .rs_1_out(rs_1_out),
        .rs_2_out(rs_2_out)
    );

    // 100MHz Simulation Clock (5ns Period Half-Cycle)
    always #5 clk_in = ~clk_in;

    // =========================================================================
    // Self-Checking Verification Tasks
    // =========================================================================
    
    // Synchronous Register Write
    task write_reg(input [4:0] rd, input [31:0] data);
        @(negedge clk_in);
        reg_write_in = 1'b1;
        rd_addrs_in  = rd;
        wb_mux_in    = data;
        @(posedge clk_in);
        #1;
        reg_write_in = 1'b0;
    endtask

    // Check Single Port RS1
    task check_rs1(input [4:0] reg_addr, input [31:0] exp_data, input string desc);
        total_tests = total_tests + 1;
        rs_1_addrs_in = reg_addr;
        #1;
        if (rs_1_out !== exp_data) begin
            $display("[FAIL] %s | RS1 (x%0d) -> Expected: 0x%08h, Got: 0x%08h", desc, reg_addr, exp_data, rs_1_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | RS1 (x%0d) == 0x%08h", desc, reg_addr, rs_1_out);
        end
    endtask

    // Check Single Port RS2
    task check_rs2(input [4:0] reg_addr, input [31:0] exp_data, input string desc);
        total_tests = total_tests + 1;
        rs_2_addrs_in = reg_addr;
        #1;
        if (rs_2_out !== exp_data) begin
            $display("[FAIL] %s | RS2 (x%0d) -> Expected: 0x%08h, Got: 0x%08h", desc, reg_addr, exp_data, rs_2_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | RS2 (x%0d) == 0x%08h", desc, reg_addr, rs_2_out);
        end
    endtask

    // Dual-Port Concurrent Verification
    task check_both(input [4:0] r1, input [31:0] exp1, input [4:0] r2, input [31:0] exp2, input string desc);
        total_tests = total_tests + 2;
        rs_1_addrs_in = r1;
        rs_2_addrs_in = r2;
        #1;
        if (rs_1_out !== exp1) begin
            $display("[FAIL] %s | Dual RS1 (x%0d) -> Expected: 0x%08h, Got: 0x%08h", desc, r1, exp1, rs_1_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Dual RS1 (x%0d) == 0x%08h", desc, r1, rs_1_out);
        end

        if (rs_2_out !== exp2) begin
            $display("[FAIL] %s | Dual RS2 (x%0d) -> Expected: 0x%08h, Got: 0x%08h", desc, r2, exp2, rs_2_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Dual RS2 (x%0d) == 0x%08h", desc, r2, rs_2_out);
        end
    endtask

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    initial begin
        clk_in        = 1'b0;
        rst_in        = 1'b1;
        reg_write_in  = 1'b0;
        rs_1_addrs_in = 5'd0;
        rs_2_addrs_in = 5'd0;
        rd_addrs_in   = 5'd0;
        wb_mux_in     = 32'h0000_0000;

        $display("\n=======================================================");
        $display("     STARTING PRAGYA REGFILE VERIFICATION SUITE       ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // Group 1: Reset & Asynchronous Initialization
        // -------------------------------------------------------------
        $display("--- [Group 1] Reset & Initial State ---");
        #20;
        @(posedge clk_in);
        check_both(5'd0, 32'h0, 5'd1, 32'h0, "Reset verification (x0 & x1)");
        check_both(5'd16, 32'h0, 5'd31, 32'h0, "Reset verification (x16 & x31)");
        rst_in = 1'b0;
        @(posedge clk_in);
        #1;

        // -------------------------------------------------------------
        // Group 2: Register x0 Constant Zero & Write Invariance
        // -------------------------------------------------------------
        $display("\n--- [Group 2] x0 Constant Zero & Write-Suppression ---");
        write_reg(5'd0, 32'hDEAD_BEEF);
        check_both(5'd0, 32'h0000_0000, 5'd0, 32'h0000_0000, "x0 invariant after writing 0xDEADBEEF");

        write_reg(5'd0, 32'hFFFF_FFFF);
        check_both(5'd0, 32'h0000_0000, 5'd0, 32'h0000_0000, "x0 invariant after writing 0xFFFFFFFF");

        write_reg(5'd0, 32'h1234_5678);
        check_both(5'd0, 32'h0000_0000, 5'd0, 32'h0000_0000, "x0 invariant after writing 0x12345678");

        // -------------------------------------------------------------
        // Group 3: Sequential Fill and Dual-Port Read Independence
        // -------------------------------------------------------------
        $display("\n--- [Group 3] Sequential Write & Cross-Coupled Dual Read ---");
        for (int r = 1; r < 32; r = r + 1) begin
            write_reg(r[4:0], 32'hCAFE_0000 + (r << 8) + r);
        end

        for (int r = 1; r < 32; r = r + 1) begin
            int r2 = 32 - r;
            check_both(r[4:0],  32'hCAFE_0000 + (r << 8) + r,
                       r2[4:0], 32'hCAFE_0000 + (r2 << 8) + r2,
                       "Independent dual-port read");
        end

        // -------------------------------------------------------------
        // Group 4: Same-Cycle Read / Write Hazards (RAW Bypass Timing)
        // -------------------------------------------------------------
        $display("\n--- [Group 4] Same-Cycle Read/Write Timing Hazards ---");
        write_reg(5'd5, 32'h1111_2222);

        @(negedge clk_in);
        rd_addrs_in   = 5'd5;
        wb_mux_in     = 32'h9999_8888;
        reg_write_in  = 1'b1;
        rs_1_addrs_in = 5'd5;
        rs_2_addrs_in = 5'd5;
        #1;
        check_both(5'd5, 32'h1111_2222, 5'd5, 32'h1111_2222, "Before posedge: Read old value");

        @(posedge clk_in);
        #1;
        check_both(5'd5, 32'h9999_8888, 5'd5, 32'h9999_8888, "After posedge: Read new value");
        reg_write_in = 1'b0;

        // -------------------------------------------------------------
        // Group 5: Write-Enable Deassertion Gating
        // -------------------------------------------------------------
        $display("\n--- [Group 5] Write-Enable Deassertion Gating Check ---");
        @(negedge clk_in);
        reg_write_in = 1'b0;
        rd_addrs_in  = 5'd7;
        wb_mux_in    = 32'hFACE_FEED;
        @(posedge clk_in);
        #1;
        check_rs1(5'd7, 32'hCAFE_0000 + (7 << 8) + 7, "Register x7 unchanged when reg_write_in=0");

        // -------------------------------------------------------------
        // Group 6: Boundary Registers & Alternating Bit Patterns
        // -------------------------------------------------------------
        $display("\n--- [Group 6] Register Boundaries & Alternating Patterns ---");
        write_reg(5'd1, 32'h5555_5555);
        check_rs1(5'd1, 32'h5555_5555, "Boundary x1 with 0x55555555");

        write_reg(5'd1, 32'hAAAA_AAAA);
        check_rs1(5'd1, 32'hAAAA_AAAA, "Boundary x1 with 0xAAAAAAAA");

        write_reg(5'd30, 32'h5555_5555);
        check_rs2(5'd30, 32'h5555_5555, "Boundary x30 with 0x55555555");

        write_reg(5'd31, 32'hAAAA_AAAA);
        check_rs2(5'd31, 32'hAAAA_AAAA, "Boundary x31 with 0xAAAAAAAA");

        write_reg(5'd31, 32'hFFFF_FFFF);
        check_rs2(5'd31, 32'hFFFF_FFFF, "Boundary x31 with all 1s (0xFFFFFFFF)");

        write_reg(5'd31, 32'h0000_0000);
        check_rs2(5'd31, 32'h0000_0000, "Boundary x31 with all 0s (0x00000000)");

        // -------------------------------------------------------------
        // Group 7: Walking 1s & Walking 0s Toggle Stress
        // -------------------------------------------------------------
        $display("\n--- [Group 7] Walking 1s & Walking 0s Toggle Stress ---");
        for (int b = 0; b < 32; b = b + 1) begin
            write_reg(5'd10, (32'h1 << b));
            check_rs1(5'd10, (32'h1 << b), "Walking 1s check on x10");
        end

        for (int b = 0; b < 32; b = b + 1) begin
            write_reg(5'd11, ~(32'h1 << b));
            check_rs2(5'd11, ~(32'h1 << b), "Walking 0s check on x11");
        end

        // -------------------------------------------------------------
        // Group 8: Mid-Execution Asynchronous Reset Flush
        // -------------------------------------------------------------
        $display("\n--- [Group 8] Mid-Execution Asynchronous Reset Flush ---");
        @(negedge clk_in);
        rst_in = 1'b1;
        #1;
        check_both(5'd1, 32'h0000_0000, 5'd31, 32'h0000_0000, "Async reset immediately flushes outputs");
        @(posedge clk_in);
        rst_in = 1'b0;
        #1;
        check_both(5'd10, 32'h0000_0000, 5'd11, 32'h0000_0000, "Post-reset verification of x10 and x11");

        // -------------------------------------------------------------
        // Summary & Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.3)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
