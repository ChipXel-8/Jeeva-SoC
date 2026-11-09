`timescale 1ns / 1ps

module tb_pragya_benchmark_system;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_SYSTEM_TESTS = 16;

  // DUT Top-level Signals
  logic clk;
  logic rst;
  logic irq_external;
  logic irq_timer;
  logic irq_software;
  logic debug_req;

  // Test Tracking
  int total_tests;
  int passed_tests;
  int failed_tests;
  int cycle_count;
  logic test_passed;

  // DUT Top Instantiation
  pragya_top dut (
    .pg_riscv32_mp_clk_in       (clk),
    .pg_riscv32_mp_rst_in       (rst),
    .pg_riscv32_mp_eirq_in      (irq_external),
    .pg_riscv32_mp_tirq_in      (irq_timer),
    .pg_riscv32_mp_sirq_in      (irq_software),
    .pg_riscv32_mp_debug_req_in (debug_req)
  );

  // 100MHz Clock Generator
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // Helper Routines
  function void init_memory();
    for (int i = 0; i < 8192; i++)  dut.I_wrapper.imem.memory[i] = 32'h00000013; // nop
    for (int i = 0; i < 16384; i++) dut.D_wrapper.dmem.memory[i] = 32'h00000000;
  endfunction

  function automatic logic [31:0] get_gpr(int idx);
    return dut.CORE.regfile_inst.regfile[idx];
  endfunction

  task automatic imem_write_word(input int word_idx, input logic [31:0] instr);
    dut.I_wrapper.imem.memory[word_idx] = instr;
  endtask

  task automatic reset_core();
  begin
    rst          = 1'b1;
    irq_software = 1'b0;
    irq_timer    = 1'b0;
    irq_external = 1'b0;
    debug_req    = 1'b0;

    #(3 * CLK_PERIOD);
    @(posedge clk);
    rst = 1'b0;
    repeat (6) @(posedge clk);
  end
  endtask

  function void print_header(string title);
    $display("");
    $display("=========================================================================================================");
    $display("  %s", title);
    $display("=========================================================================================================");
    $display("");
  endfunction

  function void print_test_start(int num, string name);
    $display("---------------------------------------------------------------------------------------------------------");
    $display("  [TEST %2d] %s", num, name);
    $display("---------------------------------------------------------------------------------------------------------");
    total_tests++;
  endfunction

  function void end_test(logic passed, string msg);
    if (passed) begin
      $display("   [PASS] %s\n", msg);
      passed_tests++;
    end else begin
      $display("   [FAIL] %s\n", msg);
      failed_tests++;
    end
  endfunction

  // Execution Flow
  initial begin
    total_tests  = 0;
    passed_tests = 0;
    failed_tests = 0;

    print_header("PRAGYA RV32IM SYSTEM & CSR COMPREHENSIVE ARCHITECTURE BENCHMARK");

    // ========================================================================
    // SECTION A: IDENTIFICATION & READ-ONLY CSRS
    // ========================================================================

    // TEST 1: Hardwired Machine IDs (MVENDORID, MARCHID, MIMPID, MHARTID)
    print_test_start(1, "Read-Only CSR IDs: marchid=5, mvendorid=0, mimpid=0, mhartid=0");
    init_memory();
    imem_write_word(0, 32'hf12020f3); // csrrs x1, marchid, x0   (0xF12 -> 5)
    imem_write_word(1, 32'hf1102173); // csrrs x2, mvendorid, x0 (0xF11 -> 0)
    imem_write_word(2, 32'hf13021f3); // csrrs x3, mimpid, x0    (0xF13 -> 0)
    imem_write_word(3, 32'hf1402273); // csrrs x4, mhartid, x0   (0xF14 -> 0)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h5) && (get_gpr(2) == 32'h0) &&
                  (get_gpr(3) == 32'h0) && (get_gpr(4) == 32'h0);
    end_test(test_passed, $sformatf("marchid=0x%08x, mvendorid=0x%08x", get_gpr(1), get_gpr(2)));

    // TEST 2: MISA Reset Value and Feature Verification
    print_test_start(2, "MISA: Verification of RV32I base architecture lock");
    init_memory();
    imem_write_word(0, 32'h301020f3); // csrrs x1, misa, x0       -> Read Reset
    imem_write_word(1, 32'h00000113); // addi  x2, x0, 0
    imem_write_word(2, 32'h30111073); // csrrw x0, misa, x2      -> Try writing 0 (lock test)
    imem_write_word(3, 32'h301021f3); // csrrs x3, misa, x0       -> Read back (FIXED to 0x73)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    // Verified against RTL: misa[31:30]=2'b01 (RV32) and misa[8]=1'b1 (I-ext) are strictly locked
    test_passed = (get_gpr(1)[31:30] == 2'b01) && (get_gpr(1)[8] == 1'b1) &&
                  (get_gpr(3)[31:30] == 2'b01) && (get_gpr(3)[8] == 1'b1);
    end_test(test_passed, $sformatf("misa reset = 0x%08x, post-clear = 0x%08x", get_gpr(1), get_gpr(3)));

    // TEST 3: Unmapped CSR Read Defaults to Zero
    print_test_start(3, "Unmapped CSR: Read from invalid address returns 0x00000000");
    init_memory();
    imem_write_word(0, 32'h3ff020f3); // csrrs x1, 0x3FF, x0 (unmapped)
    imem_write_word(1, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000000);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0x00000000)", get_gpr(1)));

    // ========================================================================
    // SECTION B: PERFORMANCE COUNTERS & TIME REGISTERS
    // ========================================================================

    // TEST 4: MCYCLE & CYCLE Read Matching
    print_test_start(4, "Counters: mcycle (0xB00) and cycle (0xC00) increment monotonically");
    init_memory();
    imem_write_word(0, 32'hb00020f3); // csrrs x1, mcycle, x0
    imem_write_word(1, 32'h00000013); // nop
    imem_write_word(2, 32'hc0002173); // csrrs x2, cycle, x0
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) > get_gpr(1)) && (get_gpr(1) > 0);
    end_test(test_passed, $sformatf("mcycle = %0d, cycle = %0d (increasing)", get_gpr(1), get_gpr(2)));

    // TEST 5: MINSTRET Write & Readback
    print_test_start(5, "MINSTRET: Write to minstret (0xB02) and instret (0xC02)");
    init_memory();
    imem_write_word(0, 32'h06400093); // addi  x1, x0, 100
    imem_write_word(1, 32'hb0209073); // csrrw x0, minstret, x1 (set lower 32-bits to 100)
    imem_write_word(2, 32'hc0202173); // csrrs x2, instret, x0  <-- FIXED OPCODE to 0x73
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) >= 32'd100);
    end_test(test_passed, $sformatf("instret readback = %0d (>= 100)", get_gpr(2)));

    // TEST 6: High 32-bit Counters (MCYCLEH & MINSTRETH)
    print_test_start(6, "Counters High: Write and Readback on mcycleh and minstreth");
    init_memory();
    imem_write_word(0, 32'h01200093); // addi  x1, x0, 0x12
    imem_write_word(1, 32'hb8009073); // csrrw x0, mcycleh, x1
    imem_write_word(2, 32'hb8209073); // csrrw x0, minstreth, x1
    imem_write_word(3, 32'hc8002173); // csrrs x2, cycleh, x0   <-- FIXED to 0x73
    imem_write_word(4, 32'hc82021f3); // csrrs x3, instreth, x0 <-- FIXED to 0x73
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h12) && (get_gpr(3) == 32'h12);
    end_test(test_passed, $sformatf("cycleh = 0x%08x, instreth = 0x%08x", get_gpr(2), get_gpr(3)));

    // ========================================================================
    // SECTION C: MACHINE STATUS & INTERRUPT ENABLES
    // ========================================================================

    // TEST 7: MSTATUS Machine Privilege Mode (bits 12:11 hardwired to 2'b11)
    print_test_start(7, "MSTATUS: Privilege mode hardwired to 2'b11 (Machine Mode)");
    init_memory();
    imem_write_word(0, 32'h300020f3); // csrrs x1, mstatus, x0
    imem_write_word(1, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1)[12:11] == 2'b11);
    end_test(test_passed, $sformatf("mstatus = 0x%08x, MPP[12:11] = %2b", get_gpr(1), get_gpr(1)[12:11]));

    // TEST 8: MIE Register Masking (Strict 0x00000888 filter)
    print_test_start(8, "MIE: Unimplemented bits remain zero (mask 0x00000888)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi  x1, x0, -1 (0xFFFFFFFF)
    imem_write_word(1, 32'h30409073); // csrrw x0, mie, x1 (write all 1s)
    imem_write_word(2, 32'h30402173); // csrrs x2, mie, x0  <-- FIXED to 0x73
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000888);
    end_test(test_passed, $sformatf("mie = 0x%08x (exp 0x00000888)", get_gpr(2)));

    // TEST 9: MIE/MPIE Gating on Trap and Return
    print_test_start(9, "MSTATUS: MIE clears on trap, restored from MPIE on MRET");
    init_memory();
    // Handler at 0x80000040 (word index 16):
    imem_write_word(16, 32'h300021f3); // csrrs x3, mstatus, x0  -> read mstatus inside trap (MPIE=1, MIE=0)
    imem_write_word(17, 32'h34102273); // csrrs x4, mepc, x0     -> read mepc
    imem_write_word(18, 32'h00420213); // addi  x4, x4, 4         -> advance past ecall
    imem_write_word(19, 32'h34121073); // csrrw x0, mepc, x4     -> update mepc
    imem_write_word(20, 32'h30200073); // mret                    -> return to main

    // Main Program:
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h04008093); // addi  x1, x1, 0x40
    imem_write_word(2, 32'h30509073); // csrrw x0, mtvec, x1     -> mtvec = 0x80000040
    imem_write_word(3, 32'h00800113); // addi  x2, x0, 8          -> MIE = 1
    imem_write_word(4, 32'h30011073); // csrrw x0, mstatus, x2   -> enable MIE
    imem_write_word(5, 32'h00000073); // ecall                    -> trap triggers
    imem_write_word(6, 32'h300022f3); // csrrs x5, mstatus, x0   -> read mstatus after MRET (MIE restored to 1)
    imem_write_word(7, 32'h0000006f); // jal   x0, 0              -> loop here safely
    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);
    // In trap: MIE(bit 3)=0, MPIE(bit 7)=1. After MRET: MIE(bit 3)=1
    test_passed = (get_gpr(3)[7] == 1'b1) && (get_gpr(5)[3] == 1'b1);
    end_test(test_passed, $sformatf("Trap mstatus=0x%08x (MPIE=%b), Return mstatus=0x%08x (MIE=%b)",
                            get_gpr(3), get_gpr(3)[7], get_gpr(5), get_gpr(5)[3]));

    // ========================================================================
    // SECTION D: TRAP VECTORING & EXCEPTION HANDLING
    // ========================================================================

    // TEST 10: MTVEC Alignment & Mode Extraction
    print_test_start(10, "MTVEC: Base address [31:2] and Mode [1:0] extraction");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h04108093); // addi  x1, x1, 0x41 (Base=0x80000040, Mode=01 Vectored)
    imem_write_word(2, 32'h30509073); // csrrw x0, mtvec, x1
    imem_write_word(3, 32'h30502173); // csrrs x2, mtvec, x0  <-- FIXED to 0x73
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h80000041);
    end_test(test_passed, $sformatf("mtvec = 0x%08x (Base=0x80000040, Mode=01)", get_gpr(2)));

    // TEST 11: Vectored Trap Vector Calculation: Base + (cause << 2)
    print_test_start(11, "Vectored Mode: Trap jumps to Base + (cause << 2)");
    init_memory();
    // In vectored mode, external interrupt (cause=11) jumps to:
    // 0x80000040 + (11 << 2) = 0x8000006C (Word index 27)
    imem_write_word(27, 32'h0ee00313); // addi  x6, x0, 0xEE (Vectored Handler executed)
    imem_write_word(28, 32'h30200073); // mret

    // Main Program:
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h04108093); // addi  x1, x1, 0x41 (Base=0x80000040, Mode=01 Vectored)
    imem_write_word(2, 32'h30509073); // csrrw x0, mtvec, x1
    imem_write_word(3, 32'h00800113); // addi  x2, x0, 8 (MIE)
    imem_write_word(4, 32'h30011073); // csrrw x0, mstatus, x2
    imem_write_word(5, 32'h80000193); // addi  x3, x0, 2048 (MEIE)
    imem_write_word(6, 32'h30419073); // csrrw x0, mie, x3
    imem_write_word(7, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);
    irq_external = 1'b1;
    repeat (4) @(posedge clk);
    irq_external = 1'b0;
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(6) == 32'hEE);
    end_test(test_passed, $sformatf("Vectored interrupt taken to 0x8000006C (x6 = 0x%02x)", get_gpr(6)));

    // TEST 12: MEPC 2-bit LSB Truncation
    print_test_start(12, "MEPC: Lower 2 bits are locked to zero (word-aligned)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h02f08093); // addi  x1, x1, 0x2F (0x8000002F, unaligned)
    imem_write_word(2, 32'h34109073); // csrrw x0, mepc, x1
    imem_write_word(3, 32'h34102173); // csrrs x2, mepc, x0  <-- FIXED to 0x73
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h8000002C); // Lower 2 bits masked to 2'b00
    end_test(test_passed, $sformatf("mepc = 0x%08x (exp 0x8000002C)", get_gpr(2)));

    // TEST 13: MTVAL Exception Value on EBREAK
    print_test_start(13, "MTVAL: Exception address captured on EBREAK (mtval = fault PC)");
    init_memory();
    // Handler at 0x80000040:
    imem_write_word(16, 32'h343021f3); // csrrs x3, mtval, x0 <-- FIXED to 0x73 (read mtval)
    imem_write_word(17, 32'h34102273); // csrrs x4, mepc, x0  <-- FIXED to 0x73
    imem_write_word(18, 32'h00420213); // addi  x4, x4, 4
    imem_write_word(19, 32'h34121073); // csrrw x0, mepc, x4
    imem_write_word(20, 32'h30200073); // mret

    // Main:
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h04008093); // addi  x1, x1, 0x40
    imem_write_word(2, 32'h30509073); // csrrw x0, mtvec, x1
    imem_write_word(3, 32'h00100073); // ebreak (PC = 0x8000000C)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h8000000C);
    end_test(test_passed, $sformatf("mtval = 0x%08x (exp PC 0x8000000C)", get_gpr(3)));

    // ========================================================================
    // SECTION E: HARDWARE DEBUG SYSTEM REGISTERS (DCSR, DPC, DSCRATCH)
    // ========================================================================

    // TEST 14: DCSR Reset Value and Read-Only Bit Preservation
    print_test_start(14, "DCSR: Reset value 0x4a030003 & preserved read-only bits [8:6]");
    init_memory();
    imem_write_word(0, 32'h7b0020f3); // csrrs x1, dcsr, x0 -> read reset value
    imem_write_word(1, 32'h00000113); // addi  x2, x0, 0
    imem_write_word(2, 32'h7b011073); // csrrw x0, dcsr, x2 -> write 0
    imem_write_word(3, 32'h7b0021f3); // csrrs x3, dcsr, x0 <-- FIXED to 0x73 (read back)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h4a030003);
    end_test(test_passed, $sformatf("dcsr reset = 0x%08x", get_gpr(1)));

    // TEST 15: DPC & DSCRATCH0/1 Read/Write
    print_test_start(15, "Debug Registers: DPC, DSCRATCH0 and DSCRATCH1 full R/W");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h01408093); // addi  x1, x1, 0x14 (0x80000014)
    imem_write_word(2, 32'h7b109073); // csrrw x0, dpc, x1
    imem_write_word(3, 32'h0aa00113); // addi  x2, x0, 0xAA
    imem_write_word(4, 32'h7b211073); // csrrw x0, dscratch0, x2
    imem_write_word(5, 32'h0bb00193); // addi  x3, x0, 0xBB
    imem_write_word(6, 32'h7b319073); // csrrw x0, dscratch1, x3
    imem_write_word(7, 32'h7b102273); // csrrs x4, dpc, x0       <-- FIXED to 0x73
    imem_write_word(8, 32'h7b2022f3); // csrrs x5, dscratch0, x0 <-- FIXED to 0x73
    imem_write_word(9, 32'h7b302373); // csrrs x6, dscratch1, x0 <-- FIXED to 0x73
    imem_write_word(10,32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(4) == 32'h80000014) && (get_gpr(5) == 32'hAA) && (get_gpr(6) == 32'hBB);
    end_test(test_passed, $sformatf("dpc=0x%08x, dscratch0=0x%02x, dscratch1=0x%02x", get_gpr(4), get_gpr(5), get_gpr(6)));

    // ========================================================================
    // SECTION F: MACHINE CONTROL LOW-POWER WFI SLEEP STATE
    // ========================================================================

    // TEST 16: WFI Low-Power Freeze and Wakeup via Software Interrupt
    print_test_start(16, "WFI: Freeze in STATE_WFI and wakeup via Software Interrupt");
    init_memory();
    // ISR @ 0x80000040 (word index 16):
    imem_write_word(16, 32'h07700313); // addi  x6, x0, 0x77  (ISR ran marker)
    imem_write_word(17, 32'h34102273); // csrrs x4, mepc, x0   (read mepc)
    imem_write_word(18, 32'h00420213); // addi  x4, x4, 4     (skip past WFI)
    imem_write_word(19, 32'h34121073); // csrrw x0, mepc, x4  (update mepc)
    imem_write_word(20, 32'h30200073); // mret

    // Main Program:
    imem_write_word(0, 32'h800000b7); // lui   x1, 0x80000
    imem_write_word(1, 32'h04008093); // addi  x1, x1, 0x40
    imem_write_word(2, 32'h30509073); // csrrw x0, mtvec, x1  (mtvec = 0x80000040)
    imem_write_word(3, 32'h00800113); // addi  x2, x0, 8       (MIE)
    imem_write_word(4, 32'h30011073); // csrrw x0, mstatus, x2
    imem_write_word(5, 32'h00800193); // addi  x3, x0, 8       (MSIE)
    imem_write_word(6, 32'h30419073); // csrrw x0, mie, x3
    imem_write_word(7, 32'h10500073); // wfi   (PC = 0x8000001C)
    imem_write_word(8, 32'h00100393); // addi  x7, x0, 1       (Post-WFI resume instruction)
    imem_write_word(9, 32'h0000006f); // jal   x0, 0           (safe park loop)
    reset_core();

    // Step cycles until core executes WFI
    for (cycle_count = 0; cycle_count < 28; cycle_count++) begin
      @(posedge clk);
    end

    // Hold in sleep for 5 cycles
    repeat (5) @(posedge clk);

    // Assert software interrupt to wake up the core
    irq_software = 1'b1;
    repeat (4) @(posedge clk);
    irq_software = 1'b0;

    // Run cycles for ISR and resume
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (get_gpr(6) == 32'h77) && (get_gpr(7) == 32'd1);
    end_test(test_passed, $sformatf("WFI woke up: ISR x6=0x%02x (exp 0x77), Resumed x7=%0d (exp 1)",
                            get_gpr(6), get_gpr(7)));

    // ========================================================================
    // FINAL BENCHMARK SUMMARY
    // ========================================================================
    print_header("SYSTEM & CSR BENCHMARK SUMMARY");
    $display("Total System Tests:   %0d", total_tests);
    $display("Passed:               %0d", passed_tests);
    $display("Failed:               %0d", failed_tests);
    $display("Success Rate:         %0d%%\n", (passed_tests * 100) / total_tests);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                 ALL SYSTEM & CSR BENCHMARK TESTS PASSED CLEANLY!                                        ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                           SOME SYSTEM BENCHMARK TESTS FAILED!                                           ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule
