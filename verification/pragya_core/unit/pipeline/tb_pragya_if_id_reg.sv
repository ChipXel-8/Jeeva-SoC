`timescale 1ns / 1ps

module tb_pragya_if_id_reg;

    // Clock and Reset
    reg clk;
    reg rst;

    // Pipeline Inputs
    reg [31:0] pc_mux_in;
    reg [31:0] pc_plus_4_pipline1_in;
    reg [31:0] if_instr;
    reg        if_valid;
    reg        stall_d;
    reg        flush;

    // DUT Outputs
    wire [31:0] pc_out;
    wire [31:0] pc_plus_4_pipline1_out;
    wire [31:0] id_instr;
    wire        id_valid;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_if_id_reg u_dut (
        .clk_in(clk),
        .rst_in(rst),
        .pc_mux_in(pc_mux_in),
        .pc_plus_4_pipline1_in(pc_plus_4_pipline1_in),
        .if_instr(if_instr),
        .if_valid(if_valid),
        .stall_d(stall_d),
        .flush(flush),
        .pc_out(pc_out),
        .pc_plus_4_pipline1_out(pc_plus_4_pipline1_out),
        .id_instr(id_instr),
        .id_valid(id_valid)
    );

    // 100MHz Clock (10ns Period)
    always #5 clk = ~clk;

    localparam [31:0] NOP_INSTR = 32'h00000013; // addi x0, x0, 0

    // =========================================================================
    // Helper Tasks
    // =========================================================================
    task clear_inputs();
        pc_mux_in              = 32'd0;
        pc_plus_4_pipline1_in  = 32'd0;
        if_instr               = 32'd0;
        if_valid               = 1'b0;
        stall_d                = 1'b0;
        flush                  = 1'b0;
    endtask

    task check_cleared(input string desc);
        total_tests = total_tests + 1;
        #1;
        if (pc_out !== 32'd0 || pc_plus_4_pipline1_out !== 32'd0 || id_valid !== 1'b0) begin
            $display("[FAIL] %s | Expected cleared pipeline regs, got: pc=0x%08h valid=%b",
                     desc, pc_out, id_valid);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Pipeline outputs cleared to zero", desc);
        end
    endtask

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        clear_inputs();

        $display("Starting Pragya IF/ID Pipeline Register Verification...");

        // -------------------------------------------------------------
        // Group 1: Power-On Reset & Initial Conditions
        // -------------------------------------------------------------
        #20;
        check_cleared("Async Reset Active Check");
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        #1;
        check_cleared("Post-Reset Initial State Check");

        // -------------------------------------------------------------
        // Group 2: Normal Instruction Flow (Steady State)
        // -------------------------------------------------------------
        @(negedge clk);
        if_valid              = 1'b1;
        stall_d               = 1'b0;
        flush                 = 1'b0;
        pc_mux_in             = 32'h0001_0000;
        pc_plus_4_pipline1_in = 32'h0001_0004;
        if_instr              = 32'h00A08113; // addi sp, ra, 10

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_out === 32'h0001_0000 &&
            pc_plus_4_pipline1_out === 32'h0001_0004 &&
            id_valid === 1'b1 &&
            id_instr === 32'h00A08113) begin
            $display("[PASS] Normal Fetch Flow: Instruction and PC latched intact");
        end else begin
            $display("[FAIL] Normal Fetch Flow Mismatch! pc=0x%08h instr=0x%08h valid=%b",
                     pc_out, id_instr, id_valid);
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 3: Bubble Insertion (if_valid = 0)
        // -------------------------------------------------------------
        @(negedge clk);
        if_valid  = 1'b0;
        pc_mux_in = 32'h0001_0008;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (id_valid === 1'b0) begin
            $display("[PASS] Bubble Insertion: id_valid pulled low when if_valid=0");
        end else begin
            $display("[FAIL] Bubble Insertion Failed! id_valid remained high");
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 4: Pipeline Stall (stall_d = 1)
        // -------------------------------------------------------------
        // First load a known instruction
        @(negedge clk);
        if_valid              = 1'b1;
        pc_mux_in             = 32'h0001_0010;
        pc_plus_4_pipline1_in = 32'h0001_0014;
        if_instr              = 32'h002081B3; // add x3, x1, x2
        @(posedge clk);
        #1;

        // Assert stall_d and present new data
        @(negedge clk);
        stall_d               = 1'b1;
        pc_mux_in             = 32'hDEAD_BEEF;
        pc_plus_4_pipline1_in = 32'hBAAD_F00D;
        if_instr              = 32'h1234_5678;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        // Registers must freeze and preserve 0x0001_0010
        if (pc_out === 32'h0001_0010 &&
            pc_plus_4_pipline1_out === 32'h0001_0014 &&
            id_valid === 1'b1) begin
            $display("[PASS] Stall Freeze: Registers held their previous values");
        end else begin
            $display("[FAIL] Stall Freeze Failed! pc=0x%08h", pc_out);
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 5: Stall Shadow / was_stall NOP Insertion
        // -------------------------------------------------------------
        // Release stall
        @(negedge clk);
        stall_d  = 1'b0;
        if_instr = 32'hA5A5_5A5A;

        // In this cycle, was_stall is 1, so id_instr must force NOP (32'h00000013)
        #1;
        total_tests = total_tests + 1;
        if (id_instr === NOP_INSTR) begin
            $display("[PASS] Post-Stall Shadow: id_instr substituted with NOP (0x00000013)");
        end else begin
            $display("[FAIL] Post-Stall Shadow Failed! Expected NOP, got 0x%08h", id_instr);
            failed_tests = failed_tests + 1;
        end

        @(posedge clk);
        #1;
        // Next cycle: was_stall drops back to 0, if_instr is passed through directly
        total_tests = total_tests + 1;
        if (id_instr === 32'hA5A5_5A5A) begin
            $display("[PASS] Post-Stall Recovery: id_instr restored to if_instr");
        end else begin
            $display("[FAIL] Post-Stall Recovery Failed! Expected 0xA5A55A5A, got 0x%08h", id_instr);
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 6: Flush & drop_next_instr Logic
        // -------------------------------------------------------------
        // 1. Assert flush
        @(negedge clk);
        flush    = 1'b1;
        stall_d  = 1'b0;
        if_valid = 1'b1;
        if_instr = 32'hCAFE_BABE;

        @(posedge clk);
        #1;
        check_cleared("Synchronous Flush Execution");

        // 2. Cycle right after flush: drop_next_instr should be 1
        total_tests = total_tests + 1;
        if (id_instr === NOP_INSTR) begin
            $display("[PASS] Flush Shadow: drop_next_instr replaced squashed instruction with NOP");
        end else begin
            $display("[FAIL] Flush Shadow Failed! Expected NOP, got 0x%08h", id_instr);
            failed_tests = failed_tests + 1;
        end

        // 3. Deassert flush and return to normal
        @(negedge clk);
        flush    = 1'b0;
        if_instr = 32'h1122_3344;
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (id_instr === 32'h1122_3344) begin
            $display("[PASS] Post-Flush Recovery: Instruction passes normally");
        end else begin
            $display("[FAIL] Post-Flush Recovery Failed! Expected 0x11223344, got 0x%08h", id_instr);
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 7: Flush Dominance over Stall (flush && stall_d)
        // -------------------------------------------------------------
        @(negedge clk);
        flush                 = 1'b1;
        stall_d               = 1'b1;
        if_valid              = 1'b1;
        pc_mux_in             = 32'h1234_5678;
        pc_plus_4_pipline1_in = 32'h1234_567C;

        @(posedge clk);
        #1;
        check_cleared("Flush Priority: Flush clears outputs even when stall is asserted");

        // Note: drop_next_instr only sets if (flush && !stall_d).
        // Since stall_d was 1, drop_next_instr must NOT have set.
        flush   = 1'b0;
        stall_d = 1'b0;

        // -------------------------------------------------------------
        // Group 8: Boundary Values & Toggle Coverage Closure
        // -------------------------------------------------------------
        // Pattern 1: Alternating 0x55555555
        @(negedge clk);
        if_valid              = 1'b1;
        pc_mux_in             = 32'h5555_5554;
        pc_plus_4_pipline1_in = 32'h5555_5558;
        if_instr              = 32'h5555_5555;
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_out === 32'h5555_5554 && id_instr === 32'h5555_5555) begin
            $display("[PASS] Pattern 0x55555555 Latched");
        end else begin
            $display("[FAIL] Pattern 0x55555555 Mismatch!");
            failed_tests = failed_tests + 1;
        end

        // Pattern 2: Alternating 0xAAAAAAAA
        @(negedge clk);
        if_valid              = 1'b1;
        pc_mux_in             = 32'hAAAA_AAA8;
        pc_plus_4_pipline1_in = 32'hAAAA_AAAC;
        if_instr              = 32'hAAAA_AAAA;
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_out === 32'hAAAA_AAA8 && id_instr === 32'hAAAA_AAAA) begin
            $display("[PASS] Pattern 0xAAAAAAAA Latched");
        end else begin
            $display("[FAIL] Pattern 0xAAAAAAAA Mismatch!");
            failed_tests = failed_tests + 1;
        end

        // Pattern 3: All-Ones 0xFFFFFFFF
        @(negedge clk);
        if_valid              = 1'b1;
        pc_mux_in             = 32'hFFFF_FFFC;
        pc_plus_4_pipline1_in = 32'h0000_0000;
        if_instr              = 32'hFFFF_FFFF;
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_out === 32'hFFFF_FFFC && id_instr === 32'hFFFF_FFFF) begin
            $display("[PASS] Pattern 0xFFFFFFFF Latched");
        end else begin
            $display("[FAIL] Pattern 0xFFFFFFFF Mismatch!");
            failed_tests = failed_tests + 1;
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