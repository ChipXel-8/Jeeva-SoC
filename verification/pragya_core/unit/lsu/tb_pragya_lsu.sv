`timescale 1ns / 1ps

module tb_pragya_lsu;

    // Clock and Reset
    reg clk;
    reg rst;

    // Processor Core Interface
    reg        mem_req;
    reg        mem_write;
    reg [2:0]  funct3;
    reg [31:0] addr_in;
    reg [31:0] rs2_data;

    // Data Memory Bus Interface
    reg        dm_rvalid;
    reg [31:0] dm_rdata;

    // DUT Outputs
    wire        dmreq_out;
    wire        dmwen_out;
    wire [3:0]  dmbe_out;
    wire [31:0] dmaddr_out;
    wire [31:0] dmdata_out;
    wire [31:0] load_data_out;

    // Pass / Fail Counters
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate LSU DUT
    pragya_lsu u_dut (
        .clk_in(clk),
        .rst_in(rst),
        .mem_req_in(mem_req),
        .mem_write_in(mem_write),
        .funct3_in(funct3),
        .i_adder_in(addr_in),
        .rs_2_in(rs2_data),
        .dm_rvalid_in(dm_rvalid),
        .dm_rdata_in(dm_rdata),
        .pg_riscv32_mp_dmreq_out(dmreq_out),
        .pg_riscv32_mp_dmwen_out(dmwen_out),
        .pg_riscv32_mp_dmbe_out(dmbe_out),
        .pg_riscv32_mp_dmaddr_out(dmaddr_out),
        .pg_riscv32_mp_dmdata_out(dmdata_out),
        .load_data_out(load_data_out)
    );

    // 100MHz Clock (10ns period)
    always #5 clk = ~clk;

    // funct3 encodings
    localparam [2:0] F3_LB  = 3'b000;
    localparam [2:0] F3_LH  = 3'b001;
    localparam [2:0] F3_LW  = 3'b010;
    localparam [2:0] F3_LBU = 3'b100;
    localparam [2:0] F3_LHU = 3'b101;
    localparam [2:0] F3_SB  = 3'b000;
    localparam [2:0] F3_SH  = 3'b001;
    localparam [2:0] F3_SW  = 3'b010;

    // =========================================================================
    // Helper Tasks
    // =========================================================================

    // Test a store request (combinational output checks)
    task test_store(
        input [2:0]  op_type,
        input [31:0] target_addr,
        input [31:0] data_to_store,
        input [3:0]  exp_be,
        input [31:0] exp_mem_data,
        input string test_name
    );
        total_tests = total_tests + 1;
        mem_req   = 1'b1;
        mem_write = 1'b1;
        funct3    = op_type;
        addr_in   = target_addr;
        rs2_data  = data_to_store;
        #1; // Wait for combinational logic

        if (dmreq_out !== 1'b1 || dmwen_out !== 1'b1 ||
            dmbe_out !== exp_be || dmdata_out !== exp_mem_data ||
            dmaddr_out !== {target_addr[31:2], 2'b00}) begin
            $display("[FAIL] %s | Addr:0x%08h -> Got: BE=%b Data=0x%08h | Exp: BE=%b Data=0x%08h",
                     test_name, target_addr, dmbe_out, dmdata_out, exp_be, exp_mem_data);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Addr:0x%08h BE=%b StoreData=0x%08h",
                     test_name, target_addr, dmbe_out, dmdata_out);
        end
    endtask

    // Test a load operation (clocked register latch check)
    task test_load(
        input [2:0]  op_type,
        input [31:0] target_addr,
        input [31:0] raw_memory_data,
        input [31:0] exp_load_result,
        input string test_name
    );
        total_tests = total_tests + 1;
        @(negedge clk);
        mem_req   = 1'b1;
        mem_write = 1'b0; // Load
        funct3    = op_type;
        addr_in   = target_addr;
        dm_rdata  = raw_memory_data;
        dm_rvalid = 1'b1;

        @(posedge clk);
        #1;
        dm_rvalid = 1'b0; // Pulse valid for 1 cycle

        if (load_data_out !== exp_load_result) begin
            $display("[FAIL] %s | Got: 0x%08h, Expected: 0x%08h", test_name, load_data_out, exp_load_result);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | Load Result: 0x%08h (%0d)", test_name, load_data_out, $signed(load_data_out));
        end
    endtask

    // =========================================================================
    // Main Verification Flow
    // =========================================================================
    initial begin
        clk       = 0;
        rst       = 1;
        mem_req   = 0;
        mem_write = 0;
        funct3    = 0;
        addr_in   = 0;
        rs2_data  = 0;
        dm_rvalid = 0;
        dm_rdata  = 0;

        $display("Starting Pragya LSU Verification...");

        // -------------------------------------------------------------
        // Group 1: Reset Check
        // -------------------------------------------------------------
        #15;
        @(posedge clk);
        rst = 0;
        #1;
        total_tests = total_tests + 1;
        if (load_data_out !== 32'd0) begin
            $display("[FAIL] Reset Failed: load_data_out not zero!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Reset State: load_data_out is 0");
        end

        // -------------------------------------------------------------
        // Group 2: Store Byte (SB) Across All 4 Byte Alignments
        // -------------------------------------------------------------
        // Byte 0: Address ending in 2'b00 -> BE = 4'b0001
        test_store(F3_SB, 32'h1000_0000, 32'h0000_00AB, 4'b0001, 32'h0000_00AB, "SB Byte 0 (offset 0)");

        // Byte 1: Address ending in 2'b01 -> BE = 4'b0010
        test_store(F3_SB, 32'h1000_0001, 32'h0000_00CD, 4'b0010, 32'h0000_CD00, "SB Byte 1 (offset 1)");

        // Byte 2: Address ending in 2'b10 -> BE = 4'b0100
        test_store(F3_SB, 32'h1000_0002, 32'h0000_00EF, 4'b0100, 32'h00EF_0000, "SB Byte 2 (offset 2)");

        // Byte 3: Address ending in 2'b11 -> BE = 4'b1000
        test_store(F3_SB, 32'h1000_0003, 32'h0000_0055, 4'b1000, 32'h5500_0000, "SB Byte 3 (offset 3)");

        // -------------------------------------------------------------
        // Group 3: Store Halfword (SH) and Store Word (SW)
        // -------------------------------------------------------------
        // Lower Halfword: Address ending in 2'b00 -> BE = 4'b0011
        test_store(F3_SH, 32'h1000_0000, 32'h0000_1234, 4'b0011, 32'h0000_1234, "SH Lower Halfword (offset 0)");

        // Upper Halfword: Address ending in 2'b10 -> BE = 4'b1100
        test_store(F3_SH, 32'h1000_0002, 32'h0000_5678, 4'b1100, 32'h5678_0000, "SH Upper Halfword (offset 2)");

        // Full Word: Address ending in 2'b00 -> BE = 4'b1111
        test_store(F3_SW, 32'h1000_0000, 32'hA5A5_5A5A, 4'b1111, 32'hA5A5_5A5A, "SW Full Word (offset 0)");

        // -------------------------------------------------------------
        // Group 4: Write Disable Gating on Loads
        // -------------------------------------------------------------
        mem_req   = 1'b1;
        mem_write = 1'b0; // Load request
        addr_in   = 32'h1000_0000;
        #1;
        total_tests = total_tests + 1;
        if (dmwen_out !== 1'b0 || dmbe_out !== 4'b0000 || dmdata_out !== 32'd0) begin
            $display("[FAIL] Load Request Leaked Write Signals!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] Load Request Correctly Disables Write and Clears BE/Data");
        end

        // -------------------------------------------------------------
        // Group 5: Load Byte (LB - Signed) vs Load Byte Unsigned (LBU)
        // Raw memory contains: 0x44_33_80_12
        // -------------------------------------------------------------
        // Positive byte at offset 0: 0x12 -> Both LB and LBU give +18 (0x00000012)
        test_load(F3_LB,  32'h2000_0000, 32'h44338012, 32'h0000_0012, "LB Positive Byte (offset 0)");
        test_load(F3_LBU, 32'h2000_0000, 32'h44338012, 32'h0000_0012, "LBU Positive Byte (offset 0)");

        // Negative byte at offset 1: 0x80 (-128)
        // LB should sign extend -> 0xFFFFFF80
        test_load(F3_LB,  32'h2000_0001, 32'h44338012, 32'hFFFF_FF80, "LB Negative Byte Sign Extension (offset 1)");
        // LBU should zero extend -> 0x00000080
        test_load(F3_LBU, 32'h2000_0001, 32'h44338012, 32'h0000_0080, "LBU Zero Extension (offset 1)");

        // Byte extraction at offset 2 (0x33) and offset 3 (0x44)
        test_load(F3_LB,  32'h2000_0002, 32'h44338012, 32'h0000_0033, "LB Byte extraction (offset 2)");
        test_load(F3_LB,  32'h2000_0003, 32'h44338012, 32'h0000_0044, "LB Byte extraction (offset 3)");

        // -------------------------------------------------------------
        // Group 6: Load Halfword (LH - Signed) vs Load Halfword Unsigned (LHU)
        // Raw memory contains: 0x8004_0020
        // -------------------------------------------------------------
        // Lower halfword: 0x0020 -> Positive (+32)
        test_load(F3_LH,  32'h3000_0000, 32'h80040020, 32'h0000_0020, "LH Positive Halfword (offset 0)");
        test_load(F3_LHU, 32'h3000_0000, 32'h80040020, 32'h0000_0020, "LHU Positive Halfword (offset 0)");

        // Upper halfword: 0x8004 -> Negative
        // LH must sign extend -> 0xFFFF8004
        test_load(F3_LH,  32'h3000_0002, 32'h80040020, 32'hFFFF_8004, "LH Negative Halfword Sign Extension (offset 2)");
        // LHU must zero extend -> 0x00008004
        test_load(F3_LHU, 32'h3000_0002, 32'h80040020, 32'h0000_8004, "LHU Zero Extension (offset 2)");

        // -------------------------------------------------------------
        // Group 7: Load Word (LW)
        // -------------------------------------------------------------
        test_load(F3_LW,  32'h4000_0000, 32'hDEAD_BEEF, 32'hDEAD_BEEF, "LW Full Word");

        // -------------------------------------------------------------
        // Group 8: Data Hold Check (dm_rvalid_in = 0)
        // -------------------------------------------------------------
        @(negedge clk);
        dm_rvalid = 1'b0;
        dm_rdata  = 32'h1111_1111; // Present new data while valid is 0

        @(posedge clk);
        #1;
        total_tests = total_tests + 1;
        // Output must still hold 0xDEAD_BEEF from previous test
        if (load_data_out !== 32'hDEAD_BEEF) begin
            $display("[FAIL] LSU overwritten when dm_rvalid_in was 0!");
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] LSU Held Previous Data Steady When dm_rvalid_in=0");
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