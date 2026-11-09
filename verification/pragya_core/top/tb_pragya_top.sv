/*`timescale 1ns/1ps

import pragya_pkg::*;

module tb_pragya_top;

    //=========================================================
    // Configuration
    //=========================================================

    parameter integer MAX_CYCLES = 1000000;

    // 0 = C Program
    // 1 = RISC-V-DV
    parameter bit RISCV_DV_MODE = 1'b0;

    localparam logic [31:0] RISCV_DV_TOHOST_ADDR = 32'h80008000;
    localparam logic [31:0] RISCV_DV_PASS_VALUE  = 32'h00000001;

   // C Program completion
   localparam logic [31:0] C_TOHOST_ADDR = 32'h80008000;
   localparam logic [31:0] C_PASS_VALUE  = 32'h00000001;
  // C interrupt test synchronization
   localparam logic [31:0] IRQ_READY_ADDR  = 32'h80007FF0;
   localparam logic [31:0] IRQ_READY_VALUE = 32'h00000001;
   localparam logic [31:0] TIMER_PENDING_READY_VALUE = 32'h00000002;

    //=========================================================
    // DUT Inputs
    //=========================================================

    logic pg_riscv32_mp_clk_in;
    logic pg_riscv32_mp_rst_in;

    logic pg_riscv32_mp_eirq_in;
    logic pg_riscv32_mp_tirq_in;
    logic pg_riscv32_mp_sirq_in;
    logic program_done;
    logic [31:0] irq_mtvec;

    //=========================================================
    // Testbench Variables
    //=========================================================

    integer rtl_log;
    integer cycle_count;
 // RV32M operation
    md_op_e md_operation;
 // Interrupt sequence enable
    bit irq_taken;
    bit dv_irq_test;
    bit c_irq_test;
    bit c_timer_irq_test;
    bit c_software_irq_test;
    bit c_timer_pending_test;
    bit c_external_pending_test;
    bit c_mip_cross_test;
    bit c_software_pending_test;
    bit c_timer_mtie_disabled_test;
    bit c_timer_both_disabled_test;
    //=========================================================
    // Coverage Objects
    //=========================================================

    rv32i_coverage        rv32i_cov;
    rv32m_coverage        rv32m_cov;
    load_store_coverage   lsu_cov;
    branch_jump_coverage  branch_cov;
    pipeline_coverage     pipe_cov;
    rv32_system_coverage system_cov;

    //=========================================================
    // DUT
    //=========================================================

    pragya_top dut(

        .pg_riscv32_mp_clk_in (pg_riscv32_mp_clk_in),
        .pg_riscv32_mp_rst_in (pg_riscv32_mp_rst_in),

        .pg_riscv32_mp_eirq_in(pg_riscv32_mp_eirq_in),
        .pg_riscv32_mp_tirq_in(pg_riscv32_mp_tirq_in),
        .pg_riscv32_mp_sirq_in(pg_riscv32_mp_sirq_in)

    );

    //=========================================================
    // Create Coverage Objects
    //=========================================================

    initial begin

        rv32i_cov  = new();
        rv32m_cov  = new();
	system_cov = new();
        lsu_cov    = new();
        branch_cov = new();
        pipe_cov   = new();

    end

//=========================================================
// TEST MODE SELECTION
//=========================================================

initial begin

    c_irq_test          = 1'b0;
    c_timer_irq_test    = 1'b0;
    c_software_irq_test = 1'b0;
    c_timer_pending_test = 1'b0;
    c_external_pending_test = 1'b0;
    c_mip_cross_test      = 1'b0;
    c_timer_mtie_disabled_test = 1'b0;
    c_timer_both_disabled_test = 1'b0;
    c_software_pending_test = 1'b0;
    dv_irq_test         = 1'b0;

    if ($test$plusargs("c_irq_test"))
        c_irq_test = 1'b1;

    if ($test$plusargs("c_timer_irq_test"))
        c_timer_irq_test = 1'b1;

    if ($test$plusargs("c_software_irq_test"))
        c_software_irq_test = 1'b1;

    if ($test$plusargs("c_timer_pending_test"))
        c_timer_pending_test = 1'b1;

    if ($test$plusargs("c_timer_mtie_disabled_test"))
        c_timer_mtie_disabled_test = 1'b1;

    if ($test$plusargs("c_mip_cross_test"))
        c_mip_cross_test = 1'b1;

    if ($test$plusargs("c_timer_both_disabled_test"))
        c_timer_both_disabled_test = 1'b1;

    if ($test$plusargs("c_external_pending_test"))
        c_external_pending_test = 1'b1;

    if ($test$plusargs("c_software_pending_test"))
        c_software_pending_test = 1'b1;



    if ($test$plusargs("enable_irq_seq"))
        dv_irq_test = 1'b1;

    $display("");
    $display("==============================================");
    $display("TB TEST MODE");
    $display("==============================================");
    $display("RISCV_DV_MODE       = %b", RISCV_DV_MODE);
    $display("c_irq_test          = %b", c_irq_test);
    $display("c_timer_irq_test    = %b", c_timer_irq_test);
    $display("c_timer_pending_test    = %b", c_timer_pending_test);
    $display("c_timer_mtie_disabled_test = %b", c_timer_mtie_disabled_test);
    $display("c_external_pending_test    = %b", c_external_pending_test);
    $display("c_software_pending_test    = %b", c_software_pending_test);
    $display("c_software_irq_test = %b", c_software_irq_test);
    $display("dv_irq_test         = %b", dv_irq_test);
    $display("==============================================");
    $display("");

end

    //=========================================================
    // Clock Generation
    //=========================================================

    initial begin

        pg_riscv32_mp_clk_in = 1'b0;

        forever
            #5 pg_riscv32_mp_clk_in = ~pg_riscv32_mp_clk_in;

    end

    //=========================================================
    // Reset Generation
    //=========================================================

    initial begin

        pg_riscv32_mp_rst_in = 1'b1;

        pg_riscv32_mp_eirq_in = 1'b0;
        pg_riscv32_mp_tirq_in = 1'b0;
        pg_riscv32_mp_sirq_in = 1'b0;

        repeat(4)
            @(posedge pg_riscv32_mp_clk_in);

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_rst_in = 1'b0;

        $display("[%0t] Reset Released",$time);

    end

    //=========================================================
    // RTL Log
    //=========================================================

    initial begin

        rtl_log = $fopen("rtl.log","w");

        if(rtl_log==0) begin

            $display("ERROR : Cannot open rtl.log");
            $finish;

        end

        $display("RTL log opened successfully.");

    end

 initial begin
    program_done = 1'b0;
    irq_mtvec    = 32'h0;
    irq_taken    = 1'b0;

  end
    //=========================================================
    // Coverage Report Task
    //=========================================================

    task automatic print_coverage;

    begin

        $display("");
        $display("======================================");
        $display("      FUNCTIONAL COVERAGE");
        $display("======================================");

        rv32i_cov.report();

        rv32m_cov.report();

        lsu_cov.report();

        branch_cov.report();

        pipe_cov.report();
	system_cov.report();

        $display("======================================");
        $display("");

    end

    endtask

//=========================================================
// REGISTER COMMIT LOGGER
// (Used ONLY for RTL vs Spike comparison)
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if(!pg_riscv32_mp_rst_in) begin

        if(!program_done && dut.CORE.commit_valid) begin

            //------------------------------------------------
            // RTL Log
            //------------------------------------------------

            $fdisplay(
                rtl_log,
                "core   0: 0x%08h (0x%08h) x%0d 0x%08h",
                dut.CORE.commit_pc,
                dut.CORE.commit_instr,
                dut.CORE.commit_rd,
                dut.CORE.commit_data
            );

            $fflush(rtl_log);

            //------------------------------------------------
            // RV32M Coverage
            //------------------------------------------------

            if ((dut.CORE.commit_instr[6:0]  == OPC_OP) &&
                (dut.CORE.commit_instr[31:25] == 7'b0000001))
            begin

                case (dut.CORE.commit_instr[14:12])

                    3'b000: md_operation = MD_OP_MUL;
                    3'b001: md_operation = MD_OP_MULH;
                    3'b010: md_operation = MD_OP_MULHSU;
                    3'b011: md_operation = MD_OP_MULHU;
                    3'b100: md_operation = MD_OP_DIV;
                    3'b101: md_operation = MD_OP_DIVU;
                    3'b110: md_operation = MD_OP_REM;
                    3'b111: md_operation = MD_OP_REMU;

                    default: md_operation = MD_OP_MUL;

                endcase

                rv32m_cov.sample(

                    dut.CORE.commit_instr,
                    dut.CORE.commit_pc,
                    dut.CORE.commit_valid,
                    dut.CORE.commit_instr[19:15],
                    dut.CORE.commit_instr[24:20],
                    dut.CORE.commit_rd,
                    dut.CORE.commit_rs1_data,
                    dut.CORE.commit_rs2_data,
                    dut.CORE.commit_data,
                    md_operation

                );

            end

        end

    end

end


//=========================================================
// RV32I / Branch / Pipeline Coverage
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if (dut.CORE.commit_instr_valid &&
            !$isunknown(dut.CORE.commit_instr)) begin

            //------------------------------------------------
            // RV32I Coverage
            //
            // Exclude:
            //   RV32M  -> rv32m_cov
            //   SYSTEM -> system_cov
            //------------------------------------------------

            if ((dut.CORE.commit_instr[6:0] != OPC_SYSTEM) &&
                !((dut.CORE.commit_instr[6:0] == OPC_OP) &&
                  (dut.CORE.commit_instr[31:25] == 7'b0000001)))
            begin

                rv32i_cov.sample(

                    dut.CORE.commit_instr,
                    dut.CORE.commit_pc,
                    dut.CORE.commit_instr_valid,

                    dut.CORE.commit_instr[6:0],
                    dut.CORE.commit_instr[14:12],
                    dut.CORE.commit_instr[31:25],

                    dut.CORE.commit_instr[19:15],
                    dut.CORE.commit_instr[24:20],
                    dut.CORE.commit_rd,

                    dut.CORE.commit_data,

                    dut.CORE.final_reg_write

                );

            end


            //------------------------------------------------
            // Branch / Jump Coverage
            //
            // Keep this independent of RV32I instruction
            // coverage.
            //------------------------------------------------

            branch_cov.sample(

                dut.CORE.commit_instr,
                dut.CORE.commit_pc,
                dut.CORE.i_adder_out,
                dut.CORE.branch_taken_out

            );

        end


        //------------------------------------------------
        // Pipeline Coverage
        //------------------------------------------------

        pipe_cov.sample(

            dut.CORE.stallD,
            dut.CORE.flush_DE,
            dut.CORE.forward_a,
            dut.CORE.forward_b,

            dut.CORE.mem_req_out,
            dut.CORE.wait_for_mem,

            dut.CORE.final_reg_write

        );

    end

end

// SYSTEM COVERAGE

localparam STATE_TRAP_TAKEN = 4'b0100;

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        //----------------------------------------------------------
        // CSR COVERAGE
        //----------------------------------------------------------

        if (dut.CORE.commit_instr_valid &&
    dut.CORE.commit_instr[6:0] == 7'b1110011) begin

    system_cov.sample_csr(

        1'b1,

        // CSR address directly from committed instruction
        dut.CORE.commit_instr[31:20],

        // CSR operation directly from committed instruction
        dut.CORE.commit_instr[14:12],

        // CSR write
        // Immediate forms with rs1/zimm != 0 are writes.
        // For now preserve the existing RTL write indication.
        dut.CORE.csr_wr_en_reg_out,

        dut.CORE.csr_data_reg_out,
        dut.CORE.csr_data_out,

        dut.CORE.csr_inst.mstatus_out,
        dut.CORE.csr_inst.mie,
        dut.CORE.csr_inst.mtvec_out,
        dut.CORE.csr_inst.mepc,
        dut.CORE.csr_inst.mcause,
        dut.CORE.csr_inst.mtval,
        dut.CORE.csr_inst.mscratch,
        dut.CORE.csr_inst.mip,

        dut.CORE.csr_inst.mcycle,
        dut.CORE.csr_inst.minstret,

        dut.CORE.csr_inst.mie_out,
        dut.CORE.csr_inst.mpie_out,

        dut.CORE.csr_inst.mtvec_mode
    );

end

//----------------------------------------------------------
// TRAP COVERAGE
//----------------------------------------------------------

if (dut.CORE.machine_control_inst.curr_state ==
    STATE_TRAP_TAKEN) begin

    if (dut.CORE.machine_control_inst.i_or_e_out) begin

        //--------------------------------------------------
        // INTERRUPT
        //--------------------------------------------------

        system_cov.sample_interrupt(

            1'b1,

            dut.CORE.machine_control_inst.cause_out,

            dut.CORE.machine_control_inst.sip,
            dut.CORE.machine_control_inst.tip,
            dut.CORE.machine_control_inst.eip,

            dut.CORE.csr_inst.mie,

            (
                dut.CORE.csr_inst.mip |
                (pg_riscv32_mp_sirq_in ? 32'h00000008 : 32'h00000000) |
                (pg_riscv32_mp_tirq_in ? 32'h00000080 : 32'h00000000) |
                (pg_riscv32_mp_eirq_in ? 32'h00000800 : 32'h00000000)
            ),

            dut.CORE.csr_inst.mie_out,
            dut.CORE.csr_inst.mtvec_mode
        );

    end
    else begin

        //--------------------------------------------------
        // EXCEPTION
        //--------------------------------------------------
	system_cov.sample_exception(
    1'b1,

    dut.CORE.machine_control_inst.cause_out,

    dut.CORE.machine_control_inst.i_or_e_out,

    dut.CORE.csr_inst.mepc,
    dut.CORE.csr_inst.mtval,

    dut.CORE.csr_inst.mie_out,
    dut.CORE.csr_inst.mpie_out,

    // ECALL = MCAUSE 11
    (dut.CORE.machine_control_inst.cause_out == 4'b1011),

    // EBREAK = MCAUSE 3
    (dut.CORE.machine_control_inst.cause_out == 4'b0011),

    1'b0
);


    end

end
    end

end

//=========================================================
// MRET COVERAGE
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        !program_done) begin

        if (dut.CORE.machine_control_inst.mret === 1'b1) begin

            system_cov.sample_system_instruction(
                1'b0,    // ECALL
                1'b0,    // EBREAK
                1'b1     // MRET
            );

        end

    end

end
//=========================================================
// INTERRUPT REQUEST COVERAGE
//=========================================================
//
// Sample interrupt conditions even when the interrupt
// is NOT taken.
//
// This is required to cover:
//
//     MSTATUS.MIE = 0
//     MIE.MTIE    = 1
//     TIMER IRQ   = active
//
// In this case:
//     taken = 0
//
// The interrupt-cause coverpoint is protected by:
//     iff (trap_taken && is_interrupt)
//
// so this sample will NOT create a fake interrupt-cause
// hit. It only covers the interrupt enable/request state.
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        !program_done) begin



            system_cov.sample_interrupt(

                1'b0,                         // NOT TAKEN

                4'b0111,                      // no trap cause

                pg_riscv32_mp_sirq_in,
                pg_riscv32_mp_tirq_in,
                pg_riscv32_mp_eirq_in,

                dut.CORE.csr_inst.mie,
                (
    dut.CORE.csr_inst.mip |
    (pg_riscv32_mp_sirq_in ? 32'h00000008 : 32'h00000000) |
    (pg_riscv32_mp_tirq_in ? 32'h00000080 : 32'h00000000) |
    (pg_riscv32_mp_eirq_in ? 32'h00000800 : 32'h00000000)
),

                dut.CORE.csr_inst.mstatus_out[3],

                dut.CORE.csr_inst.mtvec_mode

            );



    end

end

//=========================================================
// LOAD COVERAGE
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if (!program_done &&
            dut.CORE.commit_instr_valid &&
            dut.CORE.mem_req_reg_out &&
            !dut.CORE.mem_write_reg_out) begin

            lsu_cov.sample(

                1'b1,
                1'b0,

                dut.CORE.funct3_reg_out,
                dut.CORE.i_adder_reg_out,
                dut.CORE.commit_data

            );

        end

    end

end


//=========================================================
// STORE COVERAGE + STORE LOGGER
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if (!program_done &&
            dut.CORE.commit_store) begin

            //------------------------------------------------
            // RTL Log
            //------------------------------------------------

            $fdisplay(
                rtl_log,
                "core   0: 0x%08h (0x%08h) mem 0x%08h 0x%08h",
                dut.CORE.commit_store_pc,
                dut.CORE.commit_store_instr,
                dut.CORE.commit_store_addr,
                dut.CORE.commit_store_data
            );

            $fflush(rtl_log);

            //------------------------------------------------
            // STORE COVERAGE
            //------------------------------------------------

            lsu_cov.sample(

                1'b1,
                1'b1,

                dut.CORE.commit_store_instr[14:12],
                dut.CORE.commit_store_addr,
                dut.CORE.commit_store_data

            );

        end

    end

end

//=========================================================
// C INTERRUPT READY DETECTOR
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
    (c_irq_test ||
     c_timer_irq_test ||
     c_timer_mtie_disabled_test ||
      c_timer_both_disabled_test ||
     c_software_irq_test ||
     c_timer_pending_test) &&
    !program_done) begin

        if (dut.CORE.commit_store &&
    dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
    (
        (!c_timer_pending_test &&
         !c_timer_mtie_disabled_test &&
         !c_timer_both_disabled_test &&
         dut.CORE.commit_store_data == IRQ_READY_VALUE)

        ||

        (c_timer_pending_test &&
         dut.CORE.commit_store_data == TIMER_PENDING_READY_VALUE)

        ||

        (c_timer_mtie_disabled_test &&
         dut.CORE.commit_store_data == 32'h00000003)

        ||

        (c_timer_both_disabled_test &&
         dut.CORE.commit_store_data == 32'h00000004)
    )) begin

            $display("");
            $display("==============================================");
            $display("[%0t] TB: C PROGRAM ENABLED INTERRUPTS",
                     $time);
            $display("==============================================");

            $display("MSTATUS = %08h",
                     dut.CORE.csr_inst.mstatus_out);

            $display("MIE     = %08h",
                     dut.CORE.csr_inst.mie);

            $display("MIP     = %08h",
                     dut.CORE.csr_inst.mip);

        end

    end

end

    //=========================================================
    // Console Monitor
    //=========================================================

    always @(posedge pg_riscv32_mp_clk_in) begin

        if(!pg_riscv32_mp_rst_in) begin

            //--------------------------------------------------
            // Register Commit
            //--------------------------------------------------

            if(dut.CORE.commit_valid) begin

                $display(
                    "PC=%08h INSTR=%08h x%0d=%08h",
                    dut.CORE.commit_pc,
                    dut.CORE.commit_instr,
                    dut.CORE.commit_rd,
                    dut.CORE.commit_data
                );

            end

            //--------------------------------------------------
            // Store Commit
            //--------------------------------------------------

            if(dut.CORE.commit_store) begin

                $display(
                    "PC=%08h INSTR=%08h MEM[%08h]=%08h",
                    dut.CORE.commit_store_pc,
                    dut.CORE.commit_store_instr,
                    dut.CORE.commit_store_addr,
                    dut.CORE.commit_store_data
                );

            end

        end

    end


    //=========================================================
    // X / Z CHECKER
    //=========================================================

    always @(posedge pg_riscv32_mp_clk_in) begin

        if(!pg_riscv32_mp_rst_in) begin

            if(dut.CORE.commit_valid) begin

                if($isunknown(dut.CORE.commit_pc))
                    $display("WARNING : commit_pc contains X/Z");

                if($isunknown(dut.CORE.commit_instr))
                    $display("WARNING : commit_instr contains X/Z");

                if($isunknown(dut.CORE.commit_rd))
                    $display("WARNING : commit_rd contains X/Z");

                if($isunknown(dut.CORE.commit_data))
                    $display("WARNING : commit_data contains X/Z");

            end

            if(dut.CORE.commit_store) begin

                if($isunknown(dut.CORE.commit_store_pc))
                    $display("WARNING : commit_store_pc contains X/Z");

                if($isunknown(dut.CORE.commit_store_instr))
                    $display("WARNING : commit_store_instr contains X/Z");

                if($isunknown(dut.CORE.commit_store_addr))
                    $display("WARNING : commit_store_addr contains X/Z");

                if($isunknown(dut.CORE.commit_store_data))
                    $display("WARNING : commit_store_data contains X/Z");

            end

        end

    end
       //=========================================================
    // Simulation Control
    //=========================================================

    initial begin

        cycle_count = 0;

        //-----------------------------------------------------
        // Wait for Reset Release
        //-----------------------------------------------------

        wait(pg_riscv32_mp_rst_in == 1'b0);

        $display("");
        $display("======================================");

        if(RISCV_DV_MODE)
            $display("Starting RISC-V-DV Program");
        else
            $display("Starting C Program");

        $display("======================================");
        $display("");

//-----------------------------------------------------
// Main Simulation Loop
//-----------------------------------------------------

while(cycle_count < MAX_CYCLES) begin

    @(posedge pg_riscv32_mp_clk_in);
    cycle_count++;

    if(!RISCV_DV_MODE) begin

        // -------- C PROGRAM MODE --------

        if(dut.CORE.commit_store &&
           dut.CORE.commit_store_addr == C_TOHOST_ADDR) begin

            if(dut.CORE.commit_store_data == 32'h1) begin

                $display("PROGRAM PASSED");
           program_done = 1'b1;     // stop all logging

                print_coverage();

                $fflush(rtl_log);
                $fclose(rtl_log);

                $finish;

            end
            else if(dut.CORE.commit_store_data == 32'h2) begin

                $display("PROGRAM FAILED");

          program_done = 1'b1;

                print_coverage();

                $fflush(rtl_log);
                $fclose(rtl_log);

                $finish;

            end

            // Ignore all other values (especially 0)

        end

    end
    else begin

        // -------- RISC-V-DV MODE --------

        if (dut.CORE.commit_store &&
    dut.CORE.commit_store_addr == RISCV_DV_TOHOST_ADDR &&
    dut.CORE.commit_store_data == RISCV_DV_PASS_VALUE) begin

    $display("RISC-V-DV PROGRAM COMPLETED");

    program_done = 1'b1;

    print_coverage();

    $fflush(rtl_log);
    $fclose(rtl_log);

    $finish;

end

    end

end
        //------------------------------------------------------
        // TIMEOUT
        //------------------------------------------------------

        $display("");
        $display("======================================");

        if(RISCV_DV_MODE)
            $display("RISC-V-DV SIMULATION TIMEOUT");
        else
            $display("C PROGRAM SIMULATION TIMEOUT");

        $display("======================================");

        $display("Cycles      = %0d",cycle_count);
        $display("MAX_CYCLES  = %0d",MAX_CYCLES);

        //------------------------------------------------------
        // Print Coverage Before Exiting
        //------------------------------------------------------

        print_coverage();

        //------------------------------------------------------
        // Close Log
        //------------------------------------------------------

        $fflush(rtl_log);
        $fclose(rtl_log);

        //------------------------------------------------------
        // Fatal Exit
        //------------------------------------------------------

        if(RISCV_DV_MODE)
            $fatal(1,"RISC-V-DV Simulation Timeout");
        else
            $fatal(1,"C Program Simulation Timeout");

    end
//=========================================================
// TRAP HANDLER DEBUG
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if ((dut.CORE.pc_reg_out >= 32'h800031b8) &&
            (dut.CORE.pc_reg_out <= 32'h800031e0)) begin

            $display("");
            $display("========== TRAP HANDLER DEBUG ==========");
            $display("TIME            = %0t", $time);
            $display("PC              = %08h",
                     dut.CORE.pc_reg_out);
            $display("INSTR           = %08h",
                     dut.CORE.instr_reg_out);

            $display("commit_valid    = %b",
                     dut.CORE.commit_valid);

            $display("commit_store    = %b",
                     dut.CORE.commit_store);

            $display("mem_req         = %b",
                     dut.CORE.mem_req_reg_out);

            $display("mem_write       = %b",
                     dut.CORE.mem_write_reg_out);

            $display("wait_for_mem    = %b",
                     dut.CORE.wait_for_mem);

            $display("data_valid      = %b",
                     dut.CORE.pg_riscv32_mp_data_valid);

            $display("stallD          = %b",
                     dut.CORE.stallD);

            $display("flush_DE        = %b",
                     dut.CORE.flush_DE);

            $display("========================================");

        end

    end

end

//=========================================================
// WAIT UNTIL MACHINE INTERRUPTS ARE ENABLED
//=========================================================

task automatic wait_for_external_interrupt_enable;

    begin

        $display("");
        $display("==============================================");
        $display("[%0t] TB: Waiting for external interrupt enable", $time);
        $display("==============================================");

        wait (
            dut.CORE.csr_inst.mstatus_out[3] === 1'b1 &&
            dut.CORE.csr_inst.mie[11]        === 1'b1
        );

        $display("[%0t] TB: MSTATUS.MIE = 1", $time);
        $display("[%0t] TB: MIE.MEIE    = 1", $time);
        $display("[%0t] TB: MSTATUS     = %08h",
                 $time,
                 dut.CORE.csr_inst.mstatus_out);
        $display("[%0t] TB: MIE         = %08h",
                 $time,
                 dut.CORE.csr_inst.mie);
        $display("[%0t] TB: MIP         = %08h",
                 $time,
                 dut.CORE.csr_inst.mip);

    end

endtask


//=========================================================
// DIRECTED C EXTERNAL INTERRUPT TEST
//=========================================================

initial begin

    if (c_irq_test) begin

        if (RISCV_DV_MODE) begin

            $fatal(
                1,
                "ERROR: c_irq_test requires RISCV_DV_MODE=0"
            );

        end

        $display("");
        $display("=================================================");
        $display("      DIRECTED C EXTERNAL INTERRUPT TEST");
        $display("=================================================");
        $display("");


        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);


        //-------------------------------------------------
        // Wait for C program synchronization store
        //-------------------------------------------------

        $display(
            "[%0t] TB: Waiting for C program to enable EXTERNAL IRQ",
            $time
        );

        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == IRQ_READY_VALUE
        );


        //-------------------------------------------------
        // Check MSTATUS.MIE
        //-------------------------------------------------

        $display("");
        $display(
            "[%0t] TB: EXTERNAL INTERRUPT PROGRAM READY",
            $time
        );

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );


        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE is not enabled"
            );

        end


        //-------------------------------------------------
        // Check MIE.MEIE = bit 11
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mie[11] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MIE.MEIE is not enabled"
            );

        end


        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MEIE     = 1 : PASS");


        //-------------------------------------------------
        // Assert EXTERNAL interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: ASSERTING EXTERNAL INTERRUPT",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_eirq_in = 1'b1;


        //-------------------------------------------------
        // Wait for interrupt trap
        //-------------------------------------------------

        fork : EXTERNAL_IRQ_WAIT

            begin : WAIT_EXTERNAL_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

            end


            begin : EXTERNAL_IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: EXTERNAL interrupt was NOT taken within 1000 cycles"
                );

            end

        join_any

        disable EXTERNAL_IRQ_WAIT;


        //-------------------------------------------------
        // External interrupt taken
        //-------------------------------------------------

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: EXTERNAL INTERRUPT TAKEN",
            $time
        );
        $display("***********************************************");


        $display(
            "CAUSE  = %08h",
            dut.CORE.machine_control_inst.cause_out
        );

        $display(
            "I_OR_E = %b",
            dut.CORE.machine_control_inst.i_or_e_out
        );

        $display(
            "MCAUSE = %08h",
            dut.CORE.csr_inst.mcause
        );

        $display(
            "MEPC   = %08h",
            dut.CORE.csr_inst.mepc
        );

        $display(
            "MTVEC  = %08h",
            dut.CORE.csr_inst.mtvec_out
        );

        $display(
            "MIP    = %08h",
            dut.CORE.csr_inst.mip
        );


        //-------------------------------------------------
        // Verify interrupt classification
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "ERROR: EXTERNAL trap classified as exception"
            );

        end


        //-------------------------------------------------
        // Allow CSR mcause to update
        //-------------------------------------------------

        @(posedge pg_riscv32_mp_clk_in);
        #1;


        //-------------------------------------------------
        // Machine external interrupt = cause 11
        //
        // Interrupt bit = 1
        //
        // MCAUSE = 0x8000000B
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mcause !== 32'h8000000B) begin

            $fatal(
                1,
                "ERROR: Wrong EXTERNAL MCAUSE. Expected 8000000B, got %08h",
                dut.CORE.csr_inst.mcause
            );

        end


        $display(
            "MCAUSE = %08h : PASS",
            dut.CORE.csr_inst.mcause
        );


        //-------------------------------------------------
        // Deassert external interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_eirq_in = 1'b0;

        $display("");
        $display(
            "[%0t] TB: EXTERNAL INTERRUPT DEASSERTED",
            $time
        );
        $display("");


        //=================================================
        // Wait for trap handler
        //=================================================

        $display("==============================================");
        $display(" WAITING FOR TRAP HANDLER");
        $display("==============================================");


        fork : EXTERNAL_TRAP_HANDLER_WAIT

            begin : WAIT_EXTERNAL_TRAP_HANDLER

                wait (
                    dut.CORE.pc_reg_out ==
                    dut.CORE.csr_inst.mtvec_out
                );

                $display("");
                $display("==============================================");
                $display(
                    "[%0t] TB: TRAP HANDLER ENTERED",
                    $time
                );

                $display(
                    "PC    = %08h",
                    dut.CORE.pc_reg_out
                );

                $display(
                    "MTVEC = %08h",
                    dut.CORE.csr_inst.mtvec_out
                );

                $display("==============================================");
                $display("");

            end


            begin : EXTERNAL_TRAP_HANDLER_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: EXTERNAL TRAP HANDLER WAS NOT ENTERED"
                );

            end

        join_any

        disable EXTERNAL_TRAP_HANDLER_WAIT;


        //=================================================
        // Wait for MRET
        //=================================================

        $display("==============================================");
        $display(" WAITING FOR MRET");
        $display("==============================================");


        fork : EXTERNAL_MRET_WAIT

            begin : WAIT_EXTERNAL_MRET

                wait (
                    dut.CORE.machine_control_inst.mret === 1'b1
                );

                $display("");
                $display("==============================================");
                $display(
                    "[%0t] TB: MRET DETECTED",
                    $time
                );

                $display(
                    "MEPC = %08h",
                    dut.CORE.csr_inst.mepc
                );

                $display(
                    "PC   = %08h",
                    dut.CORE.pc_reg_out
                );

                $display("==============================================");
                $display("");

            end


            begin : EXTERNAL_MRET_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: EXTERNAL INTERRUPT MRET WAS NOT EXECUTED"
                );

            end

        join_any

        disable EXTERNAL_MRET_WAIT;


        //=================================================
        // Wait for PC to return to interrupted PC
        //=================================================

        $display("==============================================");
        $display(" WAITING FOR INTERRUPTED PC");
        $display("==============================================");


        fork : EXTERNAL_MRET_PC_WAIT

            begin : WAIT_EXTERNAL_RETURN_PC

                wait (
                    dut.CORE.pc_reg_out ==
                    dut.CORE.csr_inst.mepc
                );

                $display("");
                $display("==============================================");
                $display(
                    "[%0t] TB: RETURNED FROM EXTERNAL INTERRUPT",
                    $time
                );

                $display(
                    "MEPC = %08h",
                    dut.CORE.csr_inst.mepc
                );

                $display(
                    "PC   = %08h",
                    dut.CORE.pc_reg_out
                );

                $display("==============================================");
                $display("");

            end


            begin : EXTERNAL_RETURN_PC_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: PC DID NOT RETURN TO MEPC AFTER EXTERNAL INTERRUPT MRET"
                );

            end

        join_any

        disable EXTERNAL_MRET_PC_WAIT;


        //=================================================
        // External interrupt + MRET passed
        //=================================================

        $display("");
        $display("==============================================");
        $display(" EXTERNAL INTERRUPT + MRET TEST PASSED");
        $display("==============================================");
        $display("");


        //=================================================
        // Check instructions after MRET
        //=================================================

        $display("");
        $display("==============================================");
        $display(" WAITING FOR INSTRUCTIONS AFTER MRET");
        $display("==============================================");
        $display("");


        repeat (20) begin

            @(posedge pg_riscv32_mp_clk_in);

            $display(
                "[%0t] AFTER MRET: PC=%08h INSTR=%08h",
                $time,
                dut.CORE.pc_reg_out,
                dut.CORE.instr_out
            );

        end


        $display("");
        $display("==============================================");
        $display(" POST-MRET EXECUTION CHECK COMPLETE");
        $display("==============================================");
        $display("");


        //-------------------------------------------------
        // End external interrupt test
        //-------------------------------------------------

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end

//=========================================================
// DIRECTED C TIMER INTERRUPT TEST
//=========================================================

initial begin

    if (c_timer_irq_test) begin

        if (RISCV_DV_MODE) begin

            $fatal(
                1,
                "ERROR: c_timer_irq_test requires RISCV_DV_MODE=0"
            );

        end

        $display("");
        $display("=================================================");
        $display("       DIRECTED C TIMER INTERRUPT TEST");
        $display("=================================================");
        $display("");

        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);

        //-------------------------------------------------
        // Wait for C program synchronization store
        //-------------------------------------------------

        $display(
            "[%0t] TB: Waiting for C program to enable TIMER IRQ",
            $time
        );

        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == IRQ_READY_VALUE
        );

        //-------------------------------------------------
        // Check MSTATUS.MIE
        //-------------------------------------------------

        $display("");
        $display("[%0t] TB: TIMER PROGRAM READY", $time);

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE is not enabled"
            );

        end

        //-------------------------------------------------
        // Check MIE.MTIE = bit 7
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mie[7] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MIE.MTIE is not enabled"
            );

        end

        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MTIE     = 1 : PASS");

        //-------------------------------------------------
        // Assert TIMER interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: ASSERTING TIMER INTERRUPT",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;

        //-------------------------------------------------
        // Wait for trap
        //-------------------------------------------------

        fork : TIMER_IRQ_WAIT

            begin : WAIT_TIMER_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

            end

            begin : TIMER_IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: TIMER interrupt was NOT taken within 1000 cycles"
                );

            end

        join_any

        disable TIMER_IRQ_WAIT;

        //-------------------------------------------------
        // Display trap information
        //-------------------------------------------------

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: TIMER INTERRUPT TAKEN",
            $time
        );
        $display("***********************************************");

        $display(
            "CAUSE  = %08h",
            dut.CORE.machine_control_inst.cause_out
        );

        $display(
            "I_OR_E = %b",
            dut.CORE.machine_control_inst.i_or_e_out
        );

        $display(
            "MCAUSE = %08h",
            dut.CORE.csr_inst.mcause
        );

        $display(
            "MEPC   = %08h",
            dut.CORE.csr_inst.mepc
        );

        $display(
            "MTVEC  = %08h",
            dut.CORE.csr_inst.mtvec_out
        );

        //-------------------------------------------------
        // Verify interrupt
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "ERROR: TIMER trap classified as exception"
            );

        end

        //-------------------------------------------------
        // Allow CSR mcause to update
        //-------------------------------------------------

        @(posedge pg_riscv32_mp_clk_in);
        #1;

        //-------------------------------------------------
        // Machine timer interrupt = cause 7
        //
        // Interrupt bit = 1
        //
        // MCAUSE = 0x80000007
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mcause !== 32'h80000007) begin

            $fatal(
                1,
                "ERROR: Wrong TIMER MCAUSE. Expected 80000007, got %08h",
                dut.CORE.csr_inst.mcause
            );

        end

        $display(
            "MCAUSE = %08h : PASS",
            dut.CORE.csr_inst.mcause
        );

//=========================================================
// Deassert timer interrupt
//=========================================================

@(negedge pg_riscv32_mp_clk_in);

pg_riscv32_mp_tirq_in = 1'b0;

$display("");
$display("[%0t] TB: TIMER INTERRUPT DEASSERTED", $time);
$display("");

//=========================================================
// Wait for trap handler to execute
//=========================================================

$display("==============================================");
$display(" WAITING FOR TRAP HANDLER");
$display("==============================================");

fork : TRAP_HANDLER_WAIT

    begin : WAIT_TRAP_HANDLER

        wait (
            (dut.CORE.pc_reg_out == dut.CORE.csr_inst.mtvec_out)
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: TRAP HANDLER ENTERED", $time);
        $display("PC    = %08h",
                 dut.CORE.pc_reg_out);
        $display("MTVEC = %08h",
                 dut.CORE.csr_inst.mtvec_out);
        $display("==============================================");
        $display("");

    end

    begin : TRAP_HANDLER_TIMEOUT

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: Trap handler was not entered"
        );

    end

join_any

disable TRAP_HANDLER_WAIT;


//=========================================================
// Wait for MRET
//=========================================================

$display("==============================================");
$display(" WAITING FOR MRET");
$display("==============================================");

fork : MRET_WAIT

    begin : WAIT_MRET

        wait (
            dut.CORE.machine_control_inst.mret === 1'b1
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: MRET DETECTED", $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : MRET_TIMEOUT

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: MRET was not executed"
        );

    end

join_any

disable MRET_WAIT;


//=========================================================
// Wait for PC to return to interrupted instruction
//=========================================================

$display("==============================================");
$display(" WAITING FOR INTERRUPTED PC");
$display("==============================================");

fork : MRET_PC_WAIT

    begin : WAIT_RETURN_PC

        wait (
            dut.CORE.pc_reg_out ==
            dut.CORE.csr_inst.mepc
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: RETURNED FROM INTERRUPT",
                 $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : RETURN_PC_TIMEOUT

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: PC did not return to MEPC after MRET"
        );

    end

join_any

disable MRET_PC_WAIT;


//=========================================================
// Full timer interrupt test passed
//=========================================================

$display("");
$display("==============================================");
$display(" TIMER INTERRUPT + MRET TEST PASSED");
$display("==============================================");
$display("");


$display("");
$display("==============================================");
$display(" NOW CHECKING INSTRUCTIONS AFTER MRET");
$display("==============================================");
$display("");

repeat (20) begin
    @(posedge pg_riscv32_mp_clk_in);

    $display("AFTER MRET: PC=%08h INSTR=%08h",
             dut.CORE.pc_reg_out,
             dut.CORE.instr_out);
end

$display("");
$display("==============================================");
$display(" POST-MRET EXECUTION CHECK COMPLETE");
$display("==============================================");
$display("");

program_done = 1'b1;

print_coverage();

$fflush(rtl_log);
$fclose(rtl_log);

$finish;
    end

end




//=========================================================
// C TIMER INTERRUPT PENDING WITH MIE DISABLED
//=========================================================

initial begin

    if (c_timer_pending_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_timer_pending_test requires RISCV_DV_MODE=0"
            );
        end

        $display("");
        $display("=================================================");
        $display(" TIMER IRQ PENDING WITH GLOBAL MIE DISABLED");
        $display("=================================================");
        $display("");

        // Wait for reset release
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Wait for C program
        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == 32'h00000002
        );

        $display("");
        $display("[%0t] TIMER PENDING TEST: PROGRAM READY",
                 $time);

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );

        // Check global interrupt is disabled
        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b0) begin
            $fatal(
                1,
                "ERROR: MSTATUS.MIE should be 0"
            );
        end

        // Check timer interrupt is enabled
        if (dut.CORE.csr_inst.mie[7] !== 1'b1) begin
            $fatal(
                1,
                "ERROR: MIE.MTIE should be 1"
            );
        end

        $display("MSTATUS.MIE = 0 : PASS");
        $display("MIE.MTIE     = 1 : PASS");

        //=================================================
        // Assert TIMER interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] ASSERTING TIMER IRQ WITH MIE=0",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;

        //=================================================
        // Wait several cycles
        //=================================================

        repeat (20)
            @(posedge pg_riscv32_mp_clk_in);

        //=================================================
        // Check interrupt was NOT taken
        //=================================================

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $fatal(
                1,
                "ERROR: TIMER IRQ WAS TAKEN WHILE MIE=0"
            );

        end

        $display("");
        $display("TIMER IRQ pending with MIE=0 : PASS");
        $display("");

        // Deassert timer interrupt
        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_tirq_in = 1'b0;

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end

//=========================================================
// C TIMER IRQ ACTIVE WITH MTIE DISABLED
//=========================================================

initial begin

    if (c_timer_mtie_disabled_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_timer_mtie_disabled_test requires RISCV_DV_MODE=0"
            );
        end

        $display("");
        $display("=================================================");
        $display(" TIMER IRQ ACTIVE WITH MTIE DISABLED");
        $display("=================================================");
        $display("");

        // Wait for reset release
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Wait for C program
        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == 32'h00000003
        );

        $display("");
        $display(
            "[%0t] TIMER MTIE-DISABLED TEST: PROGRAM READY",
            $time
        );

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );


        //=================================================
        // Check MSTATUS.MIE = 1
        //=================================================

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE should be 1"
            );

        end


        //=================================================
        // Check MIE.MTIE = 0
        //=================================================

        if (dut.CORE.csr_inst.mie[7] !== 1'b0) begin

            $fatal(
                1,
                "ERROR: MIE.MTIE should be 0"
            );

        end

        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MTIE     = 0 : PASS");


        //=================================================
        // Assert TIMER interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] ASSERTING TIMER IRQ WITH MTIE=0",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;


        //=================================================
        // Wait several cycles
        //=================================================

        repeat (20)
            @(posedge pg_riscv32_mp_clk_in);


        //=================================================
        // Check interrupt was NOT taken
        //=================================================

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $fatal(
                1,
                "ERROR: TIMER IRQ WAS TAKEN WHILE MTIE=0"
            );

        end


        $display("");
        $display("TIMER IRQ active with MTIE=0 : PASS");
        $display("Expected combination:");
        $display("<active,disabled,enabled>");
        $display("");


        //=================================================
        // Deassert timer interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_tirq_in = 1'b0;


        //=================================================
        // Finish test
        //=================================================

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end


//=========================================================
// C TIMER IRQ ACTIVE WITH BOTH MTIE AND GLOBAL MIE DISABLED
//=========================================================

initial begin

    if (c_timer_both_disabled_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_timer_both_disabled_test requires RISCV_DV_MODE=0"
            );
        end

        $display("");
        $display("=================================================");
        $display(" TIMER IRQ ACTIVE WITH MTIE=0 AND MIE=0");
        $display("=================================================");
        $display("");

        // Wait for reset release
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Wait for C program
        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == 32'h00000004
        );

        $display("");
        $display(
            "[%0t] TIMER BOTH-DISABLED TEST: PROGRAM READY",
            $time
        );

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );

        //=================================================
        // Check MSTATUS.MIE = 0
        //=================================================

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b0) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE should be 0"
            );

        end

        //=================================================
        // Check MIE.MTIE = 0
        //=================================================

        if (dut.CORE.csr_inst.mie[7] !== 1'b0) begin

            $fatal(
                1,
                "ERROR: MIE.MTIE should be 0"
            );

        end

        $display("MSTATUS.MIE = 0 : PASS");
        $display("MIE.MTIE     = 0 : PASS");

        //=================================================
        // Assert TIMER interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] ASSERTING TIMER IRQ WITH MIE=0 AND MTIE=0",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;

        //=================================================
        // Wait several cycles
        //=================================================

        repeat (20)
            @(posedge pg_riscv32_mp_clk_in);

        //=================================================
        // Interrupt MUST NOT be taken
        //=================================================

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $fatal(
                1,
                "ERROR: TIMER IRQ WAS TAKEN WHILE MIE=0 AND MTIE=0"
            );

        end

        $display("");
        $display("TIMER IRQ active with MIE=0 and MTIE=0 : PASS");
        $display("");
        $display("Expected combination:");
        $display("<active,disabled,disabled>");
        $display("");

        //=================================================
        // Deassert timer interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_tirq_in = 1'b0;

        //=================================================
        // Finish test
        //=================================================

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end


//=========================================================
// MIP COMBINATION COVERAGE TEST
//
// Covers:
// MSIP MTIP MEIP
//  0    0    0
//  0    0    1
//  0    1    0
//  0    1    1
//  1    0    0
//  1    0    1
//  1    1    0
//  1    1    1
//=========================================================

initial begin

    if (c_mip_cross_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_mip_cross_test requires RISCV_DV_MODE=0"
            );
        end

        wait (pg_riscv32_mp_rst_in == 1'b0);

        $display("");
        $display("=================================================");
        $display("       MIP COMBINATION COVERAGE TEST");
        $display("=================================================");
        $display("");

        //-----------------------------------------------------
        // 000
        // MSIP=0 MTIP=0 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 000", $time);

        system_cov.sample_interrupt(
            1'b0,                  // taken
            4'b0000,               // cause

            1'b0,                  // software IRQ
            1'b0,                  // timer IRQ
            1'b0,                  // external IRQ

            dut.CORE.csr_inst.mie,

            32'h00000000,          // MIP

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

        system_cov.sample_mip_pending(
    1'b0,   // MSIP
    1'b0,   // MTIP
    1'b0    // MEIP
);

        //-----------------------------------------------------
        // 001
        // MSIP=0 MTIP=0 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 001", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b0,
            1'b0,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000800,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );
system_cov.sample_mip_pending(
    1'b0,
    1'b0,
    1'b1
);

        //-----------------------------------------------------
        // 010
        // MSIP=0 MTIP=1 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 010", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b0,
            1'b1,
            1'b0,

            dut.CORE.csr_inst.mie,

            32'h00000080,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b0,
    1'b1,
    1'b0
);
        //-----------------------------------------------------
        // 011
        // MSIP=0 MTIP=1 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 011", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b0,
            1'b1,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000880,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b0,
    1'b1,
    1'b1
);
        //-----------------------------------------------------
        // 100
        // MSIP=1 MTIP=0 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 100", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b0,
            1'b0,

            dut.CORE.csr_inst.mie,

            32'h00000008,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b1,
    1'b0,
    1'b0
);
        //-----------------------------------------------------
        // 101
        // MSIP=1 MTIP=0 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 101", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b0,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000808,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b1,
    1'b0,
    1'b1
);
        //-----------------------------------------------------
        // 110
        // MSIP=1 MTIP=1 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 110", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b1,
            1'b0,

            dut.CORE.csr_inst.mie,

            32'h00000088,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b1,
    1'b1,
    1'b0
);
        //-----------------------------------------------------
        // 111
        // MSIP=1 MTIP=1 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 111", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b1,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000888,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );
system_cov.sample_mip_pending(
    1'b1,
    1'b1,
    1'b1
);

        //-----------------------------------------------------
        // Done
        //-----------------------------------------------------

        $display("");
        $display("=================================================");
        $display("       MIP COMBINATION SAMPLING COMPLETE");
        $display("=================================================");
        $display("");

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end

//=========================================================
// DIRECTED C SOFTWARE INTERRUPT TEST
//=========================================================

initial begin

    if (c_software_irq_test) begin

        if (RISCV_DV_MODE) begin

            $fatal(
                1,
                "ERROR: c_software_irq_test requires RISCV_DV_MODE=0"
            );

        end

        $display("");
        $display("=================================================");
        $display("     DIRECTED C SOFTWARE INTERRUPT TEST");
        $display("=================================================");
        $display("");

        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);

        //-------------------------------------------------
        // Wait for C program
        //-------------------------------------------------

        $display(
            "[%0t] TB: Waiting for C program to enable SOFTWARE IRQ",
            $time
        );

        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == IRQ_READY_VALUE
        );

        //-------------------------------------------------
        // Check MSTATUS.MIE
        //-------------------------------------------------

        $display("");
        $display("[%0t] TB: SOFTWARE PROGRAM READY", $time);

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE is not enabled"
            );

        end

        //-------------------------------------------------
        // Check MIE.MSIE = bit 3
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mie[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MIE.MSIE is not enabled"
            );

        end

        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MSIE     = 1 : PASS");

        //-------------------------------------------------
        // Assert SOFTWARE interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: ASSERTING SOFTWARE INTERRUPT",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_sirq_in = 1'b1;

        //-------------------------------------------------
        // Wait for trap
        //-------------------------------------------------

        fork : SOFTWARE_IRQ_WAIT

            begin : WAIT_SOFTWARE_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

            end

            begin : SOFTWARE_IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: SOFTWARE interrupt was NOT taken within 1000 cycles"
                );

            end

        join_any

        disable SOFTWARE_IRQ_WAIT;

        //-------------------------------------------------
        // Display trap
        //-------------------------------------------------

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: SOFTWARE INTERRUPT TAKEN",
            $time
        );
        $display("***********************************************");

        $display(
            "CAUSE  = %08h",
            dut.CORE.machine_control_inst.cause_out
        );

        $display(
            "I_OR_E = %b",
            dut.CORE.machine_control_inst.i_or_e_out
        );

        $display(
            "MCAUSE = %08h",
            dut.CORE.csr_inst.mcause
        );

        $display(
            "MEPC   = %08h",
            dut.CORE.csr_inst.mepc
        );

        $display(
            "MTVEC  = %08h",
            dut.CORE.csr_inst.mtvec_out
        );

        //-------------------------------------------------
        // Verify interrupt classification
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "ERROR: SOFTWARE trap classified as exception"
            );

        end

        //-------------------------------------------------
        // Allow CSR update
        //-------------------------------------------------

        @(posedge pg_riscv32_mp_clk_in);
        #1;

        //-------------------------------------------------
        // Machine software interrupt = cause 3
        //
        // MCAUSE = 0x80000003
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mcause !== 32'h80000003) begin

            $fatal(
                1,
                "ERROR: Wrong SOFTWARE MCAUSE. Expected 80000003, got %08h",
                dut.CORE.csr_inst.mcause
            );

        end

        $display(
            "MCAUSE = %08h : PASS",
            dut.CORE.csr_inst.mcause
        );

        //-------------------------------------------------
        // Deassert software interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_sirq_in = 1'b0;

        $display("");
        $display(
            "[%0t] TB: SOFTWARE INTERRUPT DEASSERTED",
            $time
        );

//=========================================================
// Wait for trap handler to execute
//=========================================================

$display("==============================================");
$display(" WAITING FOR TRAP HANDLER");
$display("==============================================");

fork : TRAP_HANDLER_WAIT_SW

    begin : WAIT_TRAP_HANDLER_SW

        wait (
            dut.CORE.pc_reg_out ==
            dut.CORE.csr_inst.mtvec_out
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: TRAP HANDLER ENTERED", $time);
        $display("PC    = %08h",
                 dut.CORE.pc_reg_out);
        $display("MTVEC = %08h",
                 dut.CORE.csr_inst.mtvec_out);
        $display("==============================================");
        $display("");

    end

    begin : TRAP_HANDLER_TIMEOUT_SW

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: SOFTWARE TRAP HANDLER WAS NOT ENTERED"
        );

    end

join_any

disable TRAP_HANDLER_WAIT_SW;

//=========================================================
// Wait for MRET
//=========================================================

$display("==============================================");
$display(" WAITING FOR MRET");
$display("==============================================");

fork : MRET_WAIT_SW

    begin : WAIT_MRET_SW

        wait (
            dut.CORE.machine_control_inst.mret === 1'b1
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: MRET DETECTED", $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : MRET_TIMEOUT_SW

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: SOFTWARE INTERRUPT MRET WAS NOT EXECUTED"
        );

    end

join_any

disable MRET_WAIT_SW;

//=========================================================
// Wait for PC to return to interrupted instruction
//=========================================================

$display("==============================================");
$display(" WAITING FOR INTERRUPTED PC");
$display("==============================================");

fork : MRET_PC_WAIT_SW

    begin : WAIT_RETURN_PC_SW

        wait (
            dut.CORE.pc_reg_out ==
            dut.CORE.csr_inst.mepc
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: RETURNED FROM SOFTWARE INTERRUPT",
                 $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : RETURN_PC_TIMEOUT_SW

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: PC DID NOT RETURN TO MEPC AFTER SOFTWARE INTERRUPT MRET"
        );

    end

join_any

disable MRET_PC_WAIT_SW;

//=========================================================
// Check instructions after MRET
//=========================================================

$display("");
$display("==============================================");
$display(" SOFTWARE INTERRUPT RETURNED TO MEPC");
$display("==============================================");
$display("MEPC = %08h", dut.CORE.csr_inst.mepc);
$display("PC   = %08h", dut.CORE.pc_reg_out);
$display("");

//=========================================================
// Wait for execution after MRET
//=========================================================

$display("==============================================");
$display(" WAITING FOR INSTRUCTIONS AFTER MRET");
$display("==============================================");

repeat (20) begin

    @(posedge pg_riscv32_mp_clk_in);

    $display(
        "[%0t] AFTER MRET: PC=%08h INSTR=%08h",
        $time,
        dut.CORE.pc_reg_out,
        dut.CORE.instr_out
    );

end

$display("");
$display("==============================================");
$display(" POST-MRET EXECUTION CHECK COMPLETE");
$display("==============================================");
$display("");

program_done = 1'b1;

print_coverage();

$fflush(rtl_log);
$fclose(rtl_log);

$finish;
    end

end
//=========================================================
// INTERRUPT DEBUG MONITOR
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        //-------------------------------------------------
        // Show IRQ inputs when asserted
        //-------------------------------------------------

        if (pg_riscv32_mp_sirq_in ||
            pg_riscv32_mp_tirq_in ||
            pg_riscv32_mp_eirq_in) begin

            $display(
                "[%0t] IRQ INPUT: S=%b T=%b E=%b MSTATUS=%08h MIE=%08h MIP=%08h",
                $time,

                pg_riscv32_mp_sirq_in,
                pg_riscv32_mp_tirq_in,
                pg_riscv32_mp_eirq_in,

                dut.CORE.csr_inst.mstatus_out,
                dut.CORE.csr_inst.mie,
                dut.CORE.csr_inst.mip
            );

        end

        //-------------------------------------------------
        // Show when trap is taken
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $display("");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("[%0t] INTERRUPT/TRAP TAKEN", $time);

            $display("CAUSE       = %08h",
                     dut.CORE.machine_control_inst.cause_out);

            $display("MSTATUS     = %08h",
                     dut.CORE.csr_inst.mstatus_out);

            $display("MIE         = %08h",
                     dut.CORE.csr_inst.mie);

            $display("MIP         = %08h",
                     dut.CORE.csr_inst.mip);

            $display("MEPC        = %08h",
                     dut.CORE.csr_inst.mepc);

            $display("MTVEC       = %08h",
                     dut.CORE.csr_inst.mtvec_out);

            $display("I_OR_E      = %b",
                     dut.CORE.machine_control_inst.i_or_e_out);

            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("");

        end

    end

end

//=========================================================
// RISC-V-DV EXTERNAL INTERRUPT SEQUENCE
//=========================================================

initial begin

    if (dv_irq_test) begin

        if (!RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: enable_irq_seq requires RISCV_DV_MODE=1"
            );
        end

        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);

        $display("");
        $display("==============================================");
        $display(" DV EXTERNAL INTERRUPT SEQUENCE");
        $display("==============================================");

        //-------------------------------------------------
        // Wait until DV program enables interrupts
        //-------------------------------------------------

        $display(
            "[%0t] DV: Waiting for MSTATUS.MIE and MIE.MEIE",
            $time
        );

        wait (
            dut.CORE.csr_inst.mstatus_out[3] === 1'b1 &&
            dut.CORE.csr_inst.mie[11]        === 1'b1
        );

        //-------------------------------------------------
        // Capture DYNAMIC MTVEC
        // No fixed PC is used.
        //-------------------------------------------------

        irq_mtvec = dut.CORE.csr_inst.mtvec_out;

        $display(
            "[%0t] DV: MSTATUS.MIE = 1",
            $time
        );

        $display(
            "[%0t] DV: MIE.MEIE = 1",
            $time
        );

        $display(
            "[%0t] DV: MTVEC = %08h",
            $time,
            irq_mtvec
        );

        //-------------------------------------------------
        // Allow the core to execute normally
        //-------------------------------------------------

        repeat (5)
            @(posedge pg_riscv32_mp_clk_in);

        //-------------------------------------------------
        // IMPORTANT:
        // Mark the RTL log BEFORE injecting the IRQ.
        //
        // Spike will never receive this externally
        // injected interrupt, therefore comparison must
        // stop here.
        //-------------------------------------------------

        $fdisplay(
            rtl_log,
            "# IRQ_INJECTED"
        );

        $fflush(rtl_log);

        //-------------------------------------------------
        // Assert external interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_eirq_in = 1'b1;

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] DV: EXTERNAL IRQ ASSERTED",
            $time
        );
        $display("***********************************************");

        //-------------------------------------------------
        // Wait for interrupt trap
        //-------------------------------------------------

        fork : DV_IRQ_WAIT

            begin : WAIT_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

                irq_taken = 1'b1;

                $display("");
                $display("***********************************************");
                $display(
                    "[%0t] DV: EXTERNAL INTERRUPT TAKEN",
                    $time
                );
                $display("***********************************************");

               $display(
    "CAUSE FIELD = %0d",
    dut.CORE.machine_control_inst.cause_out
);

$display(
    "I_OR_E      = %b",
    dut.CORE.machine_control_inst.i_or_e_out
);

$display(
    "MCAUSE      = %08h",
    dut.CORE.csr_inst.mcause
);

$display(
    "MEPC        = %08h",
    dut.CORE.csr_inst.mepc
);

$display(
    "MTVEC       = %08h",
    dut.CORE.csr_inst.mtvec_out
);

            end

            begin : IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "DV ERROR: External interrupt was NOT taken"
                );

            end

        join_any

        disable DV_IRQ_WAIT;

        //-------------------------------------------------
        // Verify interrupt classification
        //-------------------------------------------------

        if (!irq_taken) begin
            $fatal(
                1,
                "DV ERROR: IRQ was not taken"
            );
        end

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "DV ERROR: Trap classified as exception instead of interrupt"
            );

        end

 //-------------------------------------------------
// Verify machine external interrupt cause
//
// RISC-V machine external interrupt:
//   interrupt bit = 1
//   cause         = 11
//
// Therefore:
//   mcause = 32'h8000000B
//-------------------------------------------------

// STATE_TRAP_TAKEN is detected at a clock edge.
// The CSR is sequential, so allow the following
// clock edge for mcause to update.
@(posedge pg_riscv32_mp_clk_in);
#1;

$display("");
$display("========== INTERRUPT CSR CHECK ==========");
$display("CAUSE FIELD = %0d",
         dut.CORE.machine_control_inst.cause_out);

$display("I_OR_E      = %b",
         dut.CORE.machine_control_inst.i_or_e_out);

$display("MCAUSE      = %08h",
         dut.CORE.csr_inst.mcause);

$display("MEPC        = %08h",
         dut.CORE.csr_inst.mepc);

$display("MTVEC       = %08h",
         dut.CORE.csr_inst.mtvec_out);

if (dut.CORE.csr_inst.mcause !== 32'h8000000B) begin

    $fatal(
        1,
        "DV ERROR: Wrong MCAUSE. Expected 8000000B, got %08h",
        dut.CORE.csr_inst.mcause
    );

end

$display("MCAUSE = %08h : PASS",
         dut.CORE.csr_inst.mcause);

$display("========================================");

        //-------------------------------------------------
        // Verify MTVEC did not unexpectedly change
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mtvec_out !== irq_mtvec) begin

            $fatal(
                1,
                "DV ERROR: MTVEC changed unexpectedly"
            );

        end

        //-------------------------------------------------
        // Deassert external IRQ
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_eirq_in = 1'b0;

        $display("");
        $display(
            "[%0t] DV: EXTERNAL IRQ DEASSERTED",
            $time
        );

        $display("");
        $display("==============================================");
        $display(" DV EXTERNAL INTERRUPT ENTRY PASSED");
        $display("==============================================");
        $display("");

    end

end


//=========================================================
// DELAYED DATA RESPONSE MODEL
// Used to hit pipeline memory-stall coverage
//=========================================================

parameter integer MEM_RESPONSE_DELAY = 2;

bit mem_delay_active;

initial begin
    mem_delay_active = 1'b0;
end

always @(negedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        !mem_delay_active &&
        dut.CORE.pg_riscv32_mp_dmreq_out &&
        !dut.CORE.pg_riscv32_mp_dmwen_out) begin

        mem_delay_active = 1'b1;

        $display("");
        $display("==============================================");
        $display("[%0t] TB: DELAYING LOAD RESPONSE", $time);
        $display("==============================================");

        // Force data_valid LOW so core sees memory waiting
        force dut.CORE.pg_riscv32_mp_data_valid = 1'b0;

        $display("[%0t] data_valid = 0", $time);

        // Keep response invalid for 2 clock cycles
        repeat (MEM_RESPONSE_DELAY)
            @(negedge pg_riscv32_mp_clk_in);

        // Release the force
        release dut.CORE.pg_riscv32_mp_data_valid;

        $display("[%0t] data_valid RELEASED", $time);

        mem_delay_active = 1'b0;

    end

end
endmodule*/



`timescale 1ns/1ps

import pragya_pkg::*;

module tb_pragya_top;

    //=========================================================
    // Configuration
    //=========================================================

    parameter integer MAX_CYCLES = 1000000;

    // 0 = C Program
    // 1 = RISC-V-DV
    parameter bit RISCV_DV_MODE = 1'b0;

    localparam logic [31:0] RISCV_DV_TOHOST_ADDR = 32'h80008000;
    localparam logic [31:0] RISCV_DV_PASS_VALUE  = 32'h00000001;

   // C Program completion
   localparam logic [31:0] C_TOHOST_ADDR = 32'h80008000;
   localparam logic [31:0] C_PASS_VALUE  = 32'h00000001;
  // C interrupt test synchronization
   localparam logic [31:0] IRQ_READY_ADDR  = 32'h80007FF0;
   localparam logic [31:0] IRQ_READY_VALUE = 32'h00000001;
   localparam logic [31:0] TIMER_PENDING_READY_VALUE = 32'h00000002;

    //=========================================================
    // DUT Inputs
    //=========================================================

    logic pg_riscv32_mp_clk_in;
    logic pg_riscv32_mp_rst_in;
    logic pg_riscv32_mp_debug_req_in;
    logic pg_riscv32_mp_eirq_in;
    logic pg_riscv32_mp_tirq_in;
    logic pg_riscv32_mp_sirq_in;
    logic program_done;
    logic [31:0] irq_mtvec;

    //=========================================================
    // Testbench Variables
    //=========================================================

    integer rtl_log;
    integer cycle_count;
 // RV32M operation
    md_op_e md_operation;
 // Interrupt sequence enable
    bit irq_taken;
    bit dv_irq_test;
    bit c_irq_test;
    bit c_timer_irq_test;
    bit c_software_irq_test;
    bit c_timer_pending_test;
    bit c_external_pending_test;
    bit c_mip_cross_test;
    bit c_software_pending_test;
    bit c_timer_mtie_disabled_test;
    bit c_timer_both_disabled_test;
    bit c_wfi_timer_test;
    //=========================================================
    // Coverage Objects
    //=========================================================

    rv32i_coverage        rv32i_cov;
    rv32m_coverage        rv32m_cov;
    load_store_coverage   lsu_cov;
    branch_jump_coverage  branch_cov;
    pipeline_coverage     pipe_cov;
    rv32_system_coverage system_cov;

    //=========================================================
    // DUT
    //=========================================================

    pragya_top dut(

        .pg_riscv32_mp_clk_in (pg_riscv32_mp_clk_in),
        .pg_riscv32_mp_rst_in (pg_riscv32_mp_rst_in),
        .pg_riscv32_mp_debug_req_in(pg_riscv32_mp_debug_req_in),
        .pg_riscv32_mp_eirq_in(pg_riscv32_mp_eirq_in),
        .pg_riscv32_mp_tirq_in(pg_riscv32_mp_tirq_in),
        .pg_riscv32_mp_sirq_in(pg_riscv32_mp_sirq_in)

    );

    //=========================================================
    // Create Coverage Objects
    //=========================================================

    initial begin

        rv32i_cov  = new();
        rv32m_cov  = new();
	system_cov = new();
        lsu_cov    = new();
        branch_cov = new();
        pipe_cov   = new();

    end

//=========================================================
// TEST MODE SELECTION
//=========================================================

initial begin

    c_irq_test          = 1'b0;
    c_timer_irq_test    = 1'b0;
    c_software_irq_test = 1'b0;
    c_timer_pending_test = 1'b0;
    c_external_pending_test = 1'b0;
    c_mip_cross_test      = 1'b0;
    c_timer_mtie_disabled_test = 1'b0;
    c_timer_both_disabled_test = 1'b0;
    c_software_pending_test = 1'b0;
    dv_irq_test         = 1'b0;

c_wfi_timer_test = 1'b0;
    if ($test$plusargs("c_wfi_timer_test"))
        c_wfi_timer_test = 1'b1;

    $display("c_wfi_timer_test    = %b", c_wfi_timer_test);

    if ($test$plusargs("c_irq_test"))
        c_irq_test = 1'b1;

    if ($test$plusargs("c_timer_irq_test"))
        c_timer_irq_test = 1'b1;

    if ($test$plusargs("c_software_irq_test"))
        c_software_irq_test = 1'b1;

    if ($test$plusargs("c_timer_pending_test"))
        c_timer_pending_test = 1'b1;

    if ($test$plusargs("c_timer_mtie_disabled_test"))
        c_timer_mtie_disabled_test = 1'b1;

    if ($test$plusargs("c_mip_cross_test"))
        c_mip_cross_test = 1'b1;

    if ($test$plusargs("c_timer_both_disabled_test"))
        c_timer_both_disabled_test = 1'b1;

    if ($test$plusargs("c_external_pending_test"))
        c_external_pending_test = 1'b1;

    if ($test$plusargs("c_software_pending_test"))
        c_software_pending_test = 1'b1;



    if ($test$plusargs("enable_irq_seq"))
        dv_irq_test = 1'b1;

    $display("");
    $display("==============================================");
    $display("TB TEST MODE");
    $display("==============================================");
    $display("RISCV_DV_MODE       = %b", RISCV_DV_MODE);
    $display("c_irq_test          = %b", c_irq_test);
    $display("c_timer_irq_test    = %b", c_timer_irq_test);
    $display("c_timer_pending_test    = %b", c_timer_pending_test);
    $display("c_timer_mtie_disabled_test = %b", c_timer_mtie_disabled_test);
    $display("c_external_pending_test    = %b", c_external_pending_test);
    $display("c_software_pending_test    = %b", c_software_pending_test);
    $display("c_software_irq_test = %b", c_software_irq_test);
    $display("dv_irq_test         = %b", dv_irq_test);
    $display("==============================================");
    $display("");

end

    //=========================================================
    // Clock Generation
    //=========================================================

    initial begin

        pg_riscv32_mp_clk_in = 1'b0;

        forever
            #5 pg_riscv32_mp_clk_in = ~pg_riscv32_mp_clk_in;

    end

    //=========================================================
    // Reset Generation
    //=========================================================

    initial begin

        pg_riscv32_mp_rst_in = 1'b1;
        pg_riscv32_mp_debug_req_in = 1'b0;
        pg_riscv32_mp_eirq_in = 1'b0;
        pg_riscv32_mp_tirq_in = 1'b0;
        pg_riscv32_mp_sirq_in = 1'b0;

        repeat(4)
            @(posedge pg_riscv32_mp_clk_in);

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_rst_in = 1'b0;

        $display("[%0t] Reset Released",$time);

    end

    //=========================================================
    // RTL Log
    //=========================================================

    initial begin

        rtl_log = $fopen("rtl.log","w");

        if(rtl_log==0) begin

            $display("ERROR : Cannot open rtl.log");
            $finish;

        end

        $display("RTL log opened successfully.");

    end

 initial begin
    program_done = 1'b0;
    irq_mtvec    = 32'h0;
    irq_taken    = 1'b0;

  end
    //=========================================================
    // Coverage Report Task
    //=========================================================

    task automatic print_coverage;

    begin

        $display("");
        $display("======================================");
        $display("      FUNCTIONAL COVERAGE");
        $display("======================================");

        rv32i_cov.report();

        rv32m_cov.report();

        lsu_cov.report();

        branch_cov.report();

        pipe_cov.report();
	system_cov.report();

        $display("======================================");
        $display("");

    end

    endtask

//=========================================================
// REGISTER COMMIT LOGGER
// (Used ONLY for RTL vs Spike comparison)
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if(!pg_riscv32_mp_rst_in) begin

        if(!program_done && dut.CORE.commit_valid) begin

            //------------------------------------------------
            // RTL Log
            //------------------------------------------------

            $fdisplay(
                rtl_log,
                "core   0: 0x%08h (0x%08h) x%0d 0x%08h",
                dut.CORE.commit_pc,
                dut.CORE.commit_instr,
                dut.CORE.commit_rd,
                dut.CORE.commit_data
            );

            $fflush(rtl_log);

            //------------------------------------------------
            // RV32M Coverage
            //------------------------------------------------

            if ((dut.CORE.commit_instr[6:0]  == OPC_OP) &&
                (dut.CORE.commit_instr[31:25] == 7'b0000001))
            begin

                case (dut.CORE.commit_instr[14:12])

                    3'b000: md_operation = MD_OP_MUL;
                    3'b001: md_operation = MD_OP_MULH;
                    3'b010: md_operation = MD_OP_MULHSU;
                    3'b011: md_operation = MD_OP_MULHU;
                    3'b100: md_operation = MD_OP_DIV;
                    3'b101: md_operation = MD_OP_DIVU;
                    3'b110: md_operation = MD_OP_REM;
                    3'b111: md_operation = MD_OP_REMU;

                    default: md_operation = MD_OP_MUL;

                endcase

                rv32m_cov.sample(

                    dut.CORE.commit_instr,
                    dut.CORE.commit_pc,
                    dut.CORE.commit_valid,
                    dut.CORE.commit_instr[19:15],
                    dut.CORE.commit_instr[24:20],
                    dut.CORE.commit_rd,
                    dut.CORE.commit_rs1_data,
                    dut.CORE.commit_rs2_data,
                    dut.CORE.commit_data,
                    md_operation

                );

            end

        end

    end

end


//=========================================================
// RV32I / Branch / Pipeline Coverage
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if (dut.CORE.commit_instr_valid &&
            !$isunknown(dut.CORE.commit_instr)) begin

            //------------------------------------------------
            // RV32I Coverage
            //
            // Exclude:
            //   RV32M  -> rv32m_cov
            //   SYSTEM -> system_cov
            //------------------------------------------------

            if ((dut.CORE.commit_instr[6:0] != OPC_SYSTEM) &&
                !((dut.CORE.commit_instr[6:0] == OPC_OP) &&
                  (dut.CORE.commit_instr[31:25] == 7'b0000001)))
            begin

                rv32i_cov.sample(

                    dut.CORE.commit_instr,
                    dut.CORE.commit_pc,
                    dut.CORE.commit_instr_valid,

                    dut.CORE.commit_instr[6:0],
                    dut.CORE.commit_instr[14:12],
                    dut.CORE.commit_instr[31:25],

                    dut.CORE.commit_instr[19:15],
                    dut.CORE.commit_instr[24:20],
                    dut.CORE.commit_rd,

                    dut.CORE.commit_data,

                    dut.CORE.final_reg_write

                );

            end


            //------------------------------------------------
            // Branch / Jump Coverage
            //
            // Keep this independent of RV32I instruction
            // coverage.
            //------------------------------------------------

            branch_cov.sample(

                dut.CORE.commit_instr,
                dut.CORE.commit_pc,
                dut.CORE.i_adder_out,
                dut.CORE.branch_taken_out

            );

        end


        //------------------------------------------------
        // Pipeline Coverage
        //------------------------------------------------

        pipe_cov.sample(

            dut.CORE.stallD,
            dut.CORE.flush_DE,
            dut.CORE.forward_a,
            dut.CORE.forward_b,

            dut.CORE.mem_req_out,
            dut.CORE.wait_for_mem,

            dut.CORE.final_reg_write

        );

    end

end

// SYSTEM COVERAGE

localparam STATE_TRAP_TAKEN = 4'b0100;

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        //----------------------------------------------------------
        // CSR COVERAGE
        //----------------------------------------------------------

        if (dut.CORE.commit_instr_valid &&
    dut.CORE.commit_instr[6:0] == 7'b1110011) begin

    system_cov.sample_csr(

        1'b1,

        // CSR address directly from committed instruction
        dut.CORE.commit_instr[31:20],

        // CSR operation directly from committed instruction
        dut.CORE.commit_instr[14:12],

        // CSR write
        // Immediate forms with rs1/zimm != 0 are writes.
        // For now preserve the existing RTL write indication.
        dut.CORE.csr_wr_en_reg_out,

        dut.CORE.csr_data_reg_out,
        dut.CORE.csr_data_out,

        dut.CORE.csr_inst.mstatus_out,
        dut.CORE.csr_inst.mie,
        dut.CORE.csr_inst.mtvec_out,
        dut.CORE.csr_inst.mepc,
        dut.CORE.csr_inst.mcause,
        dut.CORE.csr_inst.mtval,
        dut.CORE.csr_inst.mscratch,
        dut.CORE.csr_inst.mip,

        dut.CORE.csr_inst.mcycle,
        dut.CORE.csr_inst.minstret,

        dut.CORE.csr_inst.mie_out,
        dut.CORE.csr_inst.mpie_out,

        dut.CORE.csr_inst.mtvec_mode
    );

end

//----------------------------------------------------------
// TRAP COVERAGE
//----------------------------------------------------------

if (dut.CORE.machine_control_inst.curr_state ==
    STATE_TRAP_TAKEN) begin

    if (dut.CORE.machine_control_inst.i_or_e_out) begin

        //--------------------------------------------------
        // INTERRUPT
        //--------------------------------------------------

        system_cov.sample_interrupt(

            1'b1,

            dut.CORE.machine_control_inst.cause_out,

            dut.CORE.machine_control_inst.sip,
            dut.CORE.machine_control_inst.tip,
            dut.CORE.machine_control_inst.eip,

            dut.CORE.csr_inst.mie,

            (
                dut.CORE.csr_inst.mip |
                (pg_riscv32_mp_sirq_in ? 32'h00000008 : 32'h00000000) |
                (pg_riscv32_mp_tirq_in ? 32'h00000080 : 32'h00000000) |
                (pg_riscv32_mp_eirq_in ? 32'h00000800 : 32'h00000000)
            ),

            dut.CORE.csr_inst.mie_out,
            dut.CORE.csr_inst.mtvec_mode
        );

    end
    else begin

        //--------------------------------------------------
        // EXCEPTION
        //--------------------------------------------------
	system_cov.sample_exception(
    1'b1,

    dut.CORE.machine_control_inst.cause_out,

    dut.CORE.machine_control_inst.i_or_e_out,

    dut.CORE.csr_inst.mepc,
    dut.CORE.csr_inst.mtval,

    dut.CORE.csr_inst.mie_out,
    dut.CORE.csr_inst.mpie_out,

    // ECALL = MCAUSE 11
    (dut.CORE.machine_control_inst.cause_out == 4'b1011),

    // EBREAK = MCAUSE 3
    (dut.CORE.machine_control_inst.cause_out == 4'b0011),

    1'b0
);


    end

end
    end

end

//=========================================================
// MRET COVERAGE
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        !program_done) begin

        if (dut.CORE.machine_control_inst.mret === 1'b1) begin

            system_cov.sample_system_instruction(
                1'b0,    // ECALL
                1'b0,    // EBREAK
                1'b1     // MRET
            );

        end

    end

end
//=========================================================
// INTERRUPT REQUEST COVERAGE
//=========================================================
//
// Sample interrupt conditions even when the interrupt
// is NOT taken.
//
// This is required to cover:
//
//     MSTATUS.MIE = 0
//     MIE.MTIE    = 1
//     TIMER IRQ   = active
//
// In this case:
//     taken = 0
//
// The interrupt-cause coverpoint is protected by:
//     iff (trap_taken && is_interrupt)
//
// so this sample will NOT create a fake interrupt-cause
// hit. It only covers the interrupt enable/request state.
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        !program_done) begin



            system_cov.sample_interrupt(

                1'b0,                         // NOT TAKEN

                4'b0111,                      // no trap cause

                pg_riscv32_mp_sirq_in,
                pg_riscv32_mp_tirq_in,
                pg_riscv32_mp_eirq_in,

                dut.CORE.csr_inst.mie,
                (
    dut.CORE.csr_inst.mip |
    (pg_riscv32_mp_sirq_in ? 32'h00000008 : 32'h00000000) |
    (pg_riscv32_mp_tirq_in ? 32'h00000080 : 32'h00000000) |
    (pg_riscv32_mp_eirq_in ? 32'h00000800 : 32'h00000000)
),

                dut.CORE.csr_inst.mstatus_out[3],

                dut.CORE.csr_inst.mtvec_mode

            );



    end

end

//=========================================================
// LOAD COVERAGE
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if (!program_done &&
            dut.CORE.commit_instr_valid &&
            dut.CORE.mem_req_reg_out &&
            !dut.CORE.mem_write_reg_out) begin

            lsu_cov.sample(

                1'b1,
                1'b0,

                dut.CORE.funct3_reg_out,
                dut.CORE.i_adder_reg_out,
                dut.CORE.commit_data

            );

        end

    end

end


//=========================================================
// STORE COVERAGE + STORE LOGGER
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if (!program_done &&
            dut.CORE.commit_store) begin

            //------------------------------------------------
            // RTL Log
            //------------------------------------------------

            $fdisplay(
                rtl_log,
                "core   0: 0x%08h (0x%08h) mem 0x%08h 0x%08h",
                dut.CORE.commit_store_pc,
                dut.CORE.commit_store_instr,
                dut.CORE.commit_store_addr,
                dut.CORE.commit_store_data
            );

            $fflush(rtl_log);

            //------------------------------------------------
            // STORE COVERAGE
            //------------------------------------------------

            lsu_cov.sample(

                1'b1,
                1'b1,

                dut.CORE.commit_store_instr[14:12],
                dut.CORE.commit_store_addr,
                dut.CORE.commit_store_data

            );

        end

    end

end

//=========================================================
// C INTERRUPT READY DETECTOR
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
    (c_irq_test ||
     c_timer_irq_test ||
     c_timer_mtie_disabled_test ||
      c_timer_both_disabled_test ||
     c_software_irq_test ||
     c_timer_pending_test) &&
    !program_done) begin

        if (dut.CORE.commit_store &&
    dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
    (
        (!c_timer_pending_test &&
         !c_timer_mtie_disabled_test &&
         !c_timer_both_disabled_test &&
         dut.CORE.commit_store_data == IRQ_READY_VALUE)

        ||

        (c_timer_pending_test &&
         dut.CORE.commit_store_data == TIMER_PENDING_READY_VALUE)

        ||

        (c_timer_mtie_disabled_test &&
         dut.CORE.commit_store_data == 32'h00000003)

        ||

        (c_timer_both_disabled_test &&
         dut.CORE.commit_store_data == 32'h00000004)
    )) begin

            $display("");
            $display("==============================================");
            $display("[%0t] TB: C PROGRAM ENABLED INTERRUPTS",
                     $time);
            $display("==============================================");

            $display("MSTATUS = %08h",
                     dut.CORE.csr_inst.mstatus_out);

            $display("MIE     = %08h",
                     dut.CORE.csr_inst.mie);

            $display("MIP     = %08h",
                     dut.CORE.csr_inst.mip);

        end

    end

end

    //=========================================================
    // Console Monitor
    //=========================================================

    always @(posedge pg_riscv32_mp_clk_in) begin

        if(!pg_riscv32_mp_rst_in) begin

            //--------------------------------------------------
            // Register Commit
            //--------------------------------------------------

            if(dut.CORE.commit_valid) begin

                $display(
                    "PC=%08h INSTR=%08h x%0d=%08h",
                    dut.CORE.commit_pc,
                    dut.CORE.commit_instr,
                    dut.CORE.commit_rd,
                    dut.CORE.commit_data
                );

            end

            //--------------------------------------------------
            // Store Commit
            //--------------------------------------------------

            if(dut.CORE.commit_store) begin

                $display(
                    "PC=%08h INSTR=%08h MEM[%08h]=%08h",
                    dut.CORE.commit_store_pc,
                    dut.CORE.commit_store_instr,
                    dut.CORE.commit_store_addr,
                    dut.CORE.commit_store_data
                );

            end

        end

    end


    //=========================================================
    // X / Z CHECKER
    //=========================================================

    always @(posedge pg_riscv32_mp_clk_in) begin

        if(!pg_riscv32_mp_rst_in) begin

            if(dut.CORE.commit_valid) begin

                if($isunknown(dut.CORE.commit_pc))
                    $display("WARNING : commit_pc contains X/Z");

                if($isunknown(dut.CORE.commit_instr))
                    $display("WARNING : commit_instr contains X/Z");

                if($isunknown(dut.CORE.commit_rd))
                    $display("WARNING : commit_rd contains X/Z");

                if($isunknown(dut.CORE.commit_data))
                    $display("WARNING : commit_data contains X/Z");

            end

            if(dut.CORE.commit_store) begin

                if($isunknown(dut.CORE.commit_store_pc))
                    $display("WARNING : commit_store_pc contains X/Z");

                if($isunknown(dut.CORE.commit_store_instr))
                    $display("WARNING : commit_store_instr contains X/Z");

                if($isunknown(dut.CORE.commit_store_addr))
                    $display("WARNING : commit_store_addr contains X/Z");

                if($isunknown(dut.CORE.commit_store_data))
                    $display("WARNING : commit_store_data contains X/Z");

            end

        end

    end
       //=========================================================
    // Simulation Control
    //=========================================================

    initial begin

        cycle_count = 0;

        //-----------------------------------------------------
        // Wait for Reset Release
        //-----------------------------------------------------

        wait(pg_riscv32_mp_rst_in == 1'b0);

        $display("");
        $display("======================================");

        if(RISCV_DV_MODE)
            $display("Starting RISC-V-DV Program");
        else
            $display("Starting C Program");

        $display("======================================");
        $display("");

//-----------------------------------------------------
// Main Simulation Loop
//-----------------------------------------------------

while(cycle_count < MAX_CYCLES) begin

    @(posedge pg_riscv32_mp_clk_in);
    cycle_count++;

    if(!RISCV_DV_MODE) begin

        // -------- C PROGRAM MODE --------

        if(dut.CORE.commit_store &&
           dut.CORE.commit_store_addr == C_TOHOST_ADDR) begin

            if(dut.CORE.commit_store_data == 32'h1) begin

                $display("PROGRAM PASSED");
           program_done = 1'b1;     // stop all logging

                print_coverage();

                $fflush(rtl_log);
                $fclose(rtl_log);

                $finish;

            end
            else if(dut.CORE.commit_store_data == 32'h2) begin

                $display("PROGRAM FAILED");

          program_done = 1'b1;

                print_coverage();

                $fflush(rtl_log);
                $fclose(rtl_log);

                $finish;

            end

            // Ignore all other values (especially 0)

        end

    end
    else begin

        // -------- RISC-V-DV MODE --------

        if (dut.CORE.commit_store &&
    dut.CORE.commit_store_addr == RISCV_DV_TOHOST_ADDR &&
    dut.CORE.commit_store_data == RISCV_DV_PASS_VALUE) begin

    $display("RISC-V-DV PROGRAM COMPLETED");

    program_done = 1'b1;

    print_coverage();

    $fflush(rtl_log);
    $fclose(rtl_log);

    $finish;

end

    end

end
        //------------------------------------------------------
        // TIMEOUT
        //------------------------------------------------------

        $display("");
        $display("======================================");

        if(RISCV_DV_MODE)
            $display("RISC-V-DV SIMULATION TIMEOUT");
        else
            $display("C PROGRAM SIMULATION TIMEOUT");

        $display("======================================");

        $display("Cycles      = %0d",cycle_count);
        $display("MAX_CYCLES  = %0d",MAX_CYCLES);

        //------------------------------------------------------
        // Print Coverage Before Exiting
        //------------------------------------------------------

        print_coverage();

        //------------------------------------------------------
        // Close Log
        //------------------------------------------------------

        $fflush(rtl_log);
        $fclose(rtl_log);

        //------------------------------------------------------
        // Fatal Exit
        //------------------------------------------------------

        if(RISCV_DV_MODE)
            $fatal(1,"RISC-V-DV Simulation Timeout");
        else
            $fatal(1,"C Program Simulation Timeout");

    end
//=========================================================
// TRAP HANDLER DEBUG
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        if ((dut.CORE.pc_reg_out >= 32'h800031b8) &&
            (dut.CORE.pc_reg_out <= 32'h800031e0)) begin

            $display("");
            $display("========== TRAP HANDLER DEBUG ==========");
            $display("TIME            = %0t", $time);
            $display("PC              = %08h",
                     dut.CORE.pc_reg_out);
            $display("INSTR           = %08h",
                     dut.CORE.instr_reg_out);

            $display("commit_valid    = %b",
                     dut.CORE.commit_valid);

            $display("commit_store    = %b",
                     dut.CORE.commit_store);

            $display("mem_req         = %b",
                     dut.CORE.mem_req_reg_out);

            $display("mem_write       = %b",
                     dut.CORE.mem_write_reg_out);

            $display("wait_for_mem    = %b",
                     dut.CORE.wait_for_mem);

            $display("data_valid      = %b",
                     dut.CORE.pg_riscv32_mp_data_valid);

            $display("stallD          = %b",
                     dut.CORE.stallD);

            $display("flush_DE        = %b",
                     dut.CORE.flush_DE);

            $display("========================================");

        end

    end

end

//=========================================================
// WAIT UNTIL MACHINE INTERRUPTS ARE ENABLED
//=========================================================

task automatic wait_for_external_interrupt_enable;

    begin

        $display("");
        $display("==============================================");
        $display("[%0t] TB: Waiting for external interrupt enable", $time);
        $display("==============================================");

        wait (
            dut.CORE.csr_inst.mstatus_out[3] === 1'b1 &&
            dut.CORE.csr_inst.mie[11]        === 1'b1
        );

        $display("[%0t] TB: MSTATUS.MIE = 1", $time);
        $display("[%0t] TB: MIE.MEIE    = 1", $time);
        $display("[%0t] TB: MSTATUS     = %08h",
                 $time,
                 dut.CORE.csr_inst.mstatus_out);
        $display("[%0t] TB: MIE         = %08h",
                 $time,
                 dut.CORE.csr_inst.mie);
        $display("[%0t] TB: MIP         = %08h",
                 $time,
                 dut.CORE.csr_inst.mip);

    end

endtask


//=========================================================
// DIRECTED C EXTERNAL INTERRUPT TEST
//=========================================================

initial begin

    if (c_irq_test) begin

        if (RISCV_DV_MODE) begin

            $fatal(
                1,
                "ERROR: c_irq_test requires RISCV_DV_MODE=0"
            );

        end

        $display("");
        $display("=================================================");
        $display("      DIRECTED C EXTERNAL INTERRUPT TEST");
        $display("=================================================");
        $display("");


        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);


        //-------------------------------------------------
        // Wait for C program synchronization store
        //-------------------------------------------------

        $display(
            "[%0t] TB: Waiting for C program to enable EXTERNAL IRQ",
            $time
        );

        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == IRQ_READY_VALUE
        );


        //-------------------------------------------------
        // Check MSTATUS.MIE
        //-------------------------------------------------

        $display("");
        $display(
            "[%0t] TB: EXTERNAL INTERRUPT PROGRAM READY",
            $time
        );

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );


        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE is not enabled"
            );

        end


        //-------------------------------------------------
        // Check MIE.MEIE = bit 11
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mie[11] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MIE.MEIE is not enabled"
            );

        end


        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MEIE     = 1 : PASS");


        //-------------------------------------------------
        // Assert EXTERNAL interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: ASSERTING EXTERNAL INTERRUPT",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_eirq_in = 1'b1;


        //-------------------------------------------------
        // Wait for interrupt trap
        //-------------------------------------------------

        fork : EXTERNAL_IRQ_WAIT

            begin : WAIT_EXTERNAL_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

            end


            begin : EXTERNAL_IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: EXTERNAL interrupt was NOT taken within 1000 cycles"
                );

            end

        join_any

        disable EXTERNAL_IRQ_WAIT;


        //-------------------------------------------------
        // External interrupt taken
        //-------------------------------------------------

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: EXTERNAL INTERRUPT TAKEN",
            $time
        );
        $display("***********************************************");


        $display(
            "CAUSE  = %08h",
            dut.CORE.machine_control_inst.cause_out
        );

        $display(
            "I_OR_E = %b",
            dut.CORE.machine_control_inst.i_or_e_out
        );

        $display(
            "MCAUSE = %08h",
            dut.CORE.csr_inst.mcause
        );

        $display(
            "MEPC   = %08h",
            dut.CORE.csr_inst.mepc
        );

        $display(
            "MTVEC  = %08h",
            dut.CORE.csr_inst.mtvec_out
        );

        $display(
            "MIP    = %08h",
            dut.CORE.csr_inst.mip
        );


        //-------------------------------------------------
        // Verify interrupt classification
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "ERROR: EXTERNAL trap classified as exception"
            );

        end


        //-------------------------------------------------
        // Allow CSR mcause to update
        //-------------------------------------------------

        @(posedge pg_riscv32_mp_clk_in);
        #1;


        //-------------------------------------------------
        // Machine external interrupt = cause 11
        //
        // Interrupt bit = 1
        //
        // MCAUSE = 0x8000000B
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mcause !== 32'h8000000B) begin

            $fatal(
                1,
                "ERROR: Wrong EXTERNAL MCAUSE. Expected 8000000B, got %08h",
                dut.CORE.csr_inst.mcause
            );

        end


        $display(
            "MCAUSE = %08h : PASS",
            dut.CORE.csr_inst.mcause
        );


        //-------------------------------------------------
        // Deassert external interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_eirq_in = 1'b0;

        $display("");
        $display(
            "[%0t] TB: EXTERNAL INTERRUPT DEASSERTED",
            $time
        );
        $display("");


        //=================================================
        // Wait for trap handler
        //=================================================

        $display("==============================================");
        $display(" WAITING FOR TRAP HANDLER");
        $display("==============================================");


        fork : EXTERNAL_TRAP_HANDLER_WAIT

            begin : WAIT_EXTERNAL_TRAP_HANDLER

                wait (
                    dut.CORE.pc_reg_out ==
                    dut.CORE.csr_inst.mtvec_out
                );

                $display("");
                $display("==============================================");
                $display(
                    "[%0t] TB: TRAP HANDLER ENTERED",
                    $time
                );

                $display(
                    "PC    = %08h",
                    dut.CORE.pc_reg_out
                );

                $display(
                    "MTVEC = %08h",
                    dut.CORE.csr_inst.mtvec_out
                );

                $display("==============================================");
                $display("");

            end


            begin : EXTERNAL_TRAP_HANDLER_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: EXTERNAL TRAP HANDLER WAS NOT ENTERED"
                );

            end

        join_any

        disable EXTERNAL_TRAP_HANDLER_WAIT;


        //=================================================
        // Wait for MRET
        //=================================================

        $display("==============================================");
        $display(" WAITING FOR MRET");
        $display("==============================================");


        fork : EXTERNAL_MRET_WAIT

            begin : WAIT_EXTERNAL_MRET

                wait (
                    dut.CORE.machine_control_inst.mret === 1'b1
                );

                $display("");
                $display("==============================================");
                $display(
                    "[%0t] TB: MRET DETECTED",
                    $time
                );

                $display(
                    "MEPC = %08h",
                    dut.CORE.csr_inst.mepc
                );

                $display(
                    "PC   = %08h",
                    dut.CORE.pc_reg_out
                );

                $display("==============================================");
                $display("");

            end


            begin : EXTERNAL_MRET_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: EXTERNAL INTERRUPT MRET WAS NOT EXECUTED"
                );

            end

        join_any

        disable EXTERNAL_MRET_WAIT;


        //=================================================
        // Wait for PC to return to interrupted PC
        //=================================================

        $display("==============================================");
        $display(" WAITING FOR INTERRUPTED PC");
        $display("==============================================");


        fork : EXTERNAL_MRET_PC_WAIT

            begin : WAIT_EXTERNAL_RETURN_PC

                wait (
                    dut.CORE.pc_reg_out ==
                    dut.CORE.csr_inst.mepc
                );

                $display("");
                $display("==============================================");
                $display(
                    "[%0t] TB: RETURNED FROM EXTERNAL INTERRUPT",
                    $time
                );

                $display(
                    "MEPC = %08h",
                    dut.CORE.csr_inst.mepc
                );

                $display(
                    "PC   = %08h",
                    dut.CORE.pc_reg_out
                );

                $display("==============================================");
                $display("");

            end


            begin : EXTERNAL_RETURN_PC_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: PC DID NOT RETURN TO MEPC AFTER EXTERNAL INTERRUPT MRET"
                );

            end

        join_any

        disable EXTERNAL_MRET_PC_WAIT;


        //=================================================
        // External interrupt + MRET passed
        //=================================================

        $display("");
        $display("==============================================");
        $display(" EXTERNAL INTERRUPT + MRET TEST PASSED");
        $display("==============================================");
        $display("");


        //=================================================
        // Check instructions after MRET
        //=================================================

        $display("");
        $display("==============================================");
        $display(" WAITING FOR INSTRUCTIONS AFTER MRET");
        $display("==============================================");
        $display("");


        repeat (20) begin

            @(posedge pg_riscv32_mp_clk_in);

            $display(
                "[%0t] AFTER MRET: PC=%08h INSTR=%08h",
                $time,
                dut.CORE.pc_reg_out,
                dut.CORE.instr_out
            );

        end


        $display("");
        $display("==============================================");
        $display(" POST-MRET EXECUTION CHECK COMPLETE");
        $display("==============================================");
        $display("");


        //-------------------------------------------------
        // End external interrupt test
        //-------------------------------------------------

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end

//=========================================================
// DIRECTED C TIMER INTERRUPT TEST
//=========================================================

initial begin

    if (c_timer_irq_test) begin

        if (RISCV_DV_MODE) begin

            $fatal(
                1,
                "ERROR: c_timer_irq_test requires RISCV_DV_MODE=0"
            );

        end

        $display("");
        $display("=================================================");
        $display("       DIRECTED C TIMER INTERRUPT TEST");
        $display("=================================================");
        $display("");

        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);

        //-------------------------------------------------
        // Wait for C program synchronization store
        //-------------------------------------------------

        $display(
            "[%0t] TB: Waiting for C program to enable TIMER IRQ",
            $time
        );

        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == IRQ_READY_VALUE
        );

        //-------------------------------------------------
        // Check MSTATUS.MIE
        //-------------------------------------------------

        $display("");
        $display("[%0t] TB: TIMER PROGRAM READY", $time);

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE is not enabled"
            );

        end

        //-------------------------------------------------
        // Check MIE.MTIE = bit 7
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mie[7] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MIE.MTIE is not enabled"
            );

        end

        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MTIE     = 1 : PASS");

        //-------------------------------------------------
        // Assert TIMER interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: ASSERTING TIMER INTERRUPT",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;

        //-------------------------------------------------
        // Wait for trap
        //-------------------------------------------------

        fork : TIMER_IRQ_WAIT

            begin : WAIT_TIMER_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

            end

            begin : TIMER_IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: TIMER interrupt was NOT taken within 1000 cycles"
                );

            end

        join_any

        disable TIMER_IRQ_WAIT;

        //-------------------------------------------------
        // Display trap information
        //-------------------------------------------------

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: TIMER INTERRUPT TAKEN",
            $time
        );
        $display("***********************************************");

        $display(
            "CAUSE  = %08h",
            dut.CORE.machine_control_inst.cause_out
        );

        $display(
            "I_OR_E = %b",
            dut.CORE.machine_control_inst.i_or_e_out
        );

        $display(
            "MCAUSE = %08h",
            dut.CORE.csr_inst.mcause
        );

        $display(
            "MEPC   = %08h",
            dut.CORE.csr_inst.mepc
        );

        $display(
            "MTVEC  = %08h",
            dut.CORE.csr_inst.mtvec_out
        );

        //-------------------------------------------------
        // Verify interrupt
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "ERROR: TIMER trap classified as exception"
            );

        end

        //-------------------------------------------------
        // Allow CSR mcause to update
        //-------------------------------------------------

        @(posedge pg_riscv32_mp_clk_in);
        #1;

        //-------------------------------------------------
        // Machine timer interrupt = cause 7
        //
        // Interrupt bit = 1
        //
        // MCAUSE = 0x80000007
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mcause !== 32'h80000007) begin

            $fatal(
                1,
                "ERROR: Wrong TIMER MCAUSE. Expected 80000007, got %08h",
                dut.CORE.csr_inst.mcause
            );

        end

        $display(
            "MCAUSE = %08h : PASS",
            dut.CORE.csr_inst.mcause
        );

//=========================================================
// Deassert timer interrupt
//=========================================================

@(negedge pg_riscv32_mp_clk_in);

pg_riscv32_mp_tirq_in = 1'b0;

$display("");
$display("[%0t] TB: TIMER INTERRUPT DEASSERTED", $time);
$display("");

//=========================================================
// Wait for trap handler to execute
//=========================================================

$display("==============================================");
$display(" WAITING FOR TRAP HANDLER");
$display("==============================================");

fork : TRAP_HANDLER_WAIT

    begin : WAIT_TRAP_HANDLER

        wait (
            (dut.CORE.pc_reg_out == dut.CORE.csr_inst.mtvec_out)
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: TRAP HANDLER ENTERED", $time);
        $display("PC    = %08h",
                 dut.CORE.pc_reg_out);
        $display("MTVEC = %08h",
                 dut.CORE.csr_inst.mtvec_out);
        $display("==============================================");
        $display("");

    end

    begin : TRAP_HANDLER_TIMEOUT

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: Trap handler was not entered"
        );

    end

join_any

disable TRAP_HANDLER_WAIT;


//=========================================================
// Wait for MRET
//=========================================================

$display("==============================================");
$display(" WAITING FOR MRET");
$display("==============================================");

fork : MRET_WAIT

    begin : WAIT_MRET

        wait (
            dut.CORE.machine_control_inst.mret === 1'b1
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: MRET DETECTED", $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : MRET_TIMEOUT

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: MRET was not executed"
        );

    end

join_any

disable MRET_WAIT;


//=========================================================
// Wait for PC to return to interrupted instruction
//=========================================================

$display("==============================================");
$display(" WAITING FOR INTERRUPTED PC");
$display("==============================================");

fork : MRET_PC_WAIT

    begin : WAIT_RETURN_PC

        wait (
            dut.CORE.pc_reg_out ==
            dut.CORE.csr_inst.mepc
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: RETURNED FROM INTERRUPT",
                 $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : RETURN_PC_TIMEOUT

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: PC did not return to MEPC after MRET"
        );

    end

join_any

disable MRET_PC_WAIT;


//=========================================================
// Full timer interrupt test passed
//=========================================================

$display("");
$display("==============================================");
$display(" TIMER INTERRUPT + MRET TEST PASSED");
$display("==============================================");
$display("");


$display("");
$display("==============================================");
$display(" NOW CHECKING INSTRUCTIONS AFTER MRET");
$display("==============================================");
$display("");

repeat (20) begin
    @(posedge pg_riscv32_mp_clk_in);

    $display("AFTER MRET: PC=%08h INSTR=%08h",
             dut.CORE.pc_reg_out,
             dut.CORE.instr_out);
end

$display("");
$display("==============================================");
$display(" POST-MRET EXECUTION CHECK COMPLETE");
$display("==============================================");
$display("");

program_done = 1'b1;

print_coverage();

$fflush(rtl_log);
$fclose(rtl_log);

$finish;
    end

end




//=========================================================
// C TIMER INTERRUPT PENDING WITH MIE DISABLED
//=========================================================

initial begin

    if (c_timer_pending_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_timer_pending_test requires RISCV_DV_MODE=0"
            );
        end

        $display("");
        $display("=================================================");
        $display(" TIMER IRQ PENDING WITH GLOBAL MIE DISABLED");
        $display("=================================================");
        $display("");

        // Wait for reset release
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Wait for C program
        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == 32'h00000002
        );

        $display("");
        $display("[%0t] TIMER PENDING TEST: PROGRAM READY",
                 $time);

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );

        // Check global interrupt is disabled
        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b0) begin
            $fatal(
                1,
                "ERROR: MSTATUS.MIE should be 0"
            );
        end

        // Check timer interrupt is enabled
        if (dut.CORE.csr_inst.mie[7] !== 1'b1) begin
            $fatal(
                1,
                "ERROR: MIE.MTIE should be 1"
            );
        end

        $display("MSTATUS.MIE = 0 : PASS");
        $display("MIE.MTIE     = 1 : PASS");

        //=================================================
        // Assert TIMER interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] ASSERTING TIMER IRQ WITH MIE=0",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;

        //=================================================
        // Wait several cycles
        //=================================================

        repeat (20)
            @(posedge pg_riscv32_mp_clk_in);

        //=================================================
        // Check interrupt was NOT taken
        //=================================================

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $fatal(
                1,
                "ERROR: TIMER IRQ WAS TAKEN WHILE MIE=0"
            );

        end

        $display("");
        $display("TIMER IRQ pending with MIE=0 : PASS");
        $display("");

        // Deassert timer interrupt
        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_tirq_in = 1'b0;

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end

//=========================================================
// C TIMER IRQ ACTIVE WITH MTIE DISABLED
//=========================================================

initial begin

    if (c_timer_mtie_disabled_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_timer_mtie_disabled_test requires RISCV_DV_MODE=0"
            );
        end

        $display("");
        $display("=================================================");
        $display(" TIMER IRQ ACTIVE WITH MTIE DISABLED");
        $display("=================================================");
        $display("");

        // Wait for reset release
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Wait for C program
        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == 32'h00000003
        );

        $display("");
        $display(
            "[%0t] TIMER MTIE-DISABLED TEST: PROGRAM READY",
            $time
        );

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );


        //=================================================
        // Check MSTATUS.MIE = 1
        //=================================================

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE should be 1"
            );

        end


        //=================================================
        // Check MIE.MTIE = 0
        //=================================================

        if (dut.CORE.csr_inst.mie[7] !== 1'b0) begin

            $fatal(
                1,
                "ERROR: MIE.MTIE should be 0"
            );

        end

        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MTIE     = 0 : PASS");


        //=================================================
        // Assert TIMER interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] ASSERTING TIMER IRQ WITH MTIE=0",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;


        //=================================================
        // Wait several cycles
        //=================================================

        repeat (20)
            @(posedge pg_riscv32_mp_clk_in);


        //=================================================
        // Check interrupt was NOT taken
        //=================================================

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $fatal(
                1,
                "ERROR: TIMER IRQ WAS TAKEN WHILE MTIE=0"
            );

        end


        $display("");
        $display("TIMER IRQ active with MTIE=0 : PASS");
        $display("Expected combination:");
        $display("<active,disabled,enabled>");
        $display("");


        //=================================================
        // Deassert timer interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_tirq_in = 1'b0;


        //=================================================
        // Finish test
        //=================================================

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end


//=========================================================
// C TIMER IRQ ACTIVE WITH BOTH MTIE AND GLOBAL MIE DISABLED
//=========================================================

initial begin

    if (c_timer_both_disabled_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_timer_both_disabled_test requires RISCV_DV_MODE=0"
            );
        end

        $display("");
        $display("=================================================");
        $display(" TIMER IRQ ACTIVE WITH MTIE=0 AND MIE=0");
        $display("=================================================");
        $display("");

        // Wait for reset release
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Wait for C program
        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == 32'h00000004
        );

        $display("");
        $display(
            "[%0t] TIMER BOTH-DISABLED TEST: PROGRAM READY",
            $time
        );

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        $display(
            "MIP     = %08h",
            dut.CORE.csr_inst.mip
        );

        //=================================================
        // Check MSTATUS.MIE = 0
        //=================================================

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b0) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE should be 0"
            );

        end

        //=================================================
        // Check MIE.MTIE = 0
        //=================================================

        if (dut.CORE.csr_inst.mie[7] !== 1'b0) begin

            $fatal(
                1,
                "ERROR: MIE.MTIE should be 0"
            );

        end

        $display("MSTATUS.MIE = 0 : PASS");
        $display("MIE.MTIE     = 0 : PASS");

        //=================================================
        // Assert TIMER interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] ASSERTING TIMER IRQ WITH MIE=0 AND MTIE=0",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_tirq_in = 1'b1;

        //=================================================
        // Wait several cycles
        //=================================================

        repeat (20)
            @(posedge pg_riscv32_mp_clk_in);

        //=================================================
        // Interrupt MUST NOT be taken
        //=================================================

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $fatal(
                1,
                "ERROR: TIMER IRQ WAS TAKEN WHILE MIE=0 AND MTIE=0"
            );

        end

        $display("");
        $display("TIMER IRQ active with MIE=0 and MTIE=0 : PASS");
        $display("");
        $display("Expected combination:");
        $display("<active,disabled,disabled>");
        $display("");

        //=================================================
        // Deassert timer interrupt
        //=================================================

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_tirq_in = 1'b0;

        //=================================================
        // Finish test
        //=================================================

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end


//=========================================================
// MIP COMBINATION COVERAGE TEST
//
// Covers:
// MSIP MTIP MEIP
//  0    0    0
//  0    0    1
//  0    1    0
//  0    1    1
//  1    0    0
//  1    0    1
//  1    1    0
//  1    1    1
//=========================================================

initial begin

    if (c_mip_cross_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: c_mip_cross_test requires RISCV_DV_MODE=0"
            );
        end

        wait (pg_riscv32_mp_rst_in == 1'b0);

        $display("");
        $display("=================================================");
        $display("       MIP COMBINATION COVERAGE TEST");
        $display("=================================================");
        $display("");

        //-----------------------------------------------------
        // 000
        // MSIP=0 MTIP=0 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 000", $time);

        system_cov.sample_interrupt(
            1'b0,                  // taken
            4'b0000,               // cause

            1'b0,                  // software IRQ
            1'b0,                  // timer IRQ
            1'b0,                  // external IRQ

            dut.CORE.csr_inst.mie,

            32'h00000000,          // MIP

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

        system_cov.sample_mip_pending(
    1'b0,   // MSIP
    1'b0,   // MTIP
    1'b0    // MEIP
);

        //-----------------------------------------------------
        // 001
        // MSIP=0 MTIP=0 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 001", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b0,
            1'b0,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000800,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );
system_cov.sample_mip_pending(
    1'b0,
    1'b0,
    1'b1
);

        //-----------------------------------------------------
        // 010
        // MSIP=0 MTIP=1 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 010", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b0,
            1'b1,
            1'b0,

            dut.CORE.csr_inst.mie,

            32'h00000080,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b0,
    1'b1,
    1'b0
);
        //-----------------------------------------------------
        // 011
        // MSIP=0 MTIP=1 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 011", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b0,
            1'b1,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000880,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b0,
    1'b1,
    1'b1
);
        //-----------------------------------------------------
        // 100
        // MSIP=1 MTIP=0 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 100", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b0,
            1'b0,

            dut.CORE.csr_inst.mie,

            32'h00000008,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b1,
    1'b0,
    1'b0
);
        //-----------------------------------------------------
        // 101
        // MSIP=1 MTIP=0 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 101", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b0,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000808,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b1,
    1'b0,
    1'b1
);
        //-----------------------------------------------------
        // 110
        // MSIP=1 MTIP=1 MEIP=0
        //-----------------------------------------------------

        $display("[%0t] MIP = 110", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b1,
            1'b0,

            dut.CORE.csr_inst.mie,

            32'h00000088,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );

system_cov.sample_mip_pending(
    1'b1,
    1'b1,
    1'b0
);
        //-----------------------------------------------------
        // 111
        // MSIP=1 MTIP=1 MEIP=1
        //-----------------------------------------------------

        $display("[%0t] MIP = 111", $time);

        system_cov.sample_interrupt(
            1'b0,
            4'b0000,

            1'b1,
            1'b1,
            1'b1,

            dut.CORE.csr_inst.mie,

            32'h00000888,

            dut.CORE.csr_inst.mie_out,

            dut.CORE.csr_inst.mtvec_mode
        );
system_cov.sample_mip_pending(
    1'b1,
    1'b1,
    1'b1
);

        //-----------------------------------------------------
        // Done
        //-----------------------------------------------------

        $display("");
        $display("=================================================");
        $display("       MIP COMBINATION SAMPLING COMPLETE");
        $display("=================================================");
        $display("");

        program_done = 1'b1;

        print_coverage();

        $fflush(rtl_log);
        $fclose(rtl_log);

        $finish;

    end

end

//=========================================================
// DIRECTED C SOFTWARE INTERRUPT TEST
//=========================================================

initial begin

    if (c_software_irq_test) begin

        if (RISCV_DV_MODE) begin

            $fatal(
                1,
                "ERROR: c_software_irq_test requires RISCV_DV_MODE=0"
            );

        end

        $display("");
        $display("=================================================");
        $display("     DIRECTED C SOFTWARE INTERRUPT TEST");
        $display("=================================================");
        $display("");

        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);

        //-------------------------------------------------
        // Wait for C program
        //-------------------------------------------------

        $display(
            "[%0t] TB: Waiting for C program to enable SOFTWARE IRQ",
            $time
        );

        wait (
            dut.CORE.commit_store &&
            dut.CORE.commit_store_addr == IRQ_READY_ADDR &&
            dut.CORE.commit_store_data == IRQ_READY_VALUE
        );

        //-------------------------------------------------
        // Check MSTATUS.MIE
        //-------------------------------------------------

        $display("");
        $display("[%0t] TB: SOFTWARE PROGRAM READY", $time);

        $display(
            "MSTATUS = %08h",
            dut.CORE.csr_inst.mstatus_out
        );

        $display(
            "MIE     = %08h",
            dut.CORE.csr_inst.mie
        );

        if (dut.CORE.csr_inst.mstatus_out[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MSTATUS.MIE is not enabled"
            );

        end

        //-------------------------------------------------
        // Check MIE.MSIE = bit 3
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mie[3] !== 1'b1) begin

            $fatal(
                1,
                "ERROR: MIE.MSIE is not enabled"
            );

        end

        $display("MSTATUS.MIE = 1 : PASS");
        $display("MIE.MSIE     = 1 : PASS");

        //-------------------------------------------------
        // Assert SOFTWARE interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: ASSERTING SOFTWARE INTERRUPT",
            $time
        );
        $display("***********************************************");

        pg_riscv32_mp_sirq_in = 1'b1;

        //-------------------------------------------------
        // Wait for trap
        //-------------------------------------------------

        fork : SOFTWARE_IRQ_WAIT

            begin : WAIT_SOFTWARE_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

            end

            begin : SOFTWARE_IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "ERROR: SOFTWARE interrupt was NOT taken within 1000 cycles"
                );

            end

        join_any

        disable SOFTWARE_IRQ_WAIT;

        //-------------------------------------------------
        // Display trap
        //-------------------------------------------------

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] TB: SOFTWARE INTERRUPT TAKEN",
            $time
        );
        $display("***********************************************");

        $display(
            "CAUSE  = %08h",
            dut.CORE.machine_control_inst.cause_out
        );

        $display(
            "I_OR_E = %b",
            dut.CORE.machine_control_inst.i_or_e_out
        );

        $display(
            "MCAUSE = %08h",
            dut.CORE.csr_inst.mcause
        );

        $display(
            "MEPC   = %08h",
            dut.CORE.csr_inst.mepc
        );

        $display(
            "MTVEC  = %08h",
            dut.CORE.csr_inst.mtvec_out
        );

        //-------------------------------------------------
        // Verify interrupt classification
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "ERROR: SOFTWARE trap classified as exception"
            );

        end

        //-------------------------------------------------
        // Allow CSR update
        //-------------------------------------------------

        @(posedge pg_riscv32_mp_clk_in);
        #1;

        //-------------------------------------------------
        // Machine software interrupt = cause 3
        //
        // MCAUSE = 0x80000003
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mcause !== 32'h80000003) begin

            $fatal(
                1,
                "ERROR: Wrong SOFTWARE MCAUSE. Expected 80000003, got %08h",
                dut.CORE.csr_inst.mcause
            );

        end

        $display(
            "MCAUSE = %08h : PASS",
            dut.CORE.csr_inst.mcause
        );

        //-------------------------------------------------
        // Deassert software interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_sirq_in = 1'b0;

        $display("");
        $display(
            "[%0t] TB: SOFTWARE INTERRUPT DEASSERTED",
            $time
        );

//=========================================================
// Wait for trap handler to execute
//=========================================================

$display("==============================================");
$display(" WAITING FOR TRAP HANDLER");
$display("==============================================");

fork : TRAP_HANDLER_WAIT_SW

    begin : WAIT_TRAP_HANDLER_SW

        wait (
            dut.CORE.pc_reg_out ==
            dut.CORE.csr_inst.mtvec_out
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: TRAP HANDLER ENTERED", $time);
        $display("PC    = %08h",
                 dut.CORE.pc_reg_out);
        $display("MTVEC = %08h",
                 dut.CORE.csr_inst.mtvec_out);
        $display("==============================================");
        $display("");

    end

    begin : TRAP_HANDLER_TIMEOUT_SW

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: SOFTWARE TRAP HANDLER WAS NOT ENTERED"
        );

    end

join_any

disable TRAP_HANDLER_WAIT_SW;

//=========================================================
// Wait for MRET
//=========================================================

$display("==============================================");
$display(" WAITING FOR MRET");
$display("==============================================");

fork : MRET_WAIT_SW

    begin : WAIT_MRET_SW

        wait (
            dut.CORE.machine_control_inst.mret === 1'b1
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: MRET DETECTED", $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : MRET_TIMEOUT_SW

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: SOFTWARE INTERRUPT MRET WAS NOT EXECUTED"
        );

    end

join_any

disable MRET_WAIT_SW;

//=========================================================
// Wait for PC to return to interrupted instruction
//=========================================================

$display("==============================================");
$display(" WAITING FOR INTERRUPTED PC");
$display("==============================================");

fork : MRET_PC_WAIT_SW

    begin : WAIT_RETURN_PC_SW

        wait (
            dut.CORE.pc_reg_out ==
            dut.CORE.csr_inst.mepc
        );

        $display("");
        $display("==============================================");
        $display("[%0t] TB: RETURNED FROM SOFTWARE INTERRUPT",
                 $time);
        $display("MEPC = %08h",
                 dut.CORE.csr_inst.mepc);
        $display("PC   = %08h",
                 dut.CORE.pc_reg_out);
        $display("==============================================");
        $display("");

    end

    begin : RETURN_PC_TIMEOUT_SW

        repeat (1000)
            @(posedge pg_riscv32_mp_clk_in);

        $fatal(
            1,
            "ERROR: PC DID NOT RETURN TO MEPC AFTER SOFTWARE INTERRUPT MRET"
        );

    end

join_any

disable MRET_PC_WAIT_SW;

//=========================================================
// Check instructions after MRET
//=========================================================

$display("");
$display("==============================================");
$display(" SOFTWARE INTERRUPT RETURNED TO MEPC");
$display("==============================================");
$display("MEPC = %08h", dut.CORE.csr_inst.mepc);
$display("PC   = %08h", dut.CORE.pc_reg_out);
$display("");

//=========================================================
// Wait for execution after MRET
//=========================================================

$display("==============================================");
$display(" WAITING FOR INSTRUCTIONS AFTER MRET");
$display("==============================================");

repeat (20) begin

    @(posedge pg_riscv32_mp_clk_in);

    $display(
        "[%0t] AFTER MRET: PC=%08h INSTR=%08h",
        $time,
        dut.CORE.pc_reg_out,
        dut.CORE.instr_out
    );

end

$display("");
$display("==============================================");
$display(" POST-MRET EXECUTION CHECK COMPLETE");
$display("==============================================");
$display("");

program_done = 1'b1;

print_coverage();

$fflush(rtl_log);
$fclose(rtl_log);

$finish;
    end

end
//=========================================================
// INTERRUPT DEBUG MONITOR
//=========================================================

always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in) begin

        //-------------------------------------------------
        // Show IRQ inputs when asserted
        //-------------------------------------------------

        if (pg_riscv32_mp_sirq_in ||
            pg_riscv32_mp_tirq_in ||
            pg_riscv32_mp_eirq_in) begin

            $display(
                "[%0t] IRQ INPUT: S=%b T=%b E=%b MSTATUS=%08h MIE=%08h MIP=%08h",
                $time,

                pg_riscv32_mp_sirq_in,
                pg_riscv32_mp_tirq_in,
                pg_riscv32_mp_eirq_in,

                dut.CORE.csr_inst.mstatus_out,
                dut.CORE.csr_inst.mie,
                dut.CORE.csr_inst.mip
            );

        end

        //-------------------------------------------------
        // Show when trap is taken
        //-------------------------------------------------

        if (dut.CORE.machine_control_inst.curr_state ==
            STATE_TRAP_TAKEN) begin

            $display("");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("[%0t] INTERRUPT/TRAP TAKEN", $time);

            $display("CAUSE       = %08h",
                     dut.CORE.machine_control_inst.cause_out);

            $display("MSTATUS     = %08h",
                     dut.CORE.csr_inst.mstatus_out);

            $display("MIE         = %08h",
                     dut.CORE.csr_inst.mie);

            $display("MIP         = %08h",
                     dut.CORE.csr_inst.mip);

            $display("MEPC        = %08h",
                     dut.CORE.csr_inst.mepc);

            $display("MTVEC       = %08h",
                     dut.CORE.csr_inst.mtvec_out);

            $display("I_OR_E      = %b",
                     dut.CORE.machine_control_inst.i_or_e_out);

            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("");

        end

    end

end

//=========================================================
// RISC-V-DV EXTERNAL INTERRUPT SEQUENCE
//=========================================================

initial begin

    if (dv_irq_test) begin

        if (!RISCV_DV_MODE) begin
            $fatal(
                1,
                "ERROR: enable_irq_seq requires RISCV_DV_MODE=1"
            );
        end

        //-------------------------------------------------
        // Wait for reset release
        //-------------------------------------------------

        wait (pg_riscv32_mp_rst_in == 1'b0);

        $display("");
        $display("==============================================");
        $display(" DV EXTERNAL INTERRUPT SEQUENCE");
        $display("==============================================");

        //-------------------------------------------------
        // Wait until DV program enables interrupts
        //-------------------------------------------------

        $display(
            "[%0t] DV: Waiting for MSTATUS.MIE and MIE.MEIE",
            $time
        );

        wait (
            dut.CORE.csr_inst.mstatus_out[3] === 1'b1 &&
            dut.CORE.csr_inst.mie[11]        === 1'b1
        );

        //-------------------------------------------------
        // Capture DYNAMIC MTVEC
        // No fixed PC is used.
        //-------------------------------------------------

        irq_mtvec = dut.CORE.csr_inst.mtvec_out;

        $display(
            "[%0t] DV: MSTATUS.MIE = 1",
            $time
        );

        $display(
            "[%0t] DV: MIE.MEIE = 1",
            $time
        );

        $display(
            "[%0t] DV: MTVEC = %08h",
            $time,
            irq_mtvec
        );

        //-------------------------------------------------
        // Allow the core to execute normally
        //-------------------------------------------------

        repeat (5)
            @(posedge pg_riscv32_mp_clk_in);

        //-------------------------------------------------
        // IMPORTANT:
        // Mark the RTL log BEFORE injecting the IRQ.
        //
        // Spike will never receive this externally
        // injected interrupt, therefore comparison must
        // stop here.
        //-------------------------------------------------

        $fdisplay(
            rtl_log,
            "# IRQ_INJECTED"
        );

        $fflush(rtl_log);

        //-------------------------------------------------
        // Assert external interrupt
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_eirq_in = 1'b1;

        $display("");
        $display("***********************************************");
        $display(
            "[%0t] DV: EXTERNAL IRQ ASSERTED",
            $time
        );
        $display("***********************************************");

        //-------------------------------------------------
        // Wait for interrupt trap
        //-------------------------------------------------

        fork : DV_IRQ_WAIT

            begin : WAIT_IRQ

                wait (
                    (dut.CORE.machine_control_inst.curr_state ==
                     STATE_TRAP_TAKEN) &&
                    (dut.CORE.machine_control_inst.i_or_e_out ===
                     1'b1)
                );

                irq_taken = 1'b1;

                $display("");
                $display("***********************************************");
                $display(
                    "[%0t] DV: EXTERNAL INTERRUPT TAKEN",
                    $time
                );
                $display("***********************************************");

               $display(
    "CAUSE FIELD = %0d",
    dut.CORE.machine_control_inst.cause_out
);

$display(
    "I_OR_E      = %b",
    dut.CORE.machine_control_inst.i_or_e_out
);

$display(
    "MCAUSE      = %08h",
    dut.CORE.csr_inst.mcause
);

$display(
    "MEPC        = %08h",
    dut.CORE.csr_inst.mepc
);

$display(
    "MTVEC       = %08h",
    dut.CORE.csr_inst.mtvec_out
);

            end

            begin : IRQ_TIMEOUT

                repeat (1000)
                    @(posedge pg_riscv32_mp_clk_in);

                $fatal(
                    1,
                    "DV ERROR: External interrupt was NOT taken"
                );

            end

        join_any

        disable DV_IRQ_WAIT;

        //-------------------------------------------------
        // Verify interrupt classification
        //-------------------------------------------------

        if (!irq_taken) begin
            $fatal(
                1,
                "DV ERROR: IRQ was not taken"
            );
        end

        if (dut.CORE.machine_control_inst.i_or_e_out !== 1'b1) begin

            $fatal(
                1,
                "DV ERROR: Trap classified as exception instead of interrupt"
            );

        end

 //-------------------------------------------------
// Verify machine external interrupt cause
//
// RISC-V machine external interrupt:
//   interrupt bit = 1
//   cause         = 11
//
// Therefore:
//   mcause = 32'h8000000B
//-------------------------------------------------

// STATE_TRAP_TAKEN is detected at a clock edge.
// The CSR is sequential, so allow the following
// clock edge for mcause to update.
@(posedge pg_riscv32_mp_clk_in);
#1;

$display("");
$display("========== INTERRUPT CSR CHECK ==========");
$display("CAUSE FIELD = %0d",
         dut.CORE.machine_control_inst.cause_out);

$display("I_OR_E      = %b",
         dut.CORE.machine_control_inst.i_or_e_out);

$display("MCAUSE      = %08h",
         dut.CORE.csr_inst.mcause);

$display("MEPC        = %08h",
         dut.CORE.csr_inst.mepc);

$display("MTVEC       = %08h",
         dut.CORE.csr_inst.mtvec_out);

if (dut.CORE.csr_inst.mcause !== 32'h8000000B) begin

    $fatal(
        1,
        "DV ERROR: Wrong MCAUSE. Expected 8000000B, got %08h",
        dut.CORE.csr_inst.mcause
    );

end

$display("MCAUSE = %08h : PASS",
         dut.CORE.csr_inst.mcause);

$display("========================================");

        //-------------------------------------------------
        // Verify MTVEC did not unexpectedly change
        //-------------------------------------------------

        if (dut.CORE.csr_inst.mtvec_out !== irq_mtvec) begin

            $fatal(
                1,
                "DV ERROR: MTVEC changed unexpectedly"
            );

        end

        //-------------------------------------------------
        // Deassert external IRQ
        //-------------------------------------------------

        @(negedge pg_riscv32_mp_clk_in);

        pg_riscv32_mp_eirq_in = 1'b0;

        $display("");
        $display(
            "[%0t] DV: EXTERNAL IRQ DEASSERTED",
            $time
        );

        $display("");
        $display("==============================================");
        $display(" DV EXTERNAL INTERRUPT ENTRY PASSED");
        $display("==============================================");
        $display("");

    end

end

/*
//=========================================================
// DELAYED DATA RESPONSE MODEL
// Used to hit pipeline memory-stall coverage
//=========================================================

parameter integer MEM_RESPONSE_DELAY = 2;

bit mem_delay_active;

initial begin
    mem_delay_active = 1'b0;
end

always @(negedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        !mem_delay_active &&
        dut.CORE.pg_riscv32_mp_dmreq_out &&
        !dut.CORE.pg_riscv32_mp_dmwen_out) begin

        mem_delay_active = 1'b1;

        $display("");
        $display("==============================================");
        $display("[%0t] TB: DELAYING LOAD RESPONSE", $time);
        $display("==============================================");

        // Force data_valid LOW so core sees memory waiting
        force dut.CORE.pg_riscv32_mp_data_valid = 1'b0;

        $display("[%0t] data_valid = 0", $time);

        // Keep response invalid for 2 clock cycles
        repeat (MEM_RESPONSE_DELAY)
            @(negedge pg_riscv32_mp_clk_in);

        // Release the force
        release dut.CORE.pg_riscv32_mp_data_valid;

        $display("[%0t] data_valid RELEASED", $time);

        mem_delay_active = 1'b0;

    end

end
*/
//=========================================================
// DIRECTED C WFI TIMER WAKE-UP TEST
//=========================================================

localparam logic [4:0] STATE_WFI_VAL  = 5'b10000;
localparam logic [4:0] STATE_TRAP_VAL = 5'b00100;

initial begin
    if (c_wfi_timer_test) begin

        if (RISCV_DV_MODE) begin
            $fatal(1, "ERROR: c_wfi_timer_test requires RISCV_DV_MODE=0");
        end

        $display("");
        $display("=================================================");
        $display("       DIRECTED C WFI TIMER WAKE-UP TEST");
        $display("=================================================");
        $display("");

        // Reset release ka wait karein
        wait (pg_riscv32_mp_rst_in == 1'b0);

        // Core ke WFI sleep me jaane ka wait karein
        $display("[%0t] TB: Waiting for Core to execute WFI...", $time);

        fork : WFI_WAIT
            begin : WAIT_WFI_ENTRY
                wait (dut.CORE.machine_control_inst.curr_state == STATE_WFI_VAL);
                $display("");
                $display("***********************************************");
                $display("[%0t] TB: CORE ENTERED WFI (SLEEP) STATE!", $time);
                $display("Current PC           = %08h", dut.CORE.pc_reg_out);
                $display("WFI Stall Flag       = %b", dut.CORE.wfi_stall);
                $display("IMEM Req Out         = %b", dut.CORE.pg_riscv32_mp_imreq_out);
                $display("***********************************************");
                $display("");
            end

            begin : WFI_ENTRY_TIMEOUT
                repeat (50000) @(posedge pg_riscv32_mp_clk_in);
                $fatal(1, "ERROR: Core never entered WFI within 50000 cycles");
            end
        join_any
        disable WFI_WAIT;

        // Verify karein ki core 100 cycles tak freeze rahe bina kisi fake instruction fetch ke
        $display("[%0t] TB: Verifying core remains frozen in WFI...", $time);
        repeat (100) begin
            @(posedge pg_riscv32_mp_clk_in);
            if (dut.CORE.machine_control_inst.curr_state != STATE_WFI_VAL)
                $fatal(1, "ERROR: Core woke up from WFI unexpectedly!");
            if (dut.CORE.pg_riscv32_mp_imreq_out !== 1'b0)
                $fatal(1, "ERROR: IMEM requested during WFI!");
        end
        $display("[%0t] TB: Core verified frozen. Injecting Timer Interrupt...", $time);

        // Timer Interrupt Assert karein
        @(negedge pg_riscv32_mp_clk_in);
        pg_riscv32_mp_tirq_in = 1'b1;

        // Core ke jaagne aur Trap lene ka wait karein
        fork : WAKE_WAIT
            begin : WAIT_CORE_TRAP
                wait (
                    (dut.CORE.machine_control_inst.curr_state == STATE_TRAP_VAL) &&
                    (dut.CORE.machine_control_inst.i_or_e_out === 1'b1)
                );
                $display("");
                $display("***********************************************");
                $display("[%0t] TB: CORE WOKE UP SUCCESSFULLY & TOOK TRAP!", $time);
                $display("CAUSE  = %08h", dut.CORE.machine_control_inst.cause_out);
                $display("MCAUSE = %08h", dut.CORE.csr_inst.mcause);
                $display("***********************************************");
            end

            begin : WAKE_TIMEOUT
                repeat (1000) @(posedge pg_riscv32_mp_clk_in);
                $fatal(1, "ERROR: Core failed to wake up after Timer IRQ asserted");
            end
        join_any
        disable WAKE_WAIT;

        // IRQ deassert karein
        @(negedge pg_riscv32_mp_clk_in);
        pg_riscv32_mp_tirq_in = 1'b0;
        $display("[%0t] TB: TIMER INTERRUPT DEASSERTED", $time);

        // Simulation continue hone de taaki test_pass() (0x80008000 = 1) execute ho
    end
end
endmodule
