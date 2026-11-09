`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pragya_hazard_unit
// Target Checklist Item: 4.7 (Unit TB for Hazard & Forwarding Unit)
// Sign-Off Criteria:
//   - rs1, rs2, and both-operand data hazards verified
//   - x0 forwarding suppression validated across all match scenarios
//   - Gating by reg_write_MW verified
//   - Independent and overlapping stall sources checked (mem, wait, mdu, wfi)
//   - Branch flush path verified
// =============================================================================

module tb_pragya_hazard_unit;

    // DUT Interface Signals
    reg  [4:0]  rs1_DE;
    reg  [4:0]  rs2_DE;
    reg  [4:0]  rd_DE;
    reg  [2:0]  wb_sel_DE;
    reg         mem_req_DE;
    reg         wait_for_mem;
    reg         mdu_stall;
    reg         wfi_stall;
    reg  [31:0] instr_IF;
    reg  [4:0]  rd_MW;
    reg         reg_write_MW;
    reg         branch_taken;

    wire        forward_a;
    wire        forward_b;
    wire        stallD;
    wire        flush_DE;
    wire        flush_de_mw;

    // Test Tracking Counters
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate Hazard Unit DUT
    pragya_hazard_unit u_pragya_hazard_unit (
        .rs1_DE(rs1_DE),
        .rs2_DE(rs2_DE),
        .rd_DE(rd_DE),
        .wb_sel_DE(wb_sel_DE),
        .mem_req_DE(mem_req_DE),
        .wait_for_mem(wait_for_mem),
        .mdu_stall(mdu_stall),
        .wfi_stall(wfi_stall),
        .instr_IF(instr_IF),
        .rd_MW(rd_MW),
        .reg_write_MW(reg_write_MW),
        .branch_taken(branch_taken),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .stallD(stallD),
        .flush_DE(flush_DE),
        .flush_de_mw(flush_de_mw)
    );

    // =========================================================================
    // Self-Checking Verification Task
    // =========================================================================
    task verify_hazard(
        input exp_fwd_a,
        input exp_fwd_b,
        input exp_stall,
        input exp_flush,
        input string desc
    );
        total_tests = total_tests + 1;
        #1; // Combinational propagation delay

        if (forward_a   !== exp_fwd_a ||
            forward_b   !== exp_fwd_b ||
            stallD      !== exp_stall ||
            flush_DE    !== exp_flush ||
            flush_de_mw !== 1'b0) begin
            $display("[FAIL] %s -> Got: FwdA=%b FwdB=%b Stall=%b Flush=%b (de_mw=%b) | Exp: FwdA=%b FwdB=%b Stall=%b Flush=%b",
                     desc, forward_a, forward_b, stallD, flush_DE, flush_de_mw,
                     exp_fwd_a, exp_fwd_b, exp_stall, exp_flush);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | FwdA=%b FwdB=%b Stall=%b Flush=%b",
                     desc, forward_a, forward_b, stallD, flush_DE);
        end
    endtask

    // Helper task to clear all inputs to quiescent safe state
    task reset_inputs();
        rs1_DE       = 5'd0;
        rs2_DE       = 5'd0;
        rd_DE        = 5'd0;
        wb_sel_DE    = 3'd0;
        mem_req_DE   = 1'b0;
        wait_for_mem = 1'b0;
        mdu_stall    = 1'b0;
        wfi_stall    = 1'b0;
        instr_IF     = 32'd0;
        rd_MW        = 5'd0;
        reg_write_MW = 1'b0;
        branch_taken = 1'b0;
    endtask

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    initial begin
        reset_inputs();

        $display("\n=======================================================");
        $display("     STARTING PRAGYA HAZARD UNIT VERIFICATION SUITE   ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // Group 1: Quiescent State
        // -------------------------------------------------------------
        $display("--- [Group 1] Quiescent / No-Hazard Default State ---");
        verify_hazard(1'b0, 1'b0, 1'b0, 1'b0, "All inputs idle / no hazards");

        // -------------------------------------------------------------
        // Group 2: Forwarding rs1, rs2, and Both Operands
        // -------------------------------------------------------------
        $display("\n--- [Group 2] Data Forwarding Paths (ALU/MW to DE) ---");
        // Case A: rs1 match only
        reset_inputs();
        rs1_DE       = 5'd5;
        rs2_DE       = 5'd6;
        rd_MW        = 5'd5;
        reg_write_MW = 1'b1;
        verify_hazard(1'b1, 1'b0, 1'b0, 1'b0, "Forward A only (rd_MW == rs1_DE == x5)");

        // Case B: rs2 match only
        reset_inputs();
        rs1_DE       = 5'd5;
        rs2_DE       = 5'd6;
        rd_MW        = 5'd6;
        reg_write_MW = 1'b1;
        verify_hazard(1'b0, 1'b1, 1'b0, 1'b0, "Forward B only (rd_MW == rs2_DE == x6)");

        // Case C: Both operands match same destination register
        reset_inputs();
        rs1_DE       = 5'd10;
        rs2_DE       = 5'd10;
        rd_MW        = 5'd10;
        reg_write_MW = 1'b1;
        verify_hazard(1'b1, 1'b1, 1'b0, 1'b0, "Forward A & B simultaneously (rd_MW == rs1 == rs2 == x10)");

        // Case D: Forwarding inhibited when reg_write_MW = 0 (e.g., Store or Branch in MW)
        reset_inputs();
        rs1_DE       = 5'd10;
        rs2_DE       = 5'd10;
        rd_MW        = 5'd10;
        reg_write_MW = 1'b0;
        verify_hazard(1'b0, 1'b0, 1'b0, 1'b0, "Forwarding suppressed when reg_write_MW is 0");

        // -------------------------------------------------------------
        // Group 3: RISC-V x0 Invariance (Zero-Register Forwarding Suppression)
        // -------------------------------------------------------------
        $display("\n--- [Group 3] x0 Hazard Suppression Invariance ---");
        // Destination is x0 and reg_write_MW is 1 (instruction writing to x0)
        reset_inputs();
        rs1_DE       = 5'd0;
        rs2_DE       = 5'd0;
        rd_MW        = 5'd0;
        reg_write_MW = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b0, 1'b0, "x0 write must NEVER forward to rs1=0 or rs2=0");

        // rs1 reads x0, rs2 reads real register x3
        reset_inputs();
        rs1_DE       = 5'd0;
        rs2_DE       = 5'd3;
        rd_MW        = 5'd0;
        reg_write_MW = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b0, 1'b0, "rd_MW=x0 with rs1=x0, rs2=x3: No forwarding on either port");

        // -------------------------------------------------------------
        // Group 4: Register Boundary Hazards (x1 and x31)
        // -------------------------------------------------------------
        $display("\n--- [Group 4] Boundary Register Address Checks ---");
        // Boundary register x1
        reset_inputs();
        rs1_DE       = 5'd1;
        rd_MW        = 5'd1;
        reg_write_MW = 1'b1;
        verify_hazard(1'b1, 1'b0, 1'b0, 1'b0, "Boundary register x1 forward A");

        // Boundary register x31 (all 1s address: 5'b11111)
        reset_inputs();
        rs2_DE       = 5'd31;
        rd_MW        = 5'd31;
        reg_write_MW = 1'b1;
        verify_hazard(1'b0, 1'b1, 1'b0, 1'b0, "Boundary register x31 forward B");

        // -------------------------------------------------------------
        // Group 5: Stall Signal Sources & Multi-Stall Dominance
        // -------------------------------------------------------------
        $display("\n--- [Group 5] Pipeline Stall Multi-Source Matrix ---");
        // Source 1: mem_req_DE (Load/Store in DE stage)
        reset_inputs();
        mem_req_DE = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b1, 1'b0, "Stall source: mem_req_DE");

        // Source 2: wait_for_mem (Memory bus wait state)
        reset_inputs();
        wait_for_mem = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b1, 1'b0, "Stall source: wait_for_mem");

        // Source 3: mdu_stall (Multi-cycle multiplier/divider in progress)
        reset_inputs();
        mdu_stall = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b1, 1'b0, "Stall source: mdu_stall");

        // Source 4: wfi_stall (Wait for interrupt processor freeze)
        reset_inputs();
        wfi_stall = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b1, 1'b0, "Stall source: wfi_stall");

        // Multi-stall overlap: All stalls asserted simultaneously
        reset_inputs();
        mem_req_DE   = 1'b1;
        wait_for_mem = 1'b1;
        mdu_stall    = 1'b1;
        wfi_stall    = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b1, 1'b0, "Multiple simultaneous stalls asserted");

        // -------------------------------------------------------------
        // Group 6: Branch Flush & Combined Stall-Flush Conflicts
        // -------------------------------------------------------------
        $display("\n--- [Group 6] Branch Flush and Stall/Flush Interaction ---");
        // Clean Branch Taken
        reset_inputs();
        branch_taken = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b0, 1'b1, "Branch taken asserts flush_DE");

        // Branch Taken during active stall (mispredict during memory/MDU wait)
        reset_inputs();
        branch_taken = 1'b1;
        mdu_stall    = 1'b1;
        verify_hazard(1'b0, 1'b0, 1'b1, 1'b1, "Concurrent stall and branch flush");

        // Forwarding + Stall + Flush concurrent corner case
        reset_inputs();
        rs1_DE       = 5'd7;
        rd_MW        = 5'd7;
        reg_write_MW = 1'b1;
        mdu_stall    = 1'b1;
        branch_taken = 1'b1;
        verify_hazard(1'b1, 1'b0, 1'b1, 1'b1, "Forwarding, stall, and flush active simultaneously");

        // -------------------------------------------------------------
        // Group 7: Exhaustive Random Walk (Toggles & Cross-Bin Coverage)
        // -------------------------------------------------------------
        $display("\n--- [Group 7] Randomized Stimulus Sweep (1000 Cycles) ---");
        for (int i = 0; i < 1000; i = i + 1) begin
            rs1_DE       = $urandom_range(0, 31);
            rs2_DE       = $urandom_range(0, 31);
            rd_MW        = $urandom_range(0, 31);
            reg_write_MW = $urandom_range(0, 1);
            mem_req_DE   = $urandom_range(0, 1);
            wait_for_mem = $urandom_range(0, 1);
            mdu_stall    = $urandom_range(0, 1);
            wfi_stall    = $urandom_range(0, 1);
            branch_taken = $urandom_range(0, 1);

            #1;
            // Golden check
            if (forward_a !== (reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs1_DE)) ||
                forward_b !== (reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs2_DE)) ||
                stallD    !== (mem_req_DE | wait_for_mem | mdu_stall | wfi_stall)     ||
                flush_DE  !== branch_taken) begin
                $display("[FAIL] Random Vector %0d Mismatch!", i);
                failed_tests = failed_tests + 1;
            end else begin
                total_tests = total_tests + 1;
            end
        end

        // -------------------------------------------------------------
        // Summary & Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.7)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
