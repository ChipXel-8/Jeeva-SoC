`timescale 1ns/1ps

// ============================================================
// Phase 1: Passive SoC bus monitor and functional coverage
// DUT is not driven by this module.
// Compatible with the hierarchy supplied for soc_top/axi_bus/
// peripherals_top. Compile with SystemVerilog coverage enabled.
// ============================================================

module soc_phase1_monitor (
    input logic clk,
    input logic rst_n,

    // ---------------- OBI system data bus ----------------
    input logic        sys_req,
    input logic        sys_gnt,
    input logic        sys_we,
    input logic [3:0]  sys_be,
    input logic [31:0] sys_addr,
    input logic [2:0]  data_demux_sel,
    input logic        core_data_req,
    input logic        sba_data_req,

    // ---------------- Core instruction bus ----------------
    input logic        instr_req,
    input logic        instr_gnt,
    input logic [31:0] instr_addr,
    input logic [1:0]  instr_demux_sel,

    // ---------------- IMEM shared arbitration ----------------
    input logic        sram_req,
    input logic        sram_gnt,
    input logic        sba_imem_access,
    input logic        sram_rvalid,
    input logic        effective_sba_rvalid,

    // ---------------- AXI-Lite channels ----------------
    input logic        axi_awvalid,
    input logic        axi_awready,
    input logic [31:0] axi_awaddr,
    input logic        axi_wvalid,
    input logic        axi_wready,
    input logic [31:0] axi_wdata,
    input logic [3:0]  axi_wstrb,
    input logic        axi_bvalid,
    input logic        axi_bready,

    input logic        axi_arvalid,
    input logic        axi_arready,
    input logic [31:0] axi_araddr,
    input logic        axi_rvalid,
    input logic        axi_rready,
    input logic [31:0] axi_rdata,

    // ---------------- APB signals ----------------
    input logic [31:0] apb_paddr,
    input logic [5:0]  apb_pselx,
    input logic        apb_penable,
    input logic        apb_pwrite,
    input logic [3:0]  apb_pstrb,
    input logic [31:0] apb_pwdata,
    input logic [5:0]  apb_pready_vec,
    input logic [5:0]  apb_pslverr_vec
);

    // --------------------------------------------------------
    // Address classification helpers
    // --------------------------------------------------------
wire apb_selected_pready =
    |(apb_pselx & apb_pready_vec);

wire apb_selected_pslverr =
    |(apb_pselx & apb_pslverr_vec);

wire apb_complete =
    rst_n && (|apb_pselx) &&
    apb_penable && apb_selected_pready;
    logic [2:0] data_region;
    logic [1:0] instruction_region;
    logic [2:0] peripheral_region;
    logic [1:0] data_master;

    // data_region:
    // 0=DMEM, 1=CLINT, 2=AXI/APB, 3=IMEM, 4=Debug, 5=unmapped
    always_comb begin
        if ((sys_addr >= 32'h2000_0000) &&
            (sys_addr <  32'h2001_0000))
            data_region = 3'd0;
        else if ((sys_addr >= 32'h3000_0000) &&
                 (sys_addr <  32'h3000_1000))
            data_region = 3'd1;
        else if ((sys_addr >= 32'h4000_0000) &&
                 (sys_addr <  32'h4000_6000))
            data_region = 3'd2;
        else if ((sys_addr >= 32'h0000_1000) &&
                 (sys_addr <  32'h0000_9000))
            data_region = 3'd3;
        else if (((sys_addr >= 32'h1A11_0000) &&
                  (sys_addr <  32'h1A12_0000)) ||
                 ((sys_addr >= 32'h0000_0300) &&
                  (sys_addr <  32'h0000_0400)))
            data_region = 3'd4;
        else
            data_region = 3'd5;
    end

    // Match the instruction decoder in axi_bus:
    // 0=IMEM/default, 1=BootROM, 2=Debug.
    always_comb begin
        if (((instr_addr & 32'hFFFF_F000) == 32'h1A11_0000) ||
            ((instr_addr >= 32'h0000_0300) &&
             (instr_addr <  32'h0000_0400)))
            instruction_region = 2'd2;
        else if (instr_addr < 32'h0000_1000)
            instruction_region = 2'd1;
        else
            instruction_region = 2'd0;
    end

    // peripheral_region:
    // 0=UART, 1=I2C, 2=SPI, 3=GPIO, 4=Timer, 5=PLIC, 6=unmapped
    always_comb begin
        if ((apb_paddr >= 32'h4000_0000) &&
            (apb_paddr <  32'h4000_1000))
            peripheral_region = 3'd0;
        else if ((apb_paddr >= 32'h4000_1000) &&
                 (apb_paddr <  32'h4000_2000))
            peripheral_region = 3'd1;
        else if ((apb_paddr >= 32'h4000_2000) &&
                 (apb_paddr <  32'h4000_3000))
            peripheral_region = 3'd2;
        else if ((apb_paddr >= 32'h4000_3000) &&
                 (apb_paddr <  32'h4000_4000))
            peripheral_region = 3'd3;
        else if ((apb_paddr >= 32'h4000_4000) &&
                 (apb_paddr <  32'h4000_5000))
            peripheral_region = 3'd4;
        else if ((apb_paddr >= 32'h4000_5000) &&
                 (apb_paddr <  32'h4000_6000))
            peripheral_region = 3'd5;
        else
            peripheral_region = 3'd6;
    end

    // 0=Core only, 1=SBA only, 2=both requesting concurrently.
    always_comb begin
        if (core_data_req && sba_data_req)
            data_master = 2'd2;
        else if (sba_data_req)
            data_master = 2'd1;
        else
            data_master = 2'd0;
    end

    wire data_accept  = rst_n && sys_req && sys_gnt;
    wire instr_accept = rst_n && instr_req && instr_gnt;
    wire imem_accept  = rst_n && sram_req && sram_gnt;

    // --------------------------------------------------------
    // OBI data-bus functional coverage
    // --------------------------------------------------------
    covergroup obi_data_cg @(posedge clk);
        option.per_instance = 1;

        cp_target: coverpoint data_demux_sel iff (data_accept) {
            bins dmem  = {3'd0};
            bins clint = {3'd1};
            bins axi   = {3'd2};
            bins imem  = {3'd3};
            bins debug = {3'd4};
            bins other = default;
        }

        cp_address_region: coverpoint data_region iff (data_accept) {
            bins dmem      = {3'd0};
            bins clint     = {3'd1};
            bins axi_apb   = {3'd2};
            bins imem      = {3'd3};
            bins debug     = {3'd4};
            bins unmapped  = {3'd5};
        }

        cp_operation: coverpoint sys_we iff (data_accept) {
            bins read  = {1'b0};
            bins write = {1'b1};
        }

        cp_byte_enable: coverpoint sys_be iff (data_accept && sys_we) {
            bins byte0 = {4'b0001};
            bins byte1 = {4'b0010};
            bins byte2 = {4'b0100};
            bins byte3 = {4'b1000};
            bins half0 = {4'b0011};
            bins half1 = {4'b1100};
            bins word  = {4'b1111};
            bins other = default;
        }

        cp_master: coverpoint data_master iff (data_accept) {
            bins core_only = {2'd0};
            bins sba_only  = {2'd1};
            bins contention = {2'd2};
        }

        target_x_operation: cross cp_target, cp_operation;
        master_x_target: cross cp_master, cp_target;
        region_x_operation: cross cp_address_region, cp_operation;
    endgroup

    obi_data_cg obi_data_cov = new();

    // --------------------------------------------------------
    // Instruction-bus functional coverage
    // --------------------------------------------------------
    covergroup instruction_cg @(posedge clk);
        option.per_instance = 1;

        cp_target: coverpoint instr_demux_sel iff (instr_accept) {
            bins imem   = {2'd0};
            bins bootrom = {2'd1};
            bins debug  = {2'd2};
            bins other  = default;
        }

        cp_region: coverpoint instruction_region iff (instr_accept) {
            bins imem    = {2'd0};
            bins bootrom = {2'd1};
            bins debug   = {2'd2};
        }

        target_x_region: cross cp_target, cp_region;
    endgroup

    instruction_cg instruction_cov = new();

    // --------------------------------------------------------
    // IMEM arbitration coverage
    // --------------------------------------------------------
    covergroup imem_arb_cg @(posedge clk);
        option.per_instance = 1;

        cp_owner: coverpoint sba_imem_access iff (imem_accept) {
            bins core_fetch = {1'b0};
            bins sba_access = {1'b1};
        }

        cp_response: coverpoint sram_rvalid iff (rst_n) {
            bins no_response = {1'b0};
            bins response    = {1'b1};
        }

        cp_sba_response: coverpoint effective_sba_rvalid iff (rst_n) {
            bins no_response = {1'b0};
            bins response    = {1'b1};
        }
    endgroup

    imem_arb_cg imem_arb_cov = new();

    // --------------------------------------------------------
    // AXI-Lite write address channel coverage
    // --------------------------------------------------------
    covergroup axi_aw_cg @(posedge clk);
        option.per_instance = 1;

        cp_aw_region: coverpoint axi_awaddr[31:12]
            iff (rst_n && axi_awvalid && axi_awready) {
            bins uart  = {20'h40000};
            bins i2c   = {20'h40001};
            bins spi   = {20'h40002};
            bins gpio  = {20'h40003};
            bins timer = {20'h40004};
            bins plic  = {20'h40005};
            bins other = default;
        }
    endgroup

    axi_aw_cg axi_aw_cov = new();

    // --------------------------------------------------------
    // AXI-Lite write data channel coverage
    // --------------------------------------------------------
    covergroup axi_w_cg @(posedge clk);
        option.per_instance = 1;

        cp_wstrb: coverpoint axi_wstrb
            iff (rst_n && axi_wvalid && axi_wready) {
            bins byte0 = {4'b0001};
            bins byte1 = {4'b0010};
            bins byte2 = {4'b0100};
            bins byte3 = {4'b1000};
            bins half0 = {4'b0011};
            bins half1 = {4'b1100};
            bins word  = {4'b1111};
            bins other = default;
        }
    endgroup

    axi_w_cg axi_w_cov = new();

    // --------------------------------------------------------
    // AXI-Lite write response coverage
    // --------------------------------------------------------
    covergroup axi_b_cg @(posedge clk);
        option.per_instance = 1;

        cp_b_handshake: coverpoint (axi_bvalid && axi_bready)
            iff (rst_n) {
            bins response_accepted = {1'b1};
        }
    endgroup

    axi_b_cg axi_b_cov = new();

    // --------------------------------------------------------
    // AXI-Lite read address channel coverage
    // --------------------------------------------------------
    covergroup axi_ar_cg @(posedge clk);
        option.per_instance = 1;

        cp_ar_region: coverpoint axi_araddr[31:12]
            iff (rst_n && axi_arvalid && axi_arready) {
            bins uart  = {20'h40000};
            bins i2c   = {20'h40001};
            bins spi   = {20'h40002};
            bins gpio  = {20'h40003};
            bins timer = {20'h40004};
            bins plic  = {20'h40005};
            bins other = default;
        }
    endgroup

    axi_ar_cg axi_ar_cov = new();

    // --------------------------------------------------------
    // AXI-Lite read response coverage
    // --------------------------------------------------------
    covergroup axi_r_cg @(posedge clk);
        option.per_instance = 1;

        cp_r_handshake: coverpoint (axi_rvalid && axi_rready)
            iff (rst_n) {
            bins response_accepted = {1'b1};
        }
    endgroup

    axi_r_cg axi_r_cov = new();

    // --------------------------------------------------------
    // APB completed-transfer coverage
    // --------------------------------------------------------
    covergroup apb_cg @(posedge clk);
        option.per_instance = 1;

        cp_slave: coverpoint peripheral_region iff (apb_complete) {
            bins uart  = {3'd0};
            bins i2c   = {3'd1};
            bins spi   = {3'd2};
            bins gpio  = {3'd3};
            bins timer = {3'd4};
            bins plic  = {3'd5};
            bins other = {3'd6};
        }

        cp_select: coverpoint apb_pselx iff (apb_complete) {
            bins uart  = {6'b000001};
            bins i2c   = {6'b000010};
            bins spi   = {6'b000100};
            bins gpio  = {6'b001000};
            bins timer = {6'b010000};
            bins plic  = {6'b100000};
            bins other = default;
        }

        cp_operation: coverpoint apb_pwrite iff (apb_complete) {
            bins read  = {1'b0};
            bins write = {1'b1};
        }

        cp_strobe: coverpoint apb_pstrb iff (apb_complete && apb_pwrite) {
            bins byte0 = {4'b0001};
            bins byte1 = {4'b0010};
            bins byte2 = {4'b0100};
            bins byte3 = {4'b1000};
            bins half0 = {4'b0011};
            bins half1 = {4'b1100};
            bins word  = {4'b1111};
            bins other = default;
        }

        cp_error: coverpoint apb_selected_pslverr iff (apb_complete) {
            bins no_error = {1'b0};
            bins error    = {1'b1};
        }

        slave_x_operation: cross cp_slave, cp_operation;
    endgroup

    apb_cg apb_cov = new();

    // --------------------------------------------------------
    // Reset, boot and protocol observations
    // --------------------------------------------------------
    integer bootrom_fetch_count;
    integer imem_fetch_count;
    integer data_accept_count;
    integer instr_accept_count;
    integer axi_aw_count;
    integer axi_w_count;
    integer axi_b_count;
    integer axi_ar_count;
    integer axi_r_count;
    integer apb_complete_count;
    integer apb_error_count;
    logic   reset_release_seen;

    always @(posedge clk) begin
        if (!rst_n) begin
            bootrom_fetch_count <= 0;
            imem_fetch_count    <= 0;
            data_accept_count   <= 0;
            instr_accept_count  <= 0;
            axi_aw_count        <= 0;
            axi_w_count         <= 0;
            axi_b_count         <= 0;
            axi_ar_count        <= 0;
            axi_r_count         <= 0;
            apb_complete_count  <= 0;
            apb_error_count     <= 0;
            reset_release_seen  <= 1'b0;
        end else begin
            if (!reset_release_seen) begin
                $display("[SOC PHASE1] Reset released at time %0t", $time);
                reset_release_seen <= 1'b1;
            end

            if (instr_req && instr_gnt) begin
                instr_accept_count <= instr_accept_count + 1;

                if (instruction_region == 2'd1) begin
                    bootrom_fetch_count <= bootrom_fetch_count + 1;
                    if (bootrom_fetch_count == 0)
                        $display("[SOC PHASE1] First BootROM fetch: %08h at %0t",
                                 instr_addr, $time);
                end

                if (instruction_region == 2'd0) begin
                    imem_fetch_count <= imem_fetch_count + 1;
                    if (imem_fetch_count == 0)
                        $display("[SOC PHASE1] First IMEM fetch: %08h at %0t",
                                 instr_addr, $time);
                end
            end

            if (sys_req && sys_gnt) begin
                data_accept_count <= data_accept_count + 1;
                $display("[SOC OBI DATA] %s addr=%08h we=%0b be=%b target=%0d region=%0d master=%0d",
                         sys_we ? "WRITE" : "READ",
                         sys_addr, sys_we, sys_be, data_demux_sel,
                         data_region, data_master);
            end

            if (axi_awvalid && axi_awready)
                axi_aw_count <= axi_aw_count + 1;
            if (axi_wvalid && axi_wready)
                axi_w_count <= axi_w_count + 1;
            if (axi_bvalid && axi_bready)
                axi_b_count <= axi_b_count + 1;
            if (axi_arvalid && axi_arready)
                axi_ar_count <= axi_ar_count + 1;
            if (axi_rvalid && axi_rready)
                axi_r_count <= axi_r_count + 1;

            if (apb_complete) begin
                apb_complete_count <= apb_complete_count + 1;
                if (apb_selected_pslverr)
                    apb_error_count <= apb_error_count + 1;

                $display("[SOC APB] %s addr=%08h psel=%b strb=%b error=%0b",
                         apb_pwrite ? "WRITE" : "READ",
                         apb_paddr, apb_pselx, apb_pstrb, apb_selected_pslverr);
            end

            if ((|apb_pselx) && ($countones(apb_pselx) != 1))
                $error("[SOC PHASE1 ERROR] APB PSEL is not one-hot: %b",
                       apb_pselx);
        end
    end

    // --------------------------------------------------------
    // Coverage and transaction summary
    // Call from testbench at end:
    //     phase1_cov.report();
    // --------------------------------------------------------
    task automatic report;
        $display("");
        $display("======================================================");
        $display("          SOC PHASE 1 COVERAGE SUMMARY");
        $display("======================================================");
        $display("OBI data accepted       : %0d", data_accept_count);
        $display("Instruction accepted   : %0d", instr_accept_count);
        $display("BootROM fetches         : %0d", bootrom_fetch_count);
        $display("IMEM fetches            : %0d", imem_fetch_count);
        $display("AXI AW handshakes       : %0d", axi_aw_count);
        $display("AXI W handshakes        : %0d", axi_w_count);
        $display("AXI B handshakes        : %0d", axi_b_count);
        $display("AXI AR handshakes       : %0d", axi_ar_count);
        $display("AXI R handshakes        : %0d", axi_r_count);
        $display("APB completed transfers : %0d", apb_complete_count);
        $display("APB error responses     : %0d", apb_error_count);
        $display("------------------------------------------------------");
        $display("OBI data coverage       : %0.2f%%", obi_data_cov.get_coverage());
        $display("Instruction coverage   : %0.2f%%", instruction_cov.get_coverage());
        $display("IMEM arbitration cov.   : %0.2f%%", imem_arb_cov.get_coverage());
        $display("AXI AW coverage         : %0.2f%%", axi_aw_cov.get_coverage());
        $display("AXI W coverage          : %0.2f%%", axi_w_cov.get_coverage());
        $display("AXI B coverage          : %0.2f%%", axi_b_cov.get_coverage());
        $display("AXI AR coverage         : %0.2f%%", axi_ar_cov.get_coverage());
        $display("AXI R coverage          : %0.2f%%", axi_r_cov.get_coverage());
        $display("APB coverage            : %0.2f%%", apb_cov.get_coverage());
        $display("======================================================");
    endtask

endmodule
