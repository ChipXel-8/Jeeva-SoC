`timescale 1ns / 1ps

module tb_pragya_machine_control;

    // Clock and Reset
    reg clk;
    reg rst;

    // Debug Module Inputs
    reg debug_req;
    reg debug_mode_status;

    // Datapath & Instruction Inputs
    reg [31:0] pc_in;
    reg        id_valid;
    reg [31:0] mem_addr_in;
    reg        retire_valid;
    reg [31:0] instr_in;

    // Decoder Exception Inputs
    reg illegal_instr;
    reg misaligned_instr;

    // Decoded Instruction Fields
    reg [6:2] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd_addr;

    // Interrupt Lines
    reg e_irq, t_irq, s_irq;
    reg mie;
    reg meie, mtie, msie;
    reg meip, mtip, msip;

    // DUT Outputs
    wire        i_or_e_out;
    wire        set_epc_out;
    wire        set_cause_out;
    wire [3:0]  cause_out;
    wire        instret_inc_out;
    wire        mie_clear_out;
    wire        mie_set_out;
    wire [31:0] trap_value_out;
    wire [1:0]  pc_src_out;
    wire [31:0] trap_pc_out;
    wire        trap_detected_out;
    wire        mret_detected_out;
    wire        wfi_stall_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate Machine Control DUT
    pragya_machine_control u_dut (
        .clk_in(clk),
        .rst_in(rst),
        .debug_req_in(debug_req),
        .debug_mode_status_in(debug_mode_status),
        .pc_in(pc_in),
        .id_valid_in(id_valid),
        .mem_addr_in(mem_addr_in),
        .retire_valid_in(retire_valid),
        .instr_in(instr_in),
        .illegal_instr_in(illegal_instr),
        .misaligned_instr_in(misaligned_instr),
        .opcode_6_to_2_in(opcode),
        .funct3_in(funct3),
        .funct7_in(funct7),
        .rs1_addr_in(rs1_addr),
        .rs2_addr_in(rs2_addr),
        .rd_addr_in(rd_addr),
        .e_irq_in(e_irq),
        .t_irq_in(t_irq),
        .s_irq_in(s_irq),
        .mie_in(mie),
        .meie_in(meie),
        .mtie_in(mtie),
        .msie_in(msie),
        .meip_in(meip),
        .mtip_in(mtip),
        .msip_in(msip),
        .i_or_e_out(i_or_e_out),
        .set_epc_out(set_epc_out),
        .set_cause_out(set_cause_out),
        .cause_out(cause_out),
        .instret_inc_out(instret_inc_out),
        .mie_clear_out(mie_clear_out),
        .mie_set_out(mie_set_out),
        .trap_value_out(trap_value_out),
        .pc_src_out(pc_src_out),
        .trap_pc_out(trap_pc_out),
        .trap_detected_out(trap_detected_out),
        .mret_detected_out(mret_detected_out),
        .wfi_stall_out(wfi_stall_out)
    );

    // 100MHz Clock (10ns Period)
    always #5 clk = ~clk;

    // Clear all inputs
    task clear_all();
        debug_req         = 1'b0;
        debug_mode_status = 1'b0;
        pc_in             = 32'd0;
        id_valid          = 1'b0;
        mem_addr_in       = 32'd0;
        retire_valid      = 1'b0;
        instr_in          = 32'd0;
        illegal_instr     = 1'b0;
        misaligned_instr  = 1'b0;
        opcode            = 5'b0;
        funct3            = 3'b0;
        funct7            = 7'b0;
        rs1_addr          = 5'b0;
        rs2_addr          = 5'b0;
        rd_addr           = 5'b0;
        e_irq             = 1'b0;
        t_irq             = 1'b0;
        s_irq             = 1'b0;
        mie               = 1'b0;
        meie              = 1'b0;
        mtie              = 1'b0;
        msie              = 1'b0;
        meip              = 1'b0;
        mtip              = 1'b0;
        msip              = 1'b0;
    endtask

    // Configure SYSTEM instruction fields
    task setup_system_instr(input [6:0] f7, input [4:0] r2);
        opcode   = 5'b11100; // SYSTEM opcode bits [6:2]
        funct3   = 3'b000;
        funct7   = f7;
        rs1_addr = 5'b00000;
        rs2_addr = r2;
        rd_addr  = 5'b00000;
        id_valid = 1'b1;
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        clear_all();

        $display("Starting Pragya Machine Control Unit Verification...");

        // -------------------------------------------------------------
        // Group 1: Reset State & Transition to Operating
        // -------------------------------------------------------------
        #25;
        total_tests = total_tests + 1;
        if (pc_src_out !== 2'b00 || wfi_stall_out !== 1'b0) begin
            $display("[FAIL] Reset State Mismatch! pc_src=%b", pc_src_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Reset State: pc_src_out = 2'b00 (PC_BOOT)");
        end

        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_src_out !== 2'b11) begin
            $display("[FAIL] Operating State Mismatch! pc_src=%b", pc_src_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Operating State Entered: pc_src_out = 2'b11 (PC_NEXT)");
        end

        // -------------------------------------------------------------
        // Group 2: Instruction Retirement Tracking (instret_inc)
        // -------------------------------------------------------------
        @(negedge clk);
        retire_valid = 1'b1;
        #1;
        total_tests = total_tests + 1;
        if (instret_inc_out !== 1'b1) begin
            $display("[FAIL] instret_inc_out failed to track retire_valid!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] instret_inc_out tracks retire_valid");
        end
        retire_valid = 1'b0;

        // -------------------------------------------------------------
        // Group 3: Interrupts & Priority (External > Software > Timer)
        // -------------------------------------------------------------
        // A. Timer Interrupt only
        @(negedge clk);
        mie     = 1'b1;
        mtie    = 1'b1;
        t_irq   = 1'b1;
        pc_in   = 32'h0001_0040;

        @(posedge clk); // Registers trap cause & changes state to TRAP_TAKEN
        #1;
        total_tests = total_tests + 4;
        if (pc_src_out !== 2'b10 || set_epc_out !== 1'b1 ||
            cause_out !== 4'b0111 || i_or_e_out !== 1'b1) begin
            $display("[FAIL] Timer Interrupt Trap Entry Failed! pc_src=%b cause=%b i_or_e=%b",
                     pc_src_out, cause_out, i_or_e_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Timer Interrupt Trap: Cause=7 (0111), i_or_e=1, pc_src=PC_TRAP");
        end

        clear_all();
        @(posedge clk); // Returns to STATE_OPERATING
        #1;

        // B. Software Interrupt
        @(negedge clk);
        mie     = 1'b1;
        msie    = 1'b1;
        s_irq   = 1'b1;

        @(posedge clk);
        #1;
        total_tests = total_tests + 2;
        if (cause_out !== 4'b0011 || i_or_e_out !== 1'b1) begin
            $display("[FAIL] Software Interrupt Failed! cause=%b", cause_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Software Interrupt Trap: Cause=3 (0011), i_or_e=1");
        end

        clear_all();
        @(posedge clk); // Returns to STATE_OPERATING
        #1;

        // C. External Interrupt
        @(negedge clk);
        mie     = 1'b1;
        meie    = 1'b1;
        e_irq   = 1'b1;

        @(posedge clk);
        #1;
        total_tests = total_tests + 2;
        if (cause_out !== 4'b1011 || i_or_e_out !== 1'b1) begin
            $display("[FAIL] External Interrupt Failed! cause=%b", cause_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] External Interrupt Trap: Cause=11 (1011), i_or_e=1");
        end

        clear_all();
        @(posedge clk);
        #1;

        // D. Priority Conflict: All 3 active simultaneously (External MUST win)
        @(negedge clk);
        mie   = 1'b1;
        meie  = 1'b1; e_irq = 1'b1;
        msie  = 1'b1; s_irq = 1'b1;
        mtie  = 1'b1; t_irq = 1'b1;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (cause_out !== 4'b1011) begin
            $display("[FAIL] Interrupt Priority Failed! Expected Cause=11 (External), got %b", cause_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Priority Resolution: External Interrupt correctly took precedence");
        end

        clear_all();
        @(posedge clk);
        #1;

        // E. Interrupt Masking (mie_in = 0 must prevent trap entry)
        @(negedge clk);
        mie   = 1'b0; // Interrupts globally disabled
        meie  = 1'b1;
        e_irq = 1'b1;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_src_out !== 2'b11 || set_epc_out !== 1'b0) begin
            $display("[FAIL] Global MIE=0 failed to mask interrupt!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Global MIE=0 correctly masked external interrupt");
        end
        clear_all();

        // -------------------------------------------------------------
        // Group 4: Synchronous Exceptions & mtval Payloads
        // -------------------------------------------------------------
        // A. Illegal Instruction
        @(negedge clk);
        id_valid      = 1'b1;
        illegal_instr = 1'b1;
        instr_in      = 32'hDEAD_BEEF;

        @(posedge clk);
        #1;
        total_tests = total_tests + 3;
        if (cause_out !== 4'b0010 || i_or_e_out !== 1'b0 || trap_value_out !== 32'hDEAD_BEEF) begin
            $display("[FAIL] Illegal Instruction Exception Failed! cause=%b mtval=0x%08h", cause_out, trap_value_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Illegal Instruction: Cause=2, i_or_e=0, mtval=0xDEADBEEF");
        end

        clear_all();
        @(posedge clk);
        #1;

        // B. Misaligned Instruction / Address
        @(negedge clk);
        id_valid         = 1'b1;
        misaligned_instr = 1'b1;
        mem_addr_in      = 32'h1000_0003;

        @(posedge clk);
        #1;
        total_tests = total_tests + 3;
        if (cause_out !== 4'b0000 || i_or_e_out !== 1'b0 || trap_value_out !== 32'h1000_0003) begin
            $display("[FAIL] Misaligned Exception Failed! cause=%b mtval=0x%08h", cause_out, trap_value_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Misaligned Instruction: Cause=0, i_or_e=0, mtval=0x10000003");
        end

        clear_all();
        @(posedge clk);
        #1;

        // C. ECALL Instruction
        @(negedge clk);
        setup_system_instr(7'b0000000, 5'b00000); // ecall

        @(posedge clk);
        #1;
        total_tests = total_tests + 3;
        if (cause_out !== 4'b1011 || i_or_e_out !== 1'b0 || trap_value_out !== 32'd0) begin
            $display("[FAIL] ECALL Exception Failed! cause=%b i_or_e=%b mtval=0x%08h",
                     cause_out, i_or_e_out, trap_value_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] ECALL: Cause=11, i_or_e=0 (Environment Call from M-mode), mtval=0");
        end

        clear_all();
        @(posedge clk);
        #1;

        // D. EBREAK Instruction
        @(negedge clk);
        pc_in = 32'h0002_0008;
        setup_system_instr(7'b0000000, 5'b00001); // ebreak

        @(posedge clk);
        #1;
        total_tests = total_tests + 3;
        if (cause_out !== 4'b0011 || i_or_e_out !== 1'b0 || trap_value_out !== 32'h0002_0008) begin
            $display("[FAIL] EBREAK Exception Failed! cause=%b mtval=0x%08h", cause_out, trap_value_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] EBREAK: Cause=3, i_or_e=0, mtval=pc (0x00020008)");
        end

        clear_all();
        @(posedge clk);
        #1;

        // -------------------------------------------------------------
        // Group 5: Trap Return (MRET)
        // -------------------------------------------------------------
        @(negedge clk);
        setup_system_instr(7'b0011000, 5'b00010); // mret: funct7=0011000, rs2=00010
        #1;
        total_tests = total_tests + 1;
        if (mret_detected_out !== 1'b1) begin
            $display("[FAIL] mret_detected_out failed to assert combinationally!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] mret_detected_out asserted");
        end

        @(posedge clk);
        #1;
        total_tests = total_tests + 2;
        if (pc_src_out !== 2'b01 || mie_set_out !== 1'b1) begin
            $display("[FAIL] MRET State Actions Failed! pc_src=%b mie_set=%b", pc_src_out, mie_set_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] MRET Trap Return: pc_src_out = 2'b01 (PC_EPC), mie_set_out = 1");
        end

        clear_all();
        @(posedge clk);
        #1;

        // -------------------------------------------------------------
        // Group 6: Low-Power WFI Sleep & Wakeup
        // -------------------------------------------------------------
        @(negedge clk);
        setup_system_instr(7'b0001000, 5'b00101); // wfi: funct7=0001000, rs2=00101

        @(posedge clk);
        #1;
        clear_all();
        total_tests = total_tests + 1;
        if (wfi_stall_out !== 1'b1) begin
            $display("[FAIL] Failed to enter WFI Sleep State!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] WFI State Entered: wfi_stall_out asserted");
        end

        // Ensure core stays sleeping while no interrupts
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (wfi_stall_out !== 1'b1) begin
            $display("[FAIL] Core woke prematurely from WFI!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Core remains in WFI sleep without interrupts");
        end

        // Wake core from WFI via pending interrupt
        @(negedge clk);
        meie  = 1'b1;
        e_irq = 1'b1; // ip asserts

        @(posedge clk);
        #1;
        clear_all();
        total_tests = total_tests + 1;
        if (wfi_stall_out !== 1'b0) begin
            $display("[FAIL] Core failed to wake from WFI upon interrupt!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Core woke from WFI successfully upon interrupt (wfi_stall_out cleared)");
        end

        // -------------------------------------------------------------
        // Group 7: Hardware Debug Mode Integration
        // -------------------------------------------------------------
        @(negedge clk);
        debug_req = 1'b1;

        @(posedge clk);
        #1;
        debug_req         = 1'b0;
        debug_mode_status = 1'b1; // Host debugger actively halted the core

        // Present an exception while halted in Debug Mode
        id_valid      = 1'b1;
        illegal_instr = 1'b1;
        #1;
        total_tests = total_tests + 1;
        if (trap_detected_out !== 1'b0) begin
            $display("[FAIL] Trap was NOT suppressed during Debug Mode!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Debug Mode: Traps successfully suppressed (trap_detected_out = 0)");
        end

        // Exit Debug Mode (resume)
        @(negedge clk);
        debug_mode_status = 1'b0;
        clear_all();
        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (pc_src_out !== 2'b11) begin
            $display("[FAIL] Failed to return to STATE_OPERATING from Debug Mode!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Resumed from Debug Mode to normal execution");
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