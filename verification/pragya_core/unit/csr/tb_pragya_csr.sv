`timescale 1ns / 1ps

module tb_pragya_csr;

    // Clock and Reset
    reg clk;
    reg rst;

    // Hardware Debug Inputs
    reg        debug_update_dpc;
    reg [31:0] debug_pc_save;
    reg [2:0]  debug_cause;

    // CSR Instruction Bus
    reg        csr_wr_en;
    reg [11:0] csr_addr;
    reg [2:0]  csr_op;
    reg [4:0]  csr_imm;
    reg [31:0] csr_data;

    // Hardware Trap Inputs
    reg [31:0] pc_in;
    reg        set_epc;
    reg        set_cause;
    reg        i_or_e;
    reg [3:0]  cause_in;
    reg        mie_clear;
    reg        mie_set;
    reg [31:0] trap_value;

    // Counter Input
    reg instret_inc;

    // DUT Outputs
    wire [31:0] csr_data_out;
    wire [31:0] epc_out;
    wire [31:0] trap_address_out;
    wire        mie_out;
    wire [31:0] dpc_out;
    wire        meie_out;
    wire        mtie_out;
    wire        msie_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_csr u_dut (
        .clk_in(clk),
        .rst_in(rst),
        .debug_update_dpc_in(debug_update_dpc),
        .debug_pc_save_in(debug_pc_save),
        .debug_cause_in(debug_cause),
        .csr_wr_en_in(csr_wr_en),
        .csr_addr_in(csr_addr),
        .csr_op_in(csr_op),
        .csr_imm_in(csr_imm),
        .csr_data_in(csr_data),
        .pc_in(pc_in),
        .set_epc_in(set_epc),
        .set_cause_in(set_cause),
        .i_or_e_in(i_or_e),
        .cause_in(cause_in),
        .mie_clear_in(mie_clear),
        .mie_set_in(mie_set),
        .trap_value_in(trap_value),
        .instret_inc_in(instret_inc),
        .csr_data_out(csr_data_out),
        .epc_out(epc_out),
        .trap_address_out(trap_address_out),
        .mie_out(mie_out),
        .dpc_out(dpc_out),
        .meie_out(meie_out),
        .mtie_out(mtie_out),
        .msie_out(msie_out)
    );

    // 100MHz Clock (10ns Period)
    always #5 clk = ~clk;

    // CSR Address Definitions
    localparam [11:0] CYCLE     = 12'hC00;
    localparam [11:0] INSTRET   = 12'hC02;
    localparam [11:0] CYCLEH    = 12'hC80;
    localparam [11:0] INSTRETH  = 12'hC82;

    localparam [11:0] MSTATUS   = 12'h300;
    localparam [11:0] MISA      = 12'h301;
    localparam [11:0] MIE       = 12'h304;
    localparam [11:0] MTVEC     = 12'h305;
    localparam [11:0] MVENDORID = 12'hF11;
    localparam [11:0] MARCHID   = 12'hF12;
    localparam [11:0] MIMPID    = 12'hF13;
    localparam [11:0] MHARTID   = 12'hF14;

    localparam [11:0] MSCRATCH  = 12'h340;
    localparam [11:0] MEPC      = 12'h341;
    localparam [11:0] MCAUSE    = 12'h342;
    localparam [11:0] MTVAL     = 12'h343;
    localparam [11:0] MIP       = 12'h344;
    localparam [11:0] PMPADDR16 = 12'h3C0;

    localparam [11:0] MCYCLE    = 12'hB00;
    localparam [11:0] MINSTRET  = 12'hB02;
    localparam [11:0] MCYCLEH   = 12'hB80;
    localparam [11:0] MINSTRETH = 12'hB82;

    localparam [11:0] DCSR      = 12'h7B0;
    localparam [11:0] DPC       = 12'h7B1;
    localparam [11:0] DSCRATCH0 = 12'h7B2;
    localparam [11:0] DSCRATCH1 = 12'h7B3;

    // =========================================================================
    // Core Helper Tasks
    // =========================================================================

    // Execute standard CSR instruction write
    task csrrw(input [11:0] addr, input [31:0] wdata);
        @(negedge clk);
        csr_addr  = addr;
        csr_data  = wdata;
        csr_op    = 3'b001; // CSRRW
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
    endtask

    // Check read value from CSR
    task check_csr(input [11:0] addr, input [31:0] exp_data, input string desc);
        total_tests = total_tests + 1;
        csr_addr = addr;
        #1; // Read is combinational
        if (csr_data_out !== exp_data) begin
            $display("[FAIL] %s | Addr 0x%03h -> Got: 0x%08h, Expected: 0x%08h", desc, addr, csr_data_out, exp_data);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Addr 0x%03h == 0x%08h", desc, addr, csr_data_out);
        end
    endtask

    // Reset all driven signals to safe quiescent values
    task clear_all();
        debug_update_dpc = 1'b0;
        debug_pc_save    = 32'd0;
        debug_cause      = 3'd0;
        csr_wr_en        = 1'b0;
        csr_addr         = 12'd0;
        csr_op           = 3'd0;
        csr_imm          = 5'd0;
        csr_data         = 32'd0;
        pc_in            = 32'd0;
        set_epc          = 1'b0;
        set_cause        = 1'b0;
        i_or_e           = 1'b0;
        cause_in         = 4'd0;
        mie_clear        = 1'b0;
        mie_set          = 1'b0;
        trap_value       = 32'd0;
        instret_inc      = 1'b0;
    endtask

    // =========================================================================
    // Main Verification Execution
    // =========================================================================
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        clear_all();

        $display("Starting Exhaustive Pragya CSR Verification...");

        // -------------------------------------------------------------
        // Group 1: Asynchronous Reset and Initial Power-On States
        // -------------------------------------------------------------
        #25;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        #1;

        check_csr(MISA,      32'h40001100, "Reset MISA (RV32IM Base)");
        check_csr(MARCHID,   32'h00000005, "Reset MARCHID");
        check_csr(MVENDORID, 32'h00000000, "Reset MVENDORID");
        check_csr(MIMPID,    32'h00000000, "Reset MIMPID");
        check_csr(MHARTID,   32'h00000000, "Reset MHARTID");
        check_csr(DCSR,      32'h4a030003, "Reset DCSR");
        check_csr(MIE,       32'h00000000, "Reset MIE");
        check_csr(MEPC,      32'h00000000, "Reset MEPC");
        check_csr(MCAUSE,    32'h00000000, "Reset MCAUSE");
        check_csr(MTVEC,     32'h00000000, "Reset MTVEC");
        check_csr(MSCRATCH,  32'h00000000, "Reset MSCRATCH");
        check_csr(MTVAL,     32'h00000000, "Reset MTVAL");
        check_csr(MIP,       32'h00000000, "Reset MIP");
        check_csr(PMPADDR16, 32'h00000000, "Reset PMPADDR16");
        check_csr(DPC,       32'h00000000, "Reset DPC");
        check_csr(DSCRATCH0, 32'h00000000, "Reset DSCRATCH0");
        check_csr(DSCRATCH1, 32'h00000000, "Reset DSCRATCH1");

        // -------------------------------------------------------------
        // Group 2: All CSR Instruction Types (CSRRW, CSRRS, CSRRC, etc.)
        // -------------------------------------------------------------
        // Write baseline value into MSCRATCH
        csrrw(MSCRATCH, 32'h1234_5670);
        check_csr(MSCRATCH, 32'h1234_5670, "CSRRW Write Baseline");

        // CSRRS (Bit Set via Register)
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_data  = 32'h0000_000F;
        csr_op    = 3'b010;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h1234_567F, "CSRRS Set Low Bits");

        // CSRRC (Bit Clear via Register)
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_data  = 32'h0000_0006;
        csr_op    = 3'b011;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h1234_5679, "CSRRC Clear Bits");

        // CSRRWI (Immediate Overwrite)
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_imm   = 5'b10101; // 21 (0x15)
        csr_op    = 3'b101;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_0015, "CSRRWI Direct Immediate");

        // CSRRSI (Immediate Bit Set)
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_imm   = 5'b01010; // 0x0A -> 0x15 | 0x0A = 0x1F
        csr_op    = 3'b110;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_001F, "CSRRSI Immediate Bit Set");

        // CSRRCI (Immediate Bit Clear)
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_imm   = 5'b00011; // Clear bits [1:0] -> 0x1F & ~0x3 = 0x1C
        csr_op    = 3'b111;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_001C, "CSRRCI Immediate Bit Clear");

        // -------------------------------------------------------------
        // Group 3: Write Suppression Corner Checks
        // -------------------------------------------------------------
        // CSRRS with data_in == 0 -> Must NOT write
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_data  = 32'h0000_0000;
        csr_op    = 3'b010;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_001C, "Write Suppress: CSRRS with data=0");

        // CSRRC with data_in == 0 -> Must NOT write
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_data  = 32'h0000_0000;
        csr_op    = 3'b011;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_001C, "Write Suppress: CSRRC with data=0");

        // CSRRSI with imm == 0 -> Must NOT write
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_imm   = 5'b00000;
        csr_op    = 3'b110;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_001C, "Write Suppress: CSRRSI with imm=0");

        // CSRRCI with imm == 0 -> Must NOT write
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_imm   = 5'b00000;
        csr_op    = 3'b111;
        csr_wr_en = 1'b1;
        @(posedge clk);
        #1;
        csr_wr_en = 1'b0;
        check_csr(MSCRATCH, 32'h0000_001C, "Write Suppress: CSRRCI with imm=0");

        // csr_wr_en = 0 -> Must NOT write
        @(negedge clk);
        csr_addr  = MSCRATCH;
        csr_data  = 32'hDEAD_BEEF;
        csr_op    = 3'b001;
        csr_wr_en = 1'b0;
        @(posedge clk);
        #1;
        check_csr(MSCRATCH, 32'h0000_001C, "Write Suppress: csr_wr_en_in = 0");

        // -------------------------------------------------------------
        // Group 4: Unmapped CSR Address Read
        // -------------------------------------------------------------
        check_csr(12'hFFF, 32'h00000000, "Unmapped Address 0xFFF Defaults to Zero");
        check_csr(12'h000, 32'h00000000, "Unmapped Address 0x000 Defaults to Zero");

        // -------------------------------------------------------------
        // Group 5: Exhaustive R/W Verification on All Remaining Registers
        // -------------------------------------------------------------
        csrrw(MCAUSE,    32'h8000_0007);
        check_csr(MCAUSE, 32'h8000_0007, "MCAUSE R/W");

        csrrw(MTVAL,     32'hBAD0_0004);
        check_csr(MTVAL,  32'hBAD0_0004, "MTVAL R/W");

        csrrw(MIP,       32'h0000_0888);
        check_csr(MIP,    32'h0000_0888, "MIP R/W");

        csrrw(PMPADDR16, 32'hFFFF_0000);
        check_csr(PMPADDR16, 32'hFFFF_0000, "PMPADDR16 R/W");

        csrrw(DSCRATCH1, 32'hFEED_CAFE);
        check_csr(DSCRATCH1, 32'hFEED_CAFE, "DSCRATCH1 R/W");

        // -------------------------------------------------------------
        // Group 6: MEPC Alignment Truncation (Bits [1:0] Must Clear)
        // -------------------------------------------------------------
        csrrw(MEPC, 32'h8000_0001); // LSB bit 0 set
        check_csr(MEPC, 32'h8000_0000, "MEPC Truncates Bit 0");

        csrrw(MEPC, 32'h8000_0003); // Both bits [1:0] set
        check_csr(MEPC, 32'h8000_0000, "MEPC Truncates Bits [1:0]");

        // -------------------------------------------------------------
        // Group 7: MISA Read-Only Fields & Dynamic Modifiability
        // -------------------------------------------------------------
        // Try clearing everything; bits [31:30]=01 and bit 8 (I) must remain set
        csrrw(MISA, 32'h0000_0000);
        check_csr(MISA, 32'h40000100, "MISA Preserves Base RV32I Architecture");

        // Set M extension bit (bit 12)
        csrrw(MISA, 32'h40001000);
        check_csr(MISA, 32'h40001100, "MISA Sets M Extension Bit");

        // -------------------------------------------------------------
        // Group 8: MIE Register Masking & Individual Interrupt Lines
        // -------------------------------------------------------------
        csrrw(MIE, 32'hFFFF_FFFF);
        check_csr(MIE, 32'h0000_0888, "MIE Valid Mask Applied (Bits 11, 7, 3)");

        total_tests = total_tests + 3;
        if (meie_out !== 1'b1 || mtie_out !== 1'b1 || msie_out !== 1'b1) begin
            $display("[FAIL] Interrupt enable lines not active! meie=%b mtie=%b msie=%b", meie_out, mtie_out, msie_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] meie_out, mtie_out, msie_out active");
        end

        // Clear MIE
        csrrw(MIE, 32'h0000_0000);
        total_tests = total_tests + 3;
        if (meie_out !== 1'b0 || mtie_out !== 1'b0 || msie_out !== 1'b0) begin
            $display("[FAIL] Interrupt enable lines did not clear! meie=%b mtie=%b msie=%b", meie_out, mtie_out, msie_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] meie_out, mtie_out, msie_out cleared");
        end

        // -------------------------------------------------------------
        // Group 9: Hardware Trap Interface and MEPC Latching
        // -------------------------------------------------------------
        @(negedge clk);
        set_epc    = 1'b1;
        pc_in      = 32'h1000_0006; // Unaligned PC input
        set_cause  = 1'b1;
        i_or_e     = 1'b1;          // Interrupt
        cause_in   = 4'd11;         // Machine External Interrupt
        trap_value = 32'hCAFE_BABE;
        @(posedge clk);
        #1;
        clear_all();

        check_csr(MEPC,   32'h1000_0004, "Trap Latch: MEPC Aligned to 4 Bytes");
        check_csr(MCAUSE, 32'h8000_000B, "Trap Latch: MCAUSE Interrupt Bit and Code");
        check_csr(MTVAL,  32'hCAFE_BABE, "Trap Latch: MTVAL Latch");

        // Exception trap (i_or_e = 0)
        @(negedge clk);
        set_cause  = 1'b1;
        i_or_e     = 1'b0; // Exception
        cause_in   = 4'd2; // Illegal instruction
        trap_value = 32'h0000_0000;
        @(posedge clk);
        #1;
        clear_all();
        check_csr(MCAUSE, 32'h0000_0002, "Trap Latch: Exception MCAUSE (MSB=0)");

        // -------------------------------------------------------------
        // Group 10: MSTATUS Interrupt Stack State Machine
        // -------------------------------------------------------------
        // 1. Explicitly enable interrupts via MSTATUS write
        csrrw(MSTATUS, 32'h0000_0008); // mie = 1
        total_tests = total_tests + 1;
        if (mie_out !== 1'b1) begin
            $display("[FAIL] mie_out did not set from MSTATUS write");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] mie_out active from MSTATUS write");
        end

        // 2. Trap taken: mie_clear pulses
        @(negedge clk);
        mie_clear = 1'b1;
        @(posedge clk);
        #1;
        mie_clear = 1'b0;

        total_tests = total_tests + 2;
        if (mie_out !== 1'b0 || u_dut.mstatus_out[7] !== 1'b1) begin
            $display("[FAIL] mie_clear failed: mie_out=%b, mpie=%b", mie_out, u_dut.mstatus_out[7]);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] mie_clear: mie_out cleared to 0, old state saved to mpie");
        end

        // 3. Trap return (MRET): mie_set pulses
        @(negedge clk);
        mie_set = 1'b1;
        @(posedge clk);
        #1;
        mie_set = 1'b0;

        total_tests = total_tests + 2;
        if (mie_out !== 1'b1 || u_dut.mstatus_out[7] !== 1'b1) begin
            $display("[FAIL] mie_set failed: mie_out=%b, mpie=%b", mie_out, u_dut.mstatus_out[7]);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] mie_set: mie_out restored to 1 from mpie");
        end

        // -------------------------------------------------------------
        // Group 11: MTVEC Base and Vector Calculations
        // -------------------------------------------------------------
        // Direct Mode: Base = 0x8000_0000, Mode = 00
        csrrw(MTVEC, 32'h8000_0000);
        @(negedge clk);
        i_or_e   = 1'b1; // Interrupt
        cause_in = 4'd3; // Software interrupt
        #1;
        total_tests = total_tests + 1;
        if (trap_address_out !== 32'h8000_0000) begin
            $display("[FAIL] MTVEC Direct Mode failed! Got: 0x%08h", trap_address_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] MTVEC Direct Mode Trap Address: 0x%08h", trap_address_out);
        end

        // Vectored Mode: Base = 0x8000_0000, Mode = 01 -> 32'h8000_0001
        csrrw(MTVEC, 32'h8000_0001);
        @(negedge clk);
        i_or_e   = 1'b1; // Interrupt
        cause_in = 4'd7; // Timer interrupt -> Offset = 7 * 4 = 28 (0x1C)
        #1;
        total_tests = total_tests + 1;
        if (trap_address_out !== 32'h8000_001C) begin
            $display("[FAIL] MTVEC Vectored Mode failed! Got: 0x%08h, Expected: 0x8000001C", trap_address_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] MTVEC Vectored Mode Trap Address: 0x%08h", trap_address_out);
        end

        // Exceptions in Vectored Mode MUST use Base without vector offset
        @(negedge clk);
        i_or_e   = 1'b0; // Exception
        cause_in = 4'd7; // Same cause code
        #1;
        total_tests = total_tests + 1;
        if (trap_address_out !== 32'h8000_0000) begin
            $display("[FAIL] MTVEC Exception Vectoring failed! Got: 0x%08h", trap_address_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] MTVEC Exception in Vectored Mode strictly uses Base Address");
        end

        // -------------------------------------------------------------
        // Group 12: 64-bit Performance Counters and Shadow Registers
        // -------------------------------------------------------------
        // Write MCYCLE and MCYCLEH

        
        csrrw(MCYCLE,  32'h1122_3344);
        csrrw(MCYCLEH, 32'h5566_7788);

        check_csr(MCYCLE,  32'h1122_3345, "MCYCLE Increments With Clock");
        check_csr(MCYCLEH, 32'h5566_7788, "MCYCLEH Preserved High Word");
        check_csr(CYCLE,   32'h1122_3345, "CYCLE Shadow Matches MCYCLE"); 
        check_csr(CYCLEH,  32'h5566_7788, "CYCLEH Shadow Matches MCYCLEH");

        // Write MINSTRET and MINSTRETH
        csrrw(MINSTRET,  32'd500);
        csrrw(MINSTRETH, 32'd2);

        check_csr(MINSTRET,  32'd500, "MINSTRET Initial Value");
        check_csr(MINSTRETH, 32'd2,   "MINSTRETH Initial Value");
        check_csr(INSTRET,   32'd500, "INSTRET Shadow Read");
        check_csr(INSTRETH,  32'd2,   "INSTRETH Shadow Read");

        // Increment retired instructions via instret_inc
        @(negedge clk);
        instret_inc = 1'b1;
        @(posedge clk);
        #1;
        instret_inc = 1'b0;
        check_csr(MINSTRET, 32'd501, "MINSTRET Increments on instret_inc");

        // -------------------------------------------------------------
        // Group 13: Hardware Debug State Machine (DPC & DCSR)
        // -------------------------------------------------------------
        @(negedge clk);
        debug_update_dpc = 1'b1;
        debug_pc_save    = 32'h3000_0007; // Unaligned address
        debug_cause      = 3'b001;        // Trigger hit
        @(posedge clk);
        #1;
        debug_update_dpc = 1'b0;

        total_tests = total_tests + 1;
        if (dpc_out !== 32'h3000_0004) begin
            $display("[FAIL] Hardware Debug DPC Aligned Latch failed! Got: 0x%08h", dpc_out);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Hardware Debug DPC Latch: 0x%08h", dpc_out);
        end

        check_csr(DPC, 32'h3000_0004, "DPC Register Matches dpc_out");

        csr_addr = DCSR;
        #1;
        total_tests = total_tests + 1;
        if (csr_data_out[8:6] !== 3'b001) begin
            $display("[FAIL] DCSR debug cause bits [8:6] mismatch! Got: %b, Expected: 001", csr_data_out[8:6]);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] DCSR debug cause bits [8:6] == 3'b001");
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
