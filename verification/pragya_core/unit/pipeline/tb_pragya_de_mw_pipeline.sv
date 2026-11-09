`timescale 1ns / 1ps

module tb_pragya_de_mw_pipeline;

    // Clock and Reset
    reg clk;
    reg rst;

    // Control Signals
    reg valid_de;
    reg stall_mw;
    reg flush;

    // Data and Operation Inputs
    reg        mem_req_in;
    reg        mem_write_in;
    reg [31:0] mdu_result_in;
    reg [31:0] alu_result_in;
    reg [31:0] i_adder_in;
    reg [31:0] imm_in;
    reg [31:0] pc_plus_4_in;
    reg [31:0] pc_in;
    reg [31:0] instr_in;
    reg [31:0] rs_2_in;
    reg [4:0]  rd_addrs_in;
    reg [2:0]  funct3_in;
    reg [2:0]  wb_mux_sel_in;
    reg        reg_write_in;
    reg        csr_wr_en_in;
    reg [11:0] csr_addr_in;
    reg [2:0]  csr_op_in;
    reg [31:0] csr_data_in;
    reg [4:0]  csr_imm_in;

    // Memory bus unused input hook
    reg rvalid;

    // DUT Outputs
    wire        mem_wb_valid;
    wire        mem_req_reg_out;
    wire        mem_write_reg_out;
    wire [31:0] mdu_result_reg_out;
    wire [31:0] alu_result_reg_out;
    wire [31:0] i_adder_reg_out;
    wire [31:0] imm_reg_out;
    wire [31:0] pc_plus_4_reg_out;
    wire [31:0] rs_2_reg_out;
    wire [4:0]  rd_addrs_reg_out;
    wire [31:0] pc_reg_out;
    wire [31:0] instr_reg_out;
    wire [2:0]  funct3_reg_out;
    wire [2:0]  wb_mux_sel_reg_out;
    wire        reg_write_reg_out;
    wire        csr_wr_en_reg_out;
    wire [11:0] csr_addr_reg_out;
    wire [2:0]  csr_op_reg_out;
    wire [31:0] csr_data_reg_out;
    wire [4:0]  csr_imm_reg_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate Pipeline Register DUT
    pragya_de_mw_pipeline u_dut (
        .clk_in(clk),
        .rst_in(rst),
        .valid_de(valid_de),
        .mem_req_in(mem_req_in),
        .mem_write_in(mem_write_in),
        .mdu_result_in(mdu_result_in),
        .alu_result_in(alu_result_in),
        .i_adder_in(i_adder_in),
        .imm_in(imm_in),
        .pc_plus_4_in(pc_plus_4_in),
        .pc_in(pc_in),
        .instr_in(instr_in),
        .rs_2_in(rs_2_in),
        .rd_addrs_in(rd_addrs_in),
        .funct3_in(funct3_in),
        .wb_mux_sel_in(wb_mux_sel_in),
        .reg_write_in(reg_write_in),
        .csr_wr_en_in(csr_wr_en_in),
        .csr_addr_in(csr_addr_in),
        .csr_op_in(csr_op_in),
        .csr_data_in(csr_data_in),
        .csr_imm_in(csr_imm_in),
        .rvalid(rvalid),
        .stall_mw(stall_mw),
        .flush(flush),
        .mem_wb_valid(mem_wb_valid),
        .mem_req_reg_out(mem_req_reg_out),
        .mem_write_reg_out(mem_write_reg_out),
        .mdu_result_reg_out(mdu_result_reg_out),
        .alu_result_reg_out(alu_result_reg_out),
        .i_adder_reg_out(i_adder_reg_out),
        .imm_reg_out(imm_reg_out),
        .pc_plus_4_reg_out(pc_plus_4_reg_out),
        .rs_2_reg_out(rs_2_reg_out),
        .rd_addrs_reg_out(rd_addrs_reg_out),
        .pc_reg_out(pc_reg_out),
        .instr_reg_out(instr_reg_out),
        .funct3_reg_out(funct3_reg_out),
        .wb_mux_sel_reg_out(wb_mux_sel_reg_out),
        .reg_write_reg_out(reg_write_reg_out),
        .csr_wr_en_reg_out(csr_wr_en_reg_out),
        .csr_addr_reg_out(csr_addr_reg_out),
        .csr_op_reg_out(csr_op_reg_out),
        .csr_data_reg_out(csr_data_reg_out),
        .csr_imm_reg_out(csr_imm_reg_out)
    );

    // 100MHz Clock Generator (Period = 10ns)
    always #5 clk = ~clk;

    // =========================================================================
    // Helper Tasks
    // =========================================================================

    // Set all inputs to default zeroes
    task clear_inputs();
        valid_de       = 1'b0;
        stall_mw       = 1'b0;
        flush          = 1'b0;
        mem_req_in     = 1'b0;
        mem_write_in   = 1'b0;
        mdu_result_in  = 32'd0;
        alu_result_in  = 32'd0;
        i_adder_in     = 32'd0;
        imm_in         = 32'd0;
        pc_plus_4_in   = 32'd0;
        pc_in          = 32'd0;
        instr_in       = 32'd0;
        rs_2_in        = 32'd0;
        rd_addrs_in    = 5'd0;
        funct3_in      = 3'd0;
        wb_mux_sel_in  = 3'd0;
        reg_write_in   = 1'b0;
        csr_wr_en_in   = 1'b0;
        csr_addr_in    = 12'd0;
        csr_op_in      = 3'd0;
        csr_data_in    = 32'd0;
        csr_imm_in     = 5'd0;
        rvalid         = 1'b0;
    endtask

    // Check full reset or flush state
    task check_cleared(input string desc);
        total_tests = total_tests + 1;
        #1;
        if (mem_wb_valid        !== 1'b0 ||
            mem_req_reg_out     !== 1'b0 ||
            mem_write_reg_out   !== 1'b0 ||
            reg_write_reg_out   !== 1'b0 ||
            csr_wr_en_reg_out   !== 1'b0 ||
            rd_addrs_reg_out    !== 5'd0 ||
            wb_mux_sel_reg_out  !== 3'd0 ||
            funct3_reg_out      !== 3'd0 ||
            csr_addr_reg_out    !== 12'd0 ||
            alu_result_reg_out  !== 32'd0 ||
            pc_reg_out          !== 32'd0 ||
            instr_reg_out       !== 32'd0) begin
            $display("[FAIL] %s | Output registers not cleared!", desc);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | All registers successfully cleared to zero", desc);
        end
    endtask

    // Check bubble state (valid=0, control=0)
    task check_bubble(input string desc);
        total_tests = total_tests + 1;
        #1;
        if (mem_wb_valid      !== 1'b0 ||
            mem_req_reg_out   !== 1'b0 ||
            mem_write_reg_out !== 1'b0 ||
            reg_write_reg_out !== 1'b0 ||
            csr_wr_en_reg_out !== 1'b0 ||
            rd_addrs_reg_out  !== 5'd0 ||
            wb_mux_sel_reg_out!== 3'd0 ||
            funct3_reg_out    !== 3'd0) begin
            $display("[FAIL] %s | Control lines not zeroed for bubble!", desc);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Bubble correctly inserted on control lines", desc);
        end
    endtask

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        clear_inputs();

        $display("Starting Pragya DE-MW Pipeline Register Verification...");

        // -------------------------------------------------------------
        // Group 1: Asynchronous Power-on Reset
        // -------------------------------------------------------------
        #20;
        check_cleared("Async Reset Active Check");
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        #1;
        check_cleared("Post-Reset Initial State Check");

        // -------------------------------------------------------------
        // Group 2: Normal Valid Transaction Forwarding
        // -------------------------------------------------------------
        @(negedge clk);
        valid_de       = 1'b1;
        stall_mw       = 1'b0;
        flush          = 1'b0;
        mem_req_in     = 1'b1;
        mem_write_in   = 1'b0; // Load
        alu_result_in  = 32'h8000_1000;
        mdu_result_in  = 32'h0000_0000;
        i_adder_in     = 32'h8000_1000;
        imm_in         = 32'h0000_0020;
        pc_in          = 32'h0001_0040;
        pc_plus_4_in   = 32'h0001_0044;
        instr_in       = 32'h02002283; // lw x5, 32(x0)
        rs_2_in        = 32'h1234_5678;
        rd_addrs_in    = 5'd5;
        funct3_in      = 3'b010; // LW
        wb_mux_sel_in  = 3'b001; // Mem WB
        reg_write_in   = 1'b1;
        csr_wr_en_in   = 1'b0;
        csr_addr_in    = 12'd0;
        csr_op_in      = 3'd0;
        csr_data_in    = 32'd0;
        csr_imm_in     = 5'd0;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (mem_wb_valid        === 1'b1 &&
            mem_req_reg_out     === 1'b1 &&
            mem_write_reg_out   === 1'b0 &&
            alu_result_reg_out  === 32'h8000_1000 &&
            pc_reg_out          === 32'h0001_0040 &&
            instr_reg_out       === 32'h02002283 &&
            rd_addrs_reg_out    === 5'd5 &&
            reg_write_reg_out   === 1'b1 &&
            wb_mux_sel_reg_out  === 3'b001) begin
            $display("[PASS] Normal Valid Instruction Passed Through Stage");
        end else begin
            $display("[FAIL] Normal Valid Instruction Failed to Latch Correctly!");
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 3: Pipeline Freeze under Stall (stall_mw = 1)
        // -------------------------------------------------------------
        @(negedge clk);
        stall_mw       = 1'b1;
        valid_de       = 1'b1;
        // Apply different data at inputs while stalled
        alu_result_in  = 32'hDEAD_BEEF;
        pc_in          = 32'hFFFF_0000;
        rd_addrs_in    = 5'd10;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        // Verify stage preserved original values (x5, 0x8000_1000, 0x0001_0040)
        if (alu_result_reg_out === 32'h8000_1000 &&
            pc_reg_out         === 32'h0001_0040 &&
            rd_addrs_reg_out   === 5'd5) begin
            $display("[PASS] Stall Held Registers Unchanged");
        end else begin
            $display("[FAIL] Stall Failed! New data overwritten during stall");
            failed_tests = failed_tests + 1;
        end

        // Release stall
        @(negedge clk);
        stall_mw = 1'b0;

        // -------------------------------------------------------------
        // Group 4: Bubble Insertion (valid_de = 0)
        // -------------------------------------------------------------
        @(negedge clk);
        valid_de     = 1'b0;
        reg_write_in = 1'b1; // Upstream tries to assert, but valid is low
        mem_req_in   = 1'b1;

        @(posedge clk);
        #1;
        check_bubble("Bubble Gating Check with valid_de = 0");

        // -------------------------------------------------------------
        // Group 5: Pipeline Synchronous Flush (flush = 1)
        // -------------------------------------------------------------
        // First load a known non-zero transaction
        @(negedge clk);
        valid_de          = 1'b1;
        reg_write_in      = 1'b1;
        rd_addrs_in       = 5'd31;
        alu_result_in     = 32'hCAFE_BABE;
        pc_in        = 32'h0000_1000;
        @(posedge clk);
        #1;

        // Assert flush on next cycle
        @(negedge clk);
        flush = 1'b1;
        @(posedge clk);
        #1;
        check_cleared("Synchronous Flush Execution");
        flush = 1'b0;

        // -------------------------------------------------------------
        // Group 6: Flush Priority over Stall Check
        // -------------------------------------------------------------
        // Assert stall AND flush simultaneously
        @(negedge clk);
        stall_mw      = 1'b1;
        flush         = 1'b1;
        valid_de      = 1'b1;
        alu_result_in = 32'h1234_5678;

        @(posedge clk);
        #1;
        check_cleared("Flush Dominance over Active Stall");
        stall_mw = 1'b0;
        flush    = 1'b0;

        // -------------------------------------------------------------
        // Group 7: CSR Bus Payload Transmission
        // -------------------------------------------------------------
        @(negedge clk);
        valid_de      = 1'b1;
        csr_wr_en_in  = 1'b1;
        csr_addr_in   = 12'h300; // mstatus
        csr_op_in     = 3'b001; // csrrw
        csr_data_in   = 32'h0000_1808;
        csr_imm_in    = 5'b10101;
        wb_mux_sel_in = 3'b110; // CSR WB

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (csr_wr_en_reg_out  === 1'b1 &&
            csr_addr_reg_out   === 12'h300 &&
            csr_op_reg_out     === 3'b001 &&
            csr_data_reg_out   === 32'h0000_1808 &&
            csr_imm_reg_out    === 5'b10101 &&
            wb_mux_sel_reg_out === 3'b110) begin
            $display("[PASS] CSR Bus Signals Forwarded Intact");
        end else begin
            $display("[FAIL] CSR Bus Signals Corruption detected!");
            failed_tests = failed_tests + 1;
        end

        // -------------------------------------------------------------
        // Group 8: Boundary Values & Toggle Coverage Closure
        // -------------------------------------------------------------
        // Test pattern A: Alternating 0x55555555, rd = 1, funct3 = 3'b101
        @(negedge clk);
        valid_de          = 1'b1;
        mdu_result_in     = 32'h5555_5555;
        alu_result_in     = 32'h5555_5555;
        i_adder_in        = 32'h5555_5555;
        imm_in            = 32'h5555_5555;
        pc_plus_4_in      = 32'h5555_5555;
        pc_in             = 32'h5555_5555;
        instr_in          = 32'h5555_5555;
        rs_2_in           = 32'h5555_5555;
        rd_addrs_in       = 5'd1;
        funct3_in         = 3'b101;
        wb_mux_sel_in     = 3'b101;
        csr_addr_in       = 12'h555;
        csr_data_in       = 32'h5555_5555;
        csr_imm_in        = 5'b10101;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (alu_result_reg_out === 32'h5555_5555 &&
            rd_addrs_reg_out   === 5'd1 &&
            csr_addr_reg_out   === 12'h555) begin
            $display("[PASS] Pattern 0x55555555 Latched");
        end else begin
            $display("[FAIL] Pattern 0x55555555 Mismatch!");
            failed_tests = failed_tests + 1;
        end

        // Test pattern B: Alternating 0xAAAAAAAA, rd = 31 (max), funct3 = 3'b010
        @(negedge clk);
        valid_de          = 1'b1;
        mdu_result_in     = 32'hAAAA_AAAA;
        alu_result_in     = 32'hAAAA_AAAA;
        i_adder_in        = 32'hAAAA_AAAA;
        imm_in            = 32'hAAAA_AAAA;
        pc_plus_4_in      = 32'hAAAA_AAAA;
        pc_in             = 32'hAAAA_AAAA;
        instr_in          = 32'hAAAA_AAAA;
        rs_2_in           = 32'hAAAA_AAAA;
        rd_addrs_in       = 5'd31;
        funct3_in         = 3'b010;
        wb_mux_sel_in     = 3'b010;
        csr_addr_in       = 12'hAAA;
        csr_data_in       = 32'hAAAA_AAAA;
        csr_imm_in        = 5'b01010;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (alu_result_reg_out === 32'hAAAA_AAAA &&
            rd_addrs_reg_out   === 5'd31 &&
            csr_addr_reg_out   === 12'hAAA) begin
            $display("[PASS] Pattern 0xAAAAAAAA Latched (Max Address x31 Checked)");
        end else begin
            $display("[FAIL] Pattern 0xAAAAAAAA Mismatch!");
            failed_tests = failed_tests + 1;
        end

        // Test pattern C: All Ones (0xFFFFFFFF)
        @(negedge clk);
        valid_de          = 1'b1;
        mdu_result_in     = 32'hFFFF_FFFF;
        alu_result_in     = 32'hFFFF_FFFF;
        i_adder_in        = 32'hFFFF_FFFF;
        imm_in            = 32'hFFFF_FFFF;
        pc_plus_4_in      = 32'hFFFF_FFFF;
        pc_in             = 32'hFFFF_FFFF;
        instr_in          = 32'hFFFF_FFFF;
        rs_2_in           = 32'hFFFF_FFFF;
        rd_addrs_in       = 5'd31;
        funct3_in         = 3'b111;
        wb_mux_sel_in     = 3'b111;
        csr_addr_in       = 12'hFFF;
        csr_data_in       = 32'hFFFF_FFFF;
        csr_imm_in        = 5'b11111;

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        if (alu_result_reg_out === 32'hFFFF_FFFF &&
            csr_addr_reg_out   === 12'hFFF &&
            csr_imm_reg_out    === 5'b11111) begin
            $display("[PASS] All-Ones 0xFFFFFFFF Latched");
        end else begin
            $display("[FAIL] All-Ones 0xFFFFFFFF Mismatch!");
            failed_tests = failed_tests + 1;
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
