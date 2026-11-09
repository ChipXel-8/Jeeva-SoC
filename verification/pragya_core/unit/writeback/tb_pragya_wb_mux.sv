`timescale 1ns / 1ps

module tb_pragya_wb_mux;

    // DUT Inputs
    reg  [31:0] alu_result;
    reg  [31:0] load_data;
    reg  [31:0] pc_plus4;
    reg  [31:0] imm;
    reg  [31:0] i_adder;
    reg  [31:0] mdu_result;
    reg  [31:0] csr_data;
    reg  [2:0]  wb_mux_sel;

    // DUT Output
    wire [31:0] wb_mux_out;

    // Test Tracking
    integer total_tests  = 0;
    integer failed_tests = 0;

    // Instantiate DUT
    pragya_wb_mux u_dut (
        .alu_result_in(alu_result),
        .load_data_in(load_data),
        .pc_plus4_in(pc_plus4),
        .imm_in(imm),
        .i_adder_in(i_adder),
        .mdu_result_in(mdu_result),
        .csr_data_in(csr_data),
        .wb_mux_sel_in(wb_mux_sel),
        .wb_mux_out(wb_mux_out)
    );

    // Mux Select Constants
    localparam [2:0] SEL_ALU     = 3'b000;
    localparam [2:0] SEL_LOAD    = 3'b001;
    localparam [2:0] SEL_PC4     = 3'b010;
    localparam [2:0] SEL_LUI     = 3'b011;
    localparam [2:0] SEL_AUIPC   = 3'b100;
    localparam [2:0] SEL_MDU     = 3'b101;
    localparam [2:0] SEL_CSR     = 3'b110;
    localparam [2:0] SEL_DEFAULT = 3'b111;

    // Helper task to clear all inputs
    task clear_inputs();
        alu_result = 32'd0;
        load_data  = 32'd0;
        pc_plus4   = 32'd0;
        imm        = 32'd0;
        i_adder    = 32'd0;
        mdu_result = 32'd0;
        csr_data   = 32'd0;
        wb_mux_sel = 3'd0;
    endtask

    // Simple Verification Task
    task check_mux(
        input [2:0]  sel,
        input [31:0] exp_data,
        input string test_name
    );
        total_tests = total_tests + 1;
        wb_mux_sel = sel;
        #1; // Combinational propagation delay

        if (wb_mux_out !== exp_data) begin
            $display("[FAIL] %s | sel=%b -> Got: 0x%08h, Expected: 0x%08h", test_name, sel, wb_mux_out, exp_data);
            failed_tests = failed_tests + 1;
        end else begin
            $display("[PASS] %s | sel=%b -> Out: 0x%08h", test_name, sel, wb_mux_out);
        end
    endtask

    initial begin
        clear_inputs();

        $display("Starting Pragya WB MUX Verification...");

        // =============================================================
        // 1. ALL 7 FUNCTIONAL CHANNEL PATHS
        // =============================================================
        alu_result = 32'hAAAA_0001;
        load_data  = 32'hBBBB_0002;
        pc_plus4   = 32'hCCCC_0003;
        imm        = 32'hDDDD_0004;
        i_adder    = 32'hEEEE_0005;
        mdu_result = 32'h1111_0006;
        csr_data   = 32'h2222_0007;

        check_mux(SEL_ALU,   32'hAAAA_0001, "Channel 0 (ALU Result)");
        check_mux(SEL_LOAD,  32'hBBBB_0002, "Channel 1 (Load Data)");
        check_mux(SEL_PC4,   32'hCCCC_0003, "Channel 2 (PC + 4 Return Addr)");
        check_mux(SEL_LUI,   32'hDDDD_0004, "Channel 3 (LUI Immediate)");
        check_mux(SEL_AUIPC, 32'hEEEE_0005, "Channel 4 (AUIPC i_adder)");
        check_mux(SEL_MDU,   32'h1111_0006, "Channel 5 (MDU Result)");
        check_mux(SEL_CSR,   32'h2222_0007, "Channel 6 (CSR Data)");

        // =============================================================
        // 2. DEFAULT / UNUSED SELECT (3'b111)
        // =============================================================
        check_mux(SEL_DEFAULT, 32'h0000_0000, "Channel 7 Default (Forces 32'b0)");

        // =============================================================
        // 3. UNSELECTED CHANNEL ISOLATION (GLITCH / LEAKAGE IMMUNITY)
        // =============================================================
        wb_mux_sel = SEL_ALU;
        load_data  = 32'hFFFF_FFFF;
        pc_plus4   = 32'hFFFF_FFFF;
        imm        = 32'hFFFF_FFFF;
        i_adder    = 32'hFFFF_FFFF;
        mdu_result = 32'hFFFF_FFFF;
        csr_data   = 32'hFFFF_FFFF;
        check_mux(SEL_ALU, 32'hAAAA_0001, "Isolation Check: Other inputs = 0xFFFFFFFF");

        csr_data   = 32'h2222_0007;
        wb_mux_sel = SEL_CSR;
        alu_result = 32'h0000_0000;
        check_mux(SEL_CSR, 32'h2222_0007, "Isolation Check: ALU = 0x00000000");

        // =============================================================
        // 4. EXTREME DATA BOUNDARY PATTERNS (ALL-0, ALL-1, CHECKERBOARD)
        // =============================================================
        clear_inputs();
        alu_result = 32'hFFFF_FFFF;
        load_data  = 32'hFFFF_FFFF;
        pc_plus4   = 32'hFFFF_FFFF;
        imm        = 32'hFFFF_FFFF;
        i_adder    = 32'hFFFF_FFFF;
        mdu_result = 32'hFFFF_FFFF;
        csr_data   = 32'hFFFF_FFFF;

        check_mux(SEL_ALU,  32'hFFFF_FFFF, "Boundary: All-1s on ALU");
        check_mux(SEL_LOAD, 32'hFFFF_FFFF, "Boundary: All-1s on Load");

        alu_result = 32'h5555_5555;
        load_data  = 32'hAAAA_AAAA;
        check_mux(SEL_ALU,  32'h5555_5555, "Pattern: 0x55555555 on ALU");
        check_mux(SEL_LOAD, 32'hAAAA_AAAA, "Pattern: 0xAAAAAAAA on Load");

        // =============================================================
        // 5. WALKING 1s TOGGLE CLOSURE ACROSS ALL CHANNELS
        // =============================================================
        clear_inputs();
        for (int b = 0; b < 32; b = b + 1) begin
            alu_result = (32'h1 << b);
            check_mux(SEL_ALU, (32'h1 << b), "Walking 1 on ALU Result");

            load_data = (32'h1 << b);
            check_mux(SEL_LOAD, (32'h1 << b), "Walking 1 on Load Data");

            csr_data = (32'h1 << b);
            check_mux(SEL_CSR, (32'h1 << b), "Walking 1 on CSR Data");
        end

        // =============================================================
        // SUMMARY
        // =============================================================
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
