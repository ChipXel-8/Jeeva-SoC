`timescale 1ns / 1ps

module tb_pragya_benchmark_mtype;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_MTYPE_TESTS = 30;

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

  // Instantiate DUT Top
  pragya_top dut (
    .pg_riscv32_mp_clk_in       (clk),
    .pg_riscv32_mp_rst_in       (rst),
    .pg_riscv32_mp_eirq_in      (irq_external),
    .pg_riscv32_mp_tirq_in      (irq_timer),
    .pg_riscv32_mp_sirq_in      (irq_software),
    .pg_riscv32_mp_debug_req_in (debug_req)
  );

  // Clock Generation (100MHz)
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

  // Execution Sequence
  initial begin
    total_tests  = 0;
    passed_tests = 0;
    failed_tests = 0;

    print_header("PRAGYA RV32M EXTENSION COMPREHENSIVE CORNER-CASE BENCHMARK");

    // ========================================================================
    // SECTION A: MULTIPLICATION LOWER 32 BITS (MUL)
    // ========================================================================

    // TEST 1: MUL - Small Positive Values (6 * 7 = 42)
    print_test_start(1, "MUL: Small positive integers (6 * 7 = 42)");
    init_memory();
    imem_write_word(0, 32'h00600093); // addi x1, x0, 6
    imem_write_word(1, 32'h00700113); // addi x2, x0, 7
    imem_write_word(2, 32'h022081b3); // mul  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd42);
    end_test(test_passed, $sformatf("x3 = %0d (exp 42)", get_gpr(3)));

    // TEST 2: MUL - Positive * Negative (12 * -5 = -60)
    print_test_start(2, "MUL: Positive * Negative sign handling (12 * -5 = -60)");
    init_memory();
    imem_write_word(0, 32'h00c00093); // addi x1, x0, 12
    imem_write_word(1, 32'hffb00113); // addi x2, x0, -5
    imem_write_word(2, 32'h022081b3); // mul  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = ($signed(get_gpr(3)) == -60);
    end_test(test_passed, $sformatf("x3 = %0d (exp -60)", $signed(get_gpr(3))));

    // TEST 3: MUL - Negative * Negative (-6 * -7 = 42)
    print_test_start(3, "MUL: Negative * Negative (-6 * -7 = 42)");
    init_memory();
    imem_write_word(0, 32'hffa00093); // addi x1, x0, -6
    imem_write_word(1, 32'hff900113); // addi x2, x0, -7
    imem_write_word(2, 32'h022081b3); // mul  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd42);
    end_test(test_passed, $sformatf("x3 = %0d (exp 42)", get_gpr(3)));

    // TEST 4: MUL - Multiply by 0 (x * 0 = 0)
    print_test_start(4, "MUL: Identity multiplication by zero (12345 * 0 = 0)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h02008133); // mul  x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd0);
    end_test(test_passed, $sformatf("x2 = %0d (exp 0)", get_gpr(2)));

    // TEST 5: MUL - Multiply by 1 (x * 1 = x)
    print_test_start(5, "MUL: Identity multiplication by one");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h022081b3); // mul  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h12345000);
    end_test(test_passed, $sformatf("x3 = 0x%08x", get_gpr(3)));

    // TEST 6: MUL - Lower 32-bit Wraparound Overflow
    print_test_start(6, "MUL: Lower 32-bit arithmetic overflow wraparound (0x10000 * 0x10000 = 0)");
    init_memory();
    imem_write_word(0, 32'h000100b7); // lui  x1, 0x00010 (65536)
    imem_write_word(1, 32'h02108133); // mul  x2, x1, x1  (65536 * 65536 = 2^32 = lower 32-bit 0)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x00000000)", get_gpr(2)));

    // ========================================================================
    // SECTION B: HIGH-HALF MULTIPLICATION (MULH, MULHU, MULHSU)
    // ========================================================================

    // TEST 7: MULH - High 32-bit Signed Product (-1 * 2 = -2 -> High: 0xFFFFFFFF)
    print_test_start(7, "MULH: High 32 bits of signed multiply (-1 * 2 = -2)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h00200113); // addi x2, x0, 2
    imem_write_word(2, 32'h022091b3); // mulh x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(3)));

    // TEST 8: MULH - Two Negatives Yield Positive High Product (-1 * -1 = +1 -> High: 0)
    print_test_start(8, "MULH: High 32 bits of -1 * -1 = +1 (High: 0)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h02109133); // mulh x2, x1, x1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x00000000)", get_gpr(2)));

    // TEST 9: MULHU - High 32-bit Unsigned Max Product (0xFFFFFFFF * 0xFFFFFFFF)
    print_test_start(9, "MULHU: Maximum unsigned high-half product (~0 * ~0)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi  x1, x0, -1 (0xFFFFFFFF)
    imem_write_word(1, 32'h0210b133); // mulhu x2, x1, x1 (High is 0xFFFFFFFE)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFE);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xFFFFFFFE)", get_gpr(2)));

    // TEST 10: MULHSU - Signed (-1) * Unsigned (2) -> High: 0xFFFFFFFF
    print_test_start(10, "MULHSU: Signed -1 * Unsigned 2 -> High: 0xFFFFFFFF");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi   x1, x0, -1 (signed -1)
    imem_write_word(1, 32'h00200113); // addi   x2, x0, 2  (unsigned 2)
    imem_write_word(2, 32'h0220a1b3); // mulhsu x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(3)));

    // TEST 11: MULHSU - Signed Positive (2) * Unsigned Max (0xFFFFFFFF) -> High: 0x00000001
    print_test_start(11, "MULHSU: Signed +2 * Unsigned 0xFFFFFFFF -> High: 0x00000001");
    init_memory();
    imem_write_word(0, 32'h00200093); // addi   x1, x0, 2
    imem_write_word(1, 32'hfff00113); // addi   x2, x0, -1 (unsigned max: 0xFFFFFFFF)
    imem_write_word(2, 32'h0220a1b3); // mulhsu x3, x1, x2 (2 * (2^32 - 1) = 2^33 - 2 -> High: 1)
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h00000001);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x00000001)", get_gpr(3)));

    // TEST 12: MULH - Min Negative Integer Squared (-2^31 * -2^31 = 2^62)
    print_test_start(12, "MULH: 0x80000000 * 0x80000000 (High: 0x40000000)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000 (0x80000000 = -2147483648)
    imem_write_word(1, 32'h02109133); // mulh x2, x1, x1  (2^62 -> High: 0x40000000)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h40000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x40000000)", get_gpr(2)));

    // ========================================================================
    // SECTION C: SIGNED & UNSIGNED DIVISION (DIV, DIVU)
    // ========================================================================

    // TEST 13: DIV - Positive / Positive with Truncation (20 / 6 = 3)
    print_test_start(13, "DIV: Positive division truncation (20 / 6 = 3)");
    init_memory();
    imem_write_word(0, 32'h01400093); // addi x1, x0, 20
    imem_write_word(1, 32'h00600113); // addi x2, x0, 6
    imem_write_word(2, 32'h0220c1b3); // div  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd3);
    end_test(test_passed, $sformatf("x3 = %0d (exp 3)", get_gpr(3)));

    // TEST 14: DIV - Negative / Positive (Truncation toward zero: -20 / 6 = -3)
    print_test_start(14, "DIV: Negative / Positive truncation toward zero (-20 / 6 = -3)");
    init_memory();
    imem_write_word(0, 32'hfec00093); // addi x1, x0, -20 (0xFFFFFFEC)
    imem_write_word(1, 32'h00600113); // addi x2, x0, 6
    imem_write_word(2, 32'h0220c1b3); // div  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = ($signed(get_gpr(3)) == -3);
    end_test(test_passed, $sformatf("x3 = %0d (exp -3)", $signed(get_gpr(3))));

    // TEST 15: DIV - Negative / Negative (-20 / -3 = 6)
    print_test_start(15, "DIV: Negative / Negative (-20 / -3 = 6)");
    init_memory();
    imem_write_word(0, 32'hfec00093); // addi x1, x0, -20 (0xFFFFFFEC)
    imem_write_word(1, 32'hffd00113); // addi x2, x0, -3
    imem_write_word(2, 32'h0220c1b3); // div  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd6);
    end_test(test_passed, $sformatf("x3 = %0d (exp 6)", get_gpr(3)));

    // TEST 16: DIVU - Unsigned Division (0xFFFFFFFF / 2 = 0x7FFFFFFF)
    print_test_start(16, "DIVU: Max unsigned divided by 2 (0xFFFFFFFF / 2 = 0x7FFFFFFF)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1 (0xFFFFFFFF)
    imem_write_word(1, 32'h00200113); // addi x2, x0, 2
    imem_write_word(2, 32'h0220d1b3); // divu x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h7FFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x7FFFFFFF)", get_gpr(3)));

    // TEST 17: DIV - Signed Arithmetic Overflow Limit (-2^31 / -1 = -2^31)
    print_test_start(17, "DIV Overflow: -2147483648 / -1 = -2147483648 (Spec Mandated)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000 (0x80000000)
    imem_write_word(1, 32'hfff00113); // addi x2, x0, -1
    imem_write_word(2, 32'h0220c1b3); // div  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h80000000);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x80000000)", get_gpr(3)));

    // TEST 18: DIV - Divide by 1 Identity (X / 1 = X)
    print_test_start(18, "DIV: Division by 1 identity");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h0220c1b3); // div  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h12345000);
    end_test(test_passed, $sformatf("x3 = 0x%08x", get_gpr(3)));

    // ========================================================================
    // SECTION D: SIGNED & UNSIGNED REMAINDER (REM, REMU)
    // ========================================================================

    // TEST 19: REM - Positive % Positive (20 % 6 = 2)
    print_test_start(19, "REM: Positive remainder (20 % 6 = 2)");
    init_memory();
    imem_write_word(0, 32'h01400093); // addi x1, x0, 20
    imem_write_word(1, 32'h00600113); // addi x2, x0, 6
    imem_write_word(2, 32'h0220e1b3); // rem  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 20: REM - Negative % Positive (-20 % 6 = -2, sign follows dividend)
    print_test_start(20, "REM: Negative dividend sign propagation (-20 % 6 = -2)");
    init_memory();
    imem_write_word(0, 32'hfec00093); // addi x1, x0, -20 (0xFFFFFFEC)
    imem_write_word(1, 32'h00600113); // addi x2, x0, 6
    imem_write_word(2, 32'h0220e1b3); // rem  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = ($signed(get_gpr(3)) == -2);
    end_test(test_passed, $sformatf("x3 = %0d (exp -2)", $signed(get_gpr(3))));

    // TEST 21: REM - Positive % Negative (20 % -6 = 2, sign follows dividend)
    print_test_start(21, "REM: Positive dividend with negative divisor (20 % -6 = 2)");
    init_memory();
    imem_write_word(0, 32'h01400093); // addi x1, x0, 20
    imem_write_word(1, 32'hffa00113); // addi x2, x0, -6
    imem_write_word(2, 32'h0220e1b3); // rem  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // TEST 22: REMU - Unsigned Remainder (0xFFFFFFFF % 10 = 5)
    print_test_start(22, "REMU: Unsigned remainder (0xFFFFFFFF % 10 = 5)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1 (4294967295)
    imem_write_word(1, 32'h00a00113); // addi x2, x0, 10
    imem_write_word(2, 32'h0220f1b3); // remu x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd5);
    end_test(test_passed, $sformatf("x3 = %0d (exp 5)", get_gpr(3)));

    // TEST 23: REM - Overflow Remainder (-2^31 % -1 = 0)
    print_test_start(23, "REM Overflow: -2147483648 % -1 = 0 (Spec Mandated)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'hfff00113); // addi x2, x0, -1
    imem_write_word(2, 32'h0220e1b3); // rem  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd0);
    end_test(test_passed, $sformatf("x3 = %0d (exp 0)", get_gpr(3)));

    // ========================================================================
    // SECTION E: SPEC-MANDATED DIVISION-BY-ZERO CORNERS
    // ========================================================================

    // TEST 24: DIV by Zero -> Returns -1 (0xFFFFFFFF)
    print_test_start(24, "DIV by Zero: 7 / 0 = -1 (0xFFFFFFFF)");
    init_memory();
    imem_write_word(0, 32'h00700093); // addi x1, x0, 7
    imem_write_word(1, 32'h0200c133); // div  x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(2)));

    // TEST 25: DIVU by Zero -> Returns 0xFFFFFFFF
    print_test_start(25, "DIVU by Zero: 7 / 0 = 0xFFFFFFFF");
    init_memory();
    imem_write_word(0, 32'h00700093); // addi x1, x0, 7
    imem_write_word(1, 32'h0200d133); // divu x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(2)));

    // TEST 26: REM by Zero -> Returns Dividend (7 % 0 = 7)
    print_test_start(26, "REM by Zero: 7 % 0 = 7 (returns dividend)");
    init_memory();
    imem_write_word(0, 32'h00700093); // addi x1, x0, 7
    imem_write_word(1, 32'h0200e133); // rem  x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd7);
    end_test(test_passed, $sformatf("x2 = %0d (exp 7)", get_gpr(2)));

    // TEST 27: REMU by Zero -> Returns Dividend (~0 % 0 = ~0)
    print_test_start(27, "REMU by Zero: 0xFFFFFFFF % 0 = 0xFFFFFFFF");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0200f133); // remu x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(2)));

    // ========================================================================
    // SECTION F: MDU PIPELINE REUSE, FORWARDING & x0 INVARIANCE
    // ========================================================================

    // TEST 28: Consecutive DIV & REM (Quotient + Remainder extraction)
    print_test_start(28, "MDU Handshake: Back-to-back DIV and REM on same inputs");
    init_memory();
    imem_write_word(0, 32'h01d00093); // addi x1, x0, 29
    imem_write_word(1, 32'h00700113); // addi x2, x0, 7
    imem_write_word(2, 32'h0220c1b3); // div  x3, x1, x2 (4)
    imem_write_word(3, 32'h00000013); // nop
    imem_write_word(4, 32'h00000013); // nop
    imem_write_word(5, 32'h0220e233); // rem  x4, x1, x2 (1)
    imem_write_word(6, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 85; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd4) && (get_gpr(4) == 32'd1));
    end_test(test_passed, $sformatf("x3 = %0d (exp 4), x4 = %0d (exp 1)", get_gpr(3), get_gpr(4)));

    // TEST 29: Destination x0 Invariance on MUL and DIV
    print_test_start(29, "x0 Invariance: MUL and DIV with destination rd = x0");
    init_memory();
    imem_write_word(0, 32'h00600093); // addi x1, x0, 6
    imem_write_word(1, 32'h00700113); // addi x2, x0, 7
    imem_write_word(2, 32'h02208033); // mul  x0, x1, x2 (Target x0)
    imem_write_word(3, 32'h00000013); // nop
    imem_write_word(4, 32'h00000013); // nop
    imem_write_word(5, 32'h0220c033); // div  x0, x1, x2 (Target x0)
    imem_write_word(6, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 70; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(0) == 32'h00000000);
    end_test(test_passed, $sformatf("x0 = 0x%08x (strictly zero)", get_gpr(0)));

    // TEST 30: MDU to ALU Forwarding Chain: (6 * 7) + (100 / 5) = 42 + 20 = 62
    print_test_start(30, "Complex Chain: (MUL) + (DIV) combined into ALU adder");
    init_memory();
    imem_write_word(0, 32'h00600093); // addi x1, x0, 6
    imem_write_word(1, 32'h00700113); // addi x2, x0, 7
    imem_write_word(2, 32'h022081b3); // mul  x3, x1, x2 (42)
    imem_write_word(3, 32'h06400213); // addi x4, x0, 100
    imem_write_word(4, 32'h00500293); // addi x5, x0, 5
    imem_write_word(5, 32'h02524333); // div  x6, x4, x5 (20)
    imem_write_word(6, 32'h00000013); // nop
    imem_write_word(7, 32'h00000013); // nop
    imem_write_word(8, 32'h006183b3); // add  x7, x3, x6 (42 + 20 = 62)
    imem_write_word(9, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 95; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd42) && (get_gpr(6) == 32'd20) && (get_gpr(7) == 32'd62));
    end_test(test_passed, $sformatf("x3 = 42, x6 = 20, x7 = %0d (exp 62)", get_gpr(7)));

    // ========================================================================
    // FINAL BENCHMARK SUMMARY
    // ========================================================================
    print_header("RV32M EXTENSION BENCHMARK SUMMARY");
    $display("Total RV32M Tests:    %0d", total_tests);
    $display("Passed:               %0d", passed_tests);
    $display("Failed:               %0d", failed_tests);
    $display("Success Rate:         %0d%%\n", (passed_tests * 100) / total_tests);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                 ALL 30 RV32M INSTRUCTION BENCHMARK TESTS PASSED CLEANLY!                               ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                           SOME RV32M BENCHMARK TESTS FAILED!                                            ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule
