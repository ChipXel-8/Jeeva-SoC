`timescale 1ns / 1ps

// =============================================================================
// Unit Testbench: pc_unit
// Target Checklist Item: 4.1 (Unit TB for PC unit)
// =============================================================================

module tb_pc_unit;

    // Default configuration values
    localparam [31:0] RESET_PC        = 32'h8000_0000;
    localparam [31:0] DEBUG_BASE_ADDR = 32'h0100_0000;

    // PC source selection encodings
    localparam [1:0] PC_BOOT = 2'b00;
    localparam [1:0] PC_EPC  = 2'b01;
    localparam [1:0] PC_TRAP = 2'b10;
    localparam [1:0] PC_NEXT = 2'b11;

    // Inputs to DUT
    reg        clk;
    reg        rst;
    reg        stall;
    reg        branch_taken_in;
    reg [31:0] pc_target;
    reg        debug_req_i;
    reg        is_dret_inst;
    reg [31:0] dpc_in;
    reg [1:0]  pc_src_in;
    reg [31:0] epc_in;
    reg [31:0] trap_address_in;
    reg        is_ebreak_inst;

    // Outputs from DUT
    wire [31:0] pc;
    wire [31:0] pc_plus4;
    wire        misaligned_instr_out;
    wire        debug_update_dpc_o;
    wire [31:0] debug_pc_save_o;
    wire [2:0]  debug_cause_o;
    wire        debug_mode_status_o;

    // Test counters
    integer total_tests = 0;
    integer failed_tests = 0;

    // Instantiate the PC Unit
    pc_unit #(
        .RESET_PC(RESET_PC),
        .DEBUG_BASE_ADDR(DEBUG_BASE_ADDR)
    ) u_pc_unit (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_taken_in(branch_taken_in),
        .pc_target(pc_target),
        .debug_req_i(debug_req_i),
        .is_dret_inst(is_dret_inst),
        .dpc_in(dpc_in),
        .debug_update_dpc_o(debug_update_dpc_o),
        .debug_pc_save_o(debug_pc_save_o),
        .debug_cause_o(debug_cause_o),
        .debug_mode_status_o(debug_mode_status_o),
        .pc_src_in(pc_src_in),
        .epc_in(epc_in),
        .trap_address_in(trap_address_in),
        .is_ebreak_inst(is_ebreak_inst),
        .pc(pc),
        .pc_plus4(pc_plus4),
        .misaligned_instr_out(misaligned_instr_out)
    );

    // 100MHz clock generation (5ns high, 5ns low)
    always #5 clk = ~clk;

    // Simple check task with human-readable logging
    task check(input [31:0] expected_pc, input string test_name);
        total_tests = total_tests + 1;
        #1; // Sample output after clock edge settled
        if (pc !== expected_pc) begin
            $display("[FAIL] %s -> Expected PC: 0x%08h, but Got: 0x%08h", test_name, expected_pc, pc);
            failed_tests = failed_tests + 1;
        end else if (pc_plus4 !== (expected_pc + 32'd4)) begin
            $display("[FAIL] %s -> PC is correct, but pc_plus4 is wrong! Expected: 0x%08h, Got: 0x%08h", test_name, (expected_pc + 32'd4), pc_plus4);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s -> PC = 0x%08h (PC+4 = 0x%08h)", test_name, pc, pc_plus4);
        end
    endtask

    // Main Test Stimulus
    initial begin
        // Reset and clear all inputs
        clk             = 0;
        rst             = 1;
        stall           = 0;
        branch_taken_in = 0;
        pc_target       = 32'h0;
        debug_req_i     = 0;
        is_dret_inst    = 0;
        dpc_in          = 32'h0;
        pc_src_in       = PC_NEXT;
        epc_in          = 32'h0;
        trap_address_in = 32'h0;
        is_ebreak_inst  = 0;

        $display("\n=======================================================");
        $display("          STARTING PC UNIT VERIFICATION SUITE          ");
        $display("=======================================================\n");

        // -------------------------------------------------------------
        // 1. Reset Behavior
        // -------------------------------------------------------------
        $display("--- [Test Group 1] Reset & Initialization ---");
        #20;
        @(posedge clk);
        #1;
        if (pc == RESET_PC && debug_mode_status_o == 0) begin
            $display("[PASS] Hardware reset properly drives PC to boot address (0x%08h)", pc);
        end else begin
            $display("[FAIL] Hardware reset failed! PC: 0x%08h, Debug Status: %b", pc, debug_mode_status_o);
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;
        rst = 0;

        // -------------------------------------------------------------
        // 2. Sequential Stepping & 32-bit Rollover Boundary
        // -------------------------------------------------------------
        $display("\n--- [Test Group 2] Sequential Execution & Rollover ---");
        @(posedge clk);
        check(RESET_PC + 32'd4, "Step forward 1 instruction");

        @(posedge clk);
        check(RESET_PC + 32'd8, "Step forward 2 instructions");

        // Jump to top of 32-bit memory to check overflow/rollover
        branch_taken_in = 1;
        pc_target       = 32'hFFFFFFFC;
        @(posedge clk);
        check(32'hFFFFFFFC, "Jump to highest 32-bit boundary");
        branch_taken_in = 0;

        @(posedge clk);
        check(32'h00000000, "Address space roll-over from 0xFFFFFFFC to 0x00000000");

        @(posedge clk);
        check(32'h00000004, "Continue stepping smoothly after roll-over");

        // -------------------------------------------------------------
        // 3. Pipeline Stalls (Freeze checking)
        // -------------------------------------------------------------
        $display("\n--- [Test Group 3] Pipeline Stall & Freeze Tests ---");
        stall = 1;
        @(posedge clk);
        check(32'h00000004, "Stall cycle 1: PC must freeze");
        @(posedge clk);
        check(32'h00000004, "Stall cycle 2: PC must stay frozen");
        stall = 0;

        @(posedge clk);
        check(32'h00000008, "Deassert stall: PC advances to next instruction");

        // -------------------------------------------------------------
        // 4. Branching & Address Misalignment Detection
        // -------------------------------------------------------------
        $display("\n--- [Test Group 4] Branching & Alignment Detection ---");
        // Forward jump
        branch_taken_in = 1;
        pc_target       = 32'h8000_1000;
        @(posedge clk);
        check(32'h8000_1000, "Take forward branch to 0x80001000");

        // Backward jump
        pc_target = 32'h8000_0500;
        @(posedge clk);
        check(32'h8000_0500, "Take backward branch to 0x80000500");
        branch_taken_in = 0;

        // Check alignment detector logic
        branch_taken_in = 1;
        pc_target = 32'h8000_0500; #1; // Offset 0: Aligned
        if (!misaligned_instr_out)
            $display("[PASS] Word-aligned branch target correctly flagged as valid (misalign=0)");
        else begin
            $display("[FAIL] False alarm: Aligned target marked as misaligned!");
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;

        pc_target = 32'h8000_0501; #1; // Offset 1: Misaligned
        if (misaligned_instr_out)
            $display("[PASS] Misaligned target detected on byte offset +1");
        else begin
            $display("[FAIL] Missed misalignment on byte offset +1!");
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;

        pc_target = 32'h8000_0502; #1; // Offset 2: Misaligned
        if (misaligned_instr_out)
            $display("[PASS] Misaligned target detected on byte offset +2");
        else begin
            $display("[FAIL] Missed misalignment on byte offset +2!");
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;

        // Make sure misalignment flag stays LOW if branch_taken_in is 0
        branch_taken_in = 0;
        pc_target = 32'h8000_0503; #1;
        if (!misaligned_instr_out)
            $display("[PASS] Misalignment flag suppressed when branch_taken_in is inactive");
        else begin
            $display("[FAIL] Misalignment flag leaked while not branching!");
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;
        @(posedge clk);

        // -------------------------------------------------------------
        // 5. Machine Mode Traps and Interrupts
        // -------------------------------------------------------------
        $display("\n--- [Test Group 5] Machine Mode Traps & Returns ---");
        // Jump to interrupt handler
        trap_address_in = 32'h8000_0040;
        pc_src_in       = PC_TRAP;
        @(posedge clk);
        check(32'h8000_0040, "Vector directly into trap handler (mtvec)");

        // Return from trap using MRET
        epc_in    = 32'h8000_2000;
        pc_src_in = PC_EPC;
        @(posedge clk);
        check(32'h8000_2000, "MRET returns to interrupted instruction (mepc)");

        // Software boot jump
        pc_src_in = PC_BOOT;
        @(posedge clk);
        check(RESET_PC, "Warm boot forces PC back to RESET_PC");
        pc_src_in = PC_NEXT;

        // -------------------------------------------------------------
        // 6. Hardware Debug Mode Workflow
        // -------------------------------------------------------------
        $display("\n--- [Test Group 6] Hardware Debug Mode Protocol ---");
        // Pulse debug request
        debug_req_i = 1;
        #1;
        if (debug_update_dpc_o && debug_cause_o == 3'd3)
            $display("[PASS] Debug entry generates DPC save pulse with halt cause = 3");
        else begin
            $display("[FAIL] Debug entry signals missing! update_dpc: %b, cause: %0d", debug_update_dpc_o, debug_cause_o);
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;

        @(posedge clk);
        debug_req_i = 0;
        check(DEBUG_BASE_ADDR, "Core enters debug park loop at DEBUG_BASE_ADDR");

        // Repeated debug pulse while already inside debug mode (must be ignored)
        debug_req_i = 1;
        #1;
        if (!debug_update_dpc_o)
            $display("[PASS] Redundant debug request suppressed while already in debug mode");
        else begin
            $display("[FAIL] Debug pulse re-triggered while already running inside debug mode!");
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;
        @(posedge clk);
        debug_req_i = 0;

        // Advance a few steps inside debug ROM, then hit EBREAK
        @(posedge clk); // 0x01000004
        @(posedge clk); // 0x01000008
        is_ebreak_inst = 1;
        @(posedge clk);
        is_ebreak_inst = 0;
        check(DEBUG_BASE_ADDR, "EBREAK inside debug mode loops back to DEBUG_BASE_ADDR");

        // Normal traps must be ignored while in debug mode
        trap_address_in = 32'h8000_9999;
        pc_src_in       = PC_TRAP;
        @(posedge clk);
        check(DEBUG_BASE_ADDR + 32'd4, "External traps safely ignored while running in debug mode");
        pc_src_in = PC_NEXT;

        // Exit debug mode via DRET
        dpc_in       = 32'h8000_3330;
        is_dret_inst = 1;
        @(posedge clk);
        is_dret_inst = 0;
        check(32'h8000_3330, "DRET successfully exits debug mode back to saved DPC");

        // -------------------------------------------------------------
        // 7. Priority Matrix & Anti-Deadlock Checks
        // -------------------------------------------------------------
        $display("\n--- [Test Group 7] Priority Resolution & Anti-Deadlock ---");
        // Priority Rule: Debug request must break an active pipeline stall
        stall       = 1;
        debug_req_i = 1;
        @(posedge clk);
        stall       = 0;
        debug_req_i = 0;
        check(DEBUG_BASE_ADDR, "Priority 1: Debug request breaks active pipeline stall");

        // Clean exit
        dpc_in = 32'h8000_4440; is_dret_inst = 1;
        @(posedge clk); is_dret_inst = 0;

        // Priority Rule: Debug request overrides simultaneous branch and trap
        branch_taken_in = 1;
        pc_target       = 32'h8000_5550;
        pc_src_in       = PC_TRAP;
        trap_address_in = 32'h8000_6660;
        debug_req_i     = 1;
        @(posedge clk);
        branch_taken_in = 0;
        pc_src_in       = PC_NEXT;
        debug_req_i     = 0;
        check(DEBUG_BASE_ADDR, "Priority 1: Debug request overrides concurrent branch and trap");

        // Clean exit
        dpc_in = 32'h8000_7770; is_dret_inst = 1;
        @(posedge clk); is_dret_inst = 0;

        // Priority Rule: Trap overrides normal branch
        branch_taken_in = 1;
        pc_target       = 32'h8000_AAAA;
        pc_src_in       = PC_TRAP;
        trap_address_in = 32'h8000_BBBB;
        @(posedge clk);
        branch_taken_in = 0;
        pc_src_in       = PC_NEXT;
        check(32'h8000_BBBB, "Priority 2: Trap address overrides concurrent branch");

        // Priority Rule: Stall freezes PC even if branch is taken
        stall           = 1;
        branch_taken_in = 1;
        pc_target       = 32'h8000_CCCC;
        @(posedge clk);
        stall           = 0;
        branch_taken_in = 0;
        check(32'h8000_BBBB, "Priority 3: Pipeline stall holds PC, ignoring branch");

        // -------------------------------------------------------------
        // Summary & Verdict
        // -------------------------------------------------------------
        $display("\n=======================================================");
        if (failed_tests == 0) begin
            $display("   TEST SUMMARY: ALL %0d CHECKS PASSED PERFECTLY!       ", total_tests);
            $display("   STATUS: READY FOR SIGN-OFF (CHECKLIST ITEM 4.1)      ");
        end else begin
            $display("   TEST SUMMARY: %0d / %0d CHECKS FAILED!               ", failed_tests, total_tests);
            $display("   STATUS: DEFECTS FOUND - REVIEW LOG ABOVE             ");
        end
        $display("=======================================================\n");

        $finish;
    end

endmodule
