`timescale 1ns / 1ps

module tb_pragya_benchmark_ctrl;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_CTRL_TESTS = 22;

  // Top-Level DUT Interface Signals
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

  initial begin
    total_tests  = 0;
    passed_tests = 0;
    failed_tests = 0;

    print_header("PRAGYA RV32I BRANCH & JUMP CONTROL-FLOW BENCHMARK");

    // ========================================================================
    // SECTION A: EQUALITY BRANCHES (BEQ, BNE)
    // ========================================================================

    // TEST 1: BEQ - Taken (Forward +8)
    print_test_start(1, "BEQ: Branch taken (x1 == x2)");
    init_memory();
    imem_write_word(0, 32'h00500093); // addi x1, x0, 5
    imem_write_word(1, 32'h00500113); // addi x2, x0, 5
    imem_write_word(2, 32'h00208463); // beq  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 2: BEQ - Not Taken (Fallthrough)
    print_test_start(2, "BEQ: Branch not taken (x1 != x2)");
    init_memory();
    imem_write_word(0, 32'h00500093); // addi x1, x0, 5
    imem_write_word(1, 32'h00300113); // addi x2, x0, 3
    imem_write_word(2, 32'h00208463); // beq  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (EXECUTED)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d (exp 1)", get_gpr(3)));

    // TEST 3: BNE - Taken
    print_test_start(3, "BNE: Branch taken (x1 != x2)");
    init_memory();
    imem_write_word(0, 32'h00500093); // addi x1, x0, 5
    imem_write_word(1, 32'h00300113); // addi x2, x0, 3
    imem_write_word(2, 32'h00209463); // bne  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 4: BNE - Not Taken
    print_test_start(4, "BNE: Branch not taken (x1 == x2)");
    init_memory();
    imem_write_word(0, 32'h00500093); // addi x1, x0, 5
    imem_write_word(1, 32'h00500113); // addi x2, x0, 5
    imem_write_word(2, 32'h00209463); // bne  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (EXECUTED)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d (exp 1)", get_gpr(3)));

    // ========================================================================
    // SECTION B: SIGNED INEQUALITY (BLT, BGE)
    // ========================================================================

    // TEST 5: BLT - Taken (-1 < 1)
    print_test_start(5, "BLT: Negative vs Positive signed comparison (-1 < 1)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h0020c463); // blt  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 6: BLT - Not Taken (1 < -1 is false)
    print_test_start(6, "BLT: Positive vs Negative signed comparison (1 < -1)");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'hfff00113); // addi x2, x0, -1
    imem_write_word(2, 32'h0020c463); // blt  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (EXECUTED)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d (exp 1)", get_gpr(3)));

    // TEST 7: BGE - Taken (-1 >= -1 is true on equality)
    print_test_start(7, "BGE: Equality check (-1 >= -1)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'hfff00113); // addi x2, x0, -1
    imem_write_word(2, 32'h0020d463); // bge  x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 8: BGE - Signed Upper Boundary (0x7FFFFFFF >= 0x80000000)
    print_test_start(8, "BGE: Max positive >= Min negative (0x7FFFFFFF >= 0x80000000)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0010d093); // srli x1, x1, 1 -> 0x7FFFFFFF
    imem_write_word(2, 32'h80000137); // lui  x2, 0x80000 -> 0x80000000
    imem_write_word(3, 32'h0020d463); // bge  x1, x2, +8
    imem_write_word(4, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(5, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(6, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // ========================================================================
    // SECTION C: UNSIGNED INEQUALITY (BLTU, BGEU)
    // ========================================================================

    // TEST 9: BLTU - Taken (1 < 0xFFFFFFFF unsigned)
    print_test_start(9, "BLTU: 1 < 0xFFFFFFFF unsigned");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'hfff00113); // addi x2, x0, -1 (0xFFFFFFFF)
    imem_write_word(2, 32'h0020e463); // bltu x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 10: BLTU - Not Taken (0xFFFFFFFF < 1 is false)
    print_test_start(10, "BLTU: 0xFFFFFFFF < 1 unsigned is false");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h0020e463); // bltu x1, x2, +8
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1 (EXECUTED)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d (exp 1)", get_gpr(3)));

    // TEST 11: BGEU - Taken (0xFFFFFFFF >= 0 is true)
    print_test_start(11, "BGEU: 0xFFFFFFFF >= 0 unsigned");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0000f463); // bgeu x1, x0, +8
    imem_write_word(2, 32'h00100193); // addi x3, x0, 1 (FLUSHED)
    imem_write_word(3, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // ========================================================================
    // SECTION D: BACKWARD JUMPS & LOOP COUNTER
    // ========================================================================

    // TEST 12: Backward Branch Loop (Count 0 to 5)
    print_test_start(12, "Branch: Backward loop execution (Counting x1 from 0 to 5)");
    init_memory();
    // 0x00: x1 = 0 (counter)
    imem_write_word(0, 32'h00000093); // addi x1, x0, 0
    // 0x04: x2 = 5 (limit)
    imem_write_word(1, 32'h00500113); // addi x2, x0, 5
    // 0x08: LOOP_TOP: x1 = x1 + 1
    imem_write_word(2, 32'h00108093); // addi x1, x1, 1
    // 0x0C: bne x1, x2, -4 (jump back to 0x08) -> offset -4 = 13'h1FFC -> 32'hfe209ee3
    imem_write_word(3, 32'hfe209ee3); // bne  x1, x2, -4
    // 0x10: After loop:
    imem_write_word(4, 32'h00100193); // addi x3, x0, 1 (mark loop done)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 50; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'd5) && (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x1 = %0d (exp 5), loop terminated cleanly", get_gpr(1)));

    // ========================================================================
    // SECTION E: UNCONDITIONAL JUMPS (JAL, JALR)
    // ========================================================================

    // TEST 13: JAL - Jump and Link Return Address Calculation
    print_test_start(13, "JAL: Return address link calculation (PC+4 into rd)");
    init_memory();
    // PC = 0x80000000: jal x1, +8 (return address must be 0x80000004)
    imem_write_word(0, 32'h008000ef); // jal  x1, +8
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1 (FLUSHED)
    imem_write_word(2, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h80000004) && (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0x80000004), x3 = %0d", get_gpr(1), get_gpr(3)));

    // TEST 14: JAL - Discard Return Address (rd = x0)
    print_test_start(14, "JAL: Discard link register with rd = x0");
    init_memory();
    imem_write_word(0, 32'h0080006f); // jal  x0, +8
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1 (FLUSHED)
    imem_write_word(2, 32'h00200193); // addi x3, x0, 2 (TARGET)
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(0) == 32'h00000000) && (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x0 = 0x%08x, x3 = %0d", get_gpr(0), get_gpr(3)));

    // TEST 15: JALR - Jump and Link Register (Base + Offset)
    print_test_start(15, "JALR: Target address calculation (rs1 + offset) & link");
    init_memory();
    // Target PC: 0x80000010 (index 4)
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'h00c08093); // addi x1, x1, 12 (0x8000000C)
    imem_write_word(2, 32'h00408167); // jalr x2, 4(x1)  -> jump to 0x80000010, return addr in x2
    imem_write_word(3, 32'h00100193); // addi x3, x0, 1  (FLUSHED)
    imem_write_word(4, 32'h00200213); // addi x4, x0, 2  (TARGET)
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 24; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h8000000C) && (get_gpr(4) == 32'd2);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x8000000C), x4 = %0d", get_gpr(2), get_gpr(4)));

    // TEST 16: JALR - Subroutine Call and Return Flow
    print_test_start(16, "JAL + JALR: Function call and return linkage");
    init_memory();
    // 0x00: jal x1, +16 (call function at 0x10) -> return addr in x1 is 0x80000004
    imem_write_word(0, 32'h010000ef); // jal  x1, +16
    // 0x04: after return:
    imem_write_word(1, 32'h00128293); // addi x5, x5, 1 (x5 = 43)
    imem_write_word(2, 32'h00000013); // nop
    imem_write_word(3, 32'h00000013); // nop
    // 0x10: function body:
    imem_write_word(4, 32'h02a00293); // addi x5, x0, 42
    imem_write_word(5, 32'h00008067); // jalr x0, 0(x1) (ret)
    imem_write_word(6, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(5) == 32'd43);
    end_test(test_passed, $sformatf("x5 = %0d (exp 43)", get_gpr(5)));

    // ========================================================================
    // FINAL BENCHMARK SUMMARY
    // ========================================================================
    print_header("BRANCH & JUMP BENCHMARK SUMMARY");
    $display("Total Control Tests:  %0d", total_tests);
    $display("Passed:               %0d", passed_tests);
    $display("Failed:               %0d", failed_tests);
    $display("Success Rate:         %0d%%\n", (passed_tests * 100) / total_tests);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                 ALL BRANCH & JUMP BENCHMARK TESTS PASSED CLEANLY!                                       ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                           SOME CONTROL TESTS FAILED!                                                    ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule