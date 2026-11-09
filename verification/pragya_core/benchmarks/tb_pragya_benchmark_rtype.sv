`timescale 1ns / 1ps

module tb_pragya_benchmark_rtype;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_RTYPE_TESTS = 30;

  // DUT Top-Level Interface Signals
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

  // 100MHz Clock
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

    print_header("PRAGYA RV32I R-TYPE COMPREHENSIVE CORNER-CASE BENCHMARK");

    // ========================================================================
    // SECTION A: ADD & SUB ARITHMETIC CORNER CASES
    // ========================================================================

    // TEST 1: ADD - Signed Positive Overflow Wraparound
    print_test_start(1, "ADD: Max positive overflow wraparound (0x7FFFFFFF + 1 = 0x80000000)");
    init_memory();
    // Load exact 0x7FFFFFFF via (0xFFFFFFFF >> 1)
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1       -> x1 = 0xFFFFFFFF
    imem_write_word(1, 32'h0010d093); // srli x1, x1, 1        -> x1 = 0x7FFFFFFF
    imem_write_word(2, 32'h00100113); // addi x2, x0, 1        -> x2 = 0x00000001
    imem_write_word(3, 32'h002081b3); // add  x3, x1, x2       -> x3 = 0x80000000
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h80000000);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x80000000)", get_gpr(3)));

    // TEST 2: SUB - Negative Underflow Wraparound
    print_test_start(2, "SUB: Min negative underflow wraparound (0x80000000 - 1 = 0x7FFFFFFF)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000 -> x1 = 0x80000000
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h402081b3); // sub  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h7FFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x7FFFFFFF)", get_gpr(3)));

    // TEST 3: SUB - Subtract Identical Register (A - A = 0)
    print_test_start(3, "SUB: Self-subtraction identity (x1 - x1 = 0)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h40108133); // sub  x2, x1, x1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x00000000)", get_gpr(2)));

    // TEST 4: SUB - Negating Minimum Signed Integer (0 - 0x80000000 = 0x80000000)
    print_test_start(4, "SUB: Negate 0x80000000 boundary (0 - 0x80000000 = 0x80000000)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'h40100133); // sub  x2, x0, x1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h80000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x80000000)", get_gpr(2)));

    // ========================================================================
    // SECTION B: SHIFT OPERATIONS & SHIFT-AMOUNT MASKING (rs2[4:0])
    // ========================================================================

    // TEST 5: SLL - Shift Left by 0
    print_test_start(5, "SLL: Shift left by 0 bits");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h00000113); // addi x2, x0, 0
    imem_write_word(2, 32'h002091b3); // sll  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h12345000);
    end_test(test_passed, $sformatf("x3 = 0x%08x", get_gpr(3)));

    // TEST 6: SLL - Shift Left by 31 bits
    print_test_start(6, "SLL: Shift left maximum 31 bits");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'h01f00113); // addi x2, x0, 31
    imem_write_word(2, 32'h002091b3); // sll  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h80000000);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x80000000)", get_gpr(3)));

    // TEST 7: SLL - Shift Amount Masking (rs2 = 33 -> only rs2[4:0]=1 is used)
    print_test_start(7, "SLL: Shift amount masking (shift by 33 must equal shift by 1)");
    init_memory();
    imem_write_word(0, 32'h00f00093); // addi x1, x0, 0x0F
    imem_write_word(1, 32'h02100113); // addi x2, x0, 33 (33 & 0x1F = 1)
    imem_write_word(2, 32'h002091b3); // sll  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h0000001E);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x0000001E)", get_gpr(3)));

    // TEST 8: SRL - Logical Shift Right on Negative Value (Zero-fill verification)
    print_test_start(8, "SRL: Logical shift right zero fills upper bits (0xFFFFFFFF >> 4)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h00400113); // addi x2, x0, 4
    imem_write_word(2, 32'h0020d1b3); // srl  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h0FFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x0FFFFFFF)", get_gpr(3)));

    // TEST 9: SRL - Shift Amount Masking (rs2 = 64 -> rs2[4:0]=0 -> No change)
    print_test_start(9, "SRL: Shift amount masking (shift by 64 must equal shift by 0)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h04000113); // addi x2, x0, 64 (64 & 0x1F = 0)
    imem_write_word(2, 32'h0020d1b3); // srl  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h12345000);
    end_test(test_passed, $sformatf("x3 = 0x%08x", get_gpr(3)));

    // TEST 10: SRA - Arithmetic Shift Right Preserving Sign Bit
    print_test_start(10, "SRA: Arithmetic shift right sign preservation (0x80000000 >> 4)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'h00400113); // addi x2, x0, 4
    imem_write_word(2, 32'h4020d1b3); // sra  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'hF8000000);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0xF8000000)", get_gpr(3)));

    // TEST 11: SRA - Arithmetic Shift Right Maximum (31 shifts on negative value)
    print_test_start(11, "SRA: Arithmetic shift right by 31 bits (0x80000000 >> 31 = 0xFFFFFFFF)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'h01f00113); // addi x2, x0, 31
    imem_write_word(2, 32'h4020d1b3); // sra  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(3)));

    // TEST 12: SRA - Arithmetic Shift Right on Positive Value (Sign=0)
    print_test_start(12, "SRA: Positive operand sign preservation (0x70000000 >> 4 = 0x07000000)");
    init_memory();
    imem_write_word(0, 32'h700000b7); // lui  x1, 0x70000
    imem_write_word(1, 32'h00400113); // addi x2, x0, 4
    imem_write_word(2, 32'h4020d1b3); // sra  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h07000000);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x07000000)", get_gpr(3)));

    // ========================================================================
    // SECTION C: COMPARISONS (SLT Signed vs SLTU Unsigned)
    // ========================================================================

    // TEST 13: SLT - Negative vs Positive (-1 < 1 -> 1)
    print_test_start(13, "SLT: Negative vs Positive (-1 < 1 is true)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h0020a1b3); // slt  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d", get_gpr(3)));

    // TEST 14: SLTU - Negative vs Positive (~0 < 1 is false)
    print_test_start(14, "SLTU: Unsigned comparison (0xFFFFFFFF < 1 is false)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1 (0xFFFFFFFF)
    imem_write_word(1, 32'h00100113); // addi x2, x0, 1
    imem_write_word(2, 32'h0020b1b3); // sltu x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd0);
    end_test(test_passed, $sformatf("x3 = %0d", get_gpr(3)));

    // TEST 15: SLT - Both Negative (-5 < -2 is true)
    print_test_start(15, "SLT: Both negative operands (-5 < -2 is true)");
    init_memory();
    imem_write_word(0, 32'hffb00093); // addi x1, x0, -5
    imem_write_word(1, 32'hffe00113); // addi x2, x0, -2
    imem_write_word(2, 32'h0020a1b3); // slt  x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d", get_gpr(3)));

    // TEST 16: SLTU - Both Negative (~4 < ~1 is true in unsigned)
    print_test_start(16, "SLTU: Unsigned order of negative values (0xFFFFFFFB < 0xFFFFFFFE)");
    init_memory();
    imem_write_word(0, 32'hffb00093); // addi x1, x0, -5 (0xFFFFFFFB)
    imem_write_word(1, 32'hffe00113); // addi x2, x0, -2 (0xFFFFFFFE)
    imem_write_word(2, 32'h0020b1b3); // sltu x3, x1, x2
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d", get_gpr(3)));

    // TEST 17: SLT / SLTU - Equal Operands (A < A = 0)
    print_test_start(17, "SLT & SLTU: Equal operands identity (A < A = 0)");
    init_memory();
    imem_write_word(0, 32'h02a00093); // addi x1, x0, 42
    imem_write_word(1, 32'h0010a133); // slt  x2, x1, x1
    imem_write_word(2, 32'h0010b1b3); // sltu x3, x1, x1
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(2) == 32'd0) && (get_gpr(3) == 32'd0));
    end_test(test_passed, $sformatf("slt=%0d, sltu=%0d", get_gpr(2), get_gpr(3)));

    // TEST 18: SLT - Min Negative vs Max Positive (0x80000000 < 0x7FFFFFFF)
    print_test_start(18, "SLT: 0x80000000 < 0x7FFFFFFF signed boundary");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000 (0x80000000)
    imem_write_word(1, 32'h7ffff137); // lui  x2, 0x7FFFF
    imem_write_word(2, 32'hfff10113); // addi x2, x2, 0xFFF (0x7FFFFFFF)
    imem_write_word(3, 32'h0020a1b3); // slt  x3, x1, x2
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd1);
    end_test(test_passed, $sformatf("x3 = %0d", get_gpr(3)));

    // TEST 19: SLTU - 0 vs Any Non-Zero Value (0 < X is always true)
    print_test_start(19, "SLTU: Zero is less than any unsigned non-zero value");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'h00103133); // sltu x2, x0, x1
    imem_write_word(2, 32'h0000b1b3); // sltu x3, x1, x0
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(2) == 32'd1) && (get_gpr(3) == 32'd0));
    end_test(test_passed, $sformatf("0<1=%0d, 1<0=%0d", get_gpr(2), get_gpr(3)));

    // ========================================================================
    // SECTION D: LOGIC BIT-PERMUTATION CORNERS (XOR, OR, AND)
    // ========================================================================

    // TEST 20: XOR - Self Cancellation (x ^ x = 0)
    print_test_start(20, "XOR: Self cancellation identity (x ^ x = 0)");
    init_memory();
    imem_write_word(0, 32'ha5a5a0b7); // lui  x1, 0xA5A5A
    imem_write_word(1, 32'h0010c133); // xor  x2, x1, x1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 21: XOR - Alternating Checkerboards (0xAAAAAAAA ^ 0x55555555 = 0xFFFFFFFF)
    print_test_start(21, "XOR: Complementary checkerboard inversion");
    init_memory();
    imem_write_word(0, 32'h55555137); // lui  x2, 0x55555
    imem_write_word(1, 32'h55516113); // ori  x2, x2, 0x555    -> x2 = 0x55555555
    imem_write_word(2, 32'hfff14093); // xori x1, x2, -1      -> x1 = 0xAAAAAAAA
    imem_write_word(3, 32'h0020c1b3); // xor  x3, x1, x2      -> x3 = 0xFFFFFFFF
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(3)));

    // TEST 22: AND - Complementary Checkerboards (0xAAAAAAAA & 0x55555555 = 0)
    print_test_start(22, "AND: Disjoint checkerboards (0xAAAAAAAA & 0x55555555 = 0)");
    init_memory();
    imem_write_word(0, 32'h55555137); // lui  x2, 0x55555
    imem_write_word(1, 32'h55516113); // ori  x2, x2, 0x555    -> x2 = 0x55555555
    imem_write_word(2, 32'hfff14093); // xori x1, x2, -1      -> x1 = 0xAAAAAAAA
    imem_write_word(3, 32'h0020f1b3); // and  x3, x1, x2      -> x3 = 0x00000000
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h00000000);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0x00000000)", get_gpr(3)));

    // TEST 23: OR - Complementary Checkerboards (0xAAAAAAAA | 0x55555555 = 0xFFFFFFFF)
    print_test_start(23, "OR: Disjoint checkerboards union (0xAAAAAAAA | 0x55555555 = 0xFFFFFFFF)");
    init_memory();
    imem_write_word(0, 32'h55555137); // lui  x2, 0x55555
    imem_write_word(1, 32'h55516113); // ori  x2, x2, 0x555    -> x2 = 0x55555555
    imem_write_word(2, 32'hfff14093); // xori x1, x2, -1      -> x1 = 0xAAAAAAAA
    imem_write_word(3, 32'h0020e1b3); // or   x3, x1, x2      -> x3 = 0xFFFFFFFF
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x3 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(3)));

    // TEST 24: AND - Masking with Zero (X & 0 = 0)
    print_test_start(24, "AND: Masking with zero identity (x & 0 = 0)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0000f133); // and  x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 25: OR - Identity with Zero (X | 0 = X)
    print_test_start(25, "OR: Identity with zero (x | 0 = x)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h0000e133); // or   x2, x1, x0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h12345000);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // ========================================================================
    // SECTION E: FORWARDING, DEPENDENCY CHAINS & x0 INVARIANCE
    // ========================================================================

    // TEST 26: R-Type Execution Forwarding Chain (EX/MEM -> ID/EX)
    print_test_start(26, "RAW: Consecutive dependent R-Type chain without bubbles");
    init_memory();
    imem_write_word(0, 32'h00200093); // addi x1, x0, 2
    imem_write_word(1, 32'h00108133); // add  x2, x1, x1  -> 4
    imem_write_word(2, 32'h002101b3); // add  x3, x2, x2  -> 8
    imem_write_word(3, 32'h00318233); // add  x4, x3, x3  -> 16
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(2) == 32'd4) && (get_gpr(3) == 32'd8) && (get_gpr(4) == 32'd16));
    end_test(test_passed, $sformatf("x2=%0d, x3=%0d, x4=%0d", get_gpr(2), get_gpr(3), get_gpr(4)));

    // TEST 27: R-Type Two Operands Identical (A + A = 2*A)
    print_test_start(27, "ADD: rs1 and rs2 referencing identical register");
    init_memory();
    imem_write_word(0, 32'h00500093); // addi x1, x0, 5
    imem_write_word(1, 32'h00108133); // add  x2, x1, x1 (5 + 5 = 10)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd10);
    end_test(test_passed, $sformatf("x2 = %0d (exp 10)", get_gpr(2)));

    // TEST 28: R-Type with Destination x0 Invariance
    print_test_start(28, "x0 Invariance: R-type operation with rd = x0 (add x0, x1, x2)");
    init_memory();
    imem_write_word(0, 32'h00a00093); // addi x1, x0, 10
    imem_write_word(1, 32'h01400113); // addi x2, x0, 20
    imem_write_word(2, 32'h00208033); // add  x0, x1, x2 (Target rd = x0)
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(0) == 32'h00000000);
    end_test(test_passed, $sformatf("x0 = 0x%08x (strictly zero)", get_gpr(0)));

    // TEST 29: R-Type All Operands x0 (add x0, x0, x0)
    print_test_start(29, "x0 Boundary: add x0, x0, x0 execution");
    init_memory();
    imem_write_word(0, 32'h00000033); // add x0, x0, x0
    imem_write_word(1, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(0) == 32'h00000000);
    end_test(test_passed, "add x0, x0, x0 retired cleanly");

    // TEST 30: Alternating Arithmetic-Logic Stress Chain
    print_test_start(30, "Stress: Alternating ADD -> SUB -> XOR -> SLL -> SRA -> OR -> AND chain");
    init_memory();
    imem_write_word(0, 32'h02000093); // addi x1, x0, 32
    imem_write_word(1, 32'h00400113); // addi x2, x0, 4
    imem_write_word(2, 32'h002081b3); // add  x3, x1, x2  (32 + 4 = 36)
    imem_write_word(3, 32'h40218233); // sub  x4, x3, x2  (36 - 4 = 32)
    imem_write_word(4, 32'h002202b3); // xor  x5, x4, x2  (32 ^ 4 = 36)
    imem_write_word(5, 32'h00229333); // sll  x6, x5, x2  (36 << 4 = 576)
    imem_write_word(6, 32'h402353b3); // sra  x7, x6, x2  (576 >> 4 = 36)
    imem_write_word(7, 32'h0023e433); // or   x8, x7, x2  (36 | 4 = 36)
    imem_write_word(8, 32'h002474b3); // and  x9, x8, x2  (36 & 4 = 4)
    imem_write_word(9, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd36)  &&
                   (get_gpr(4) == 32'd32)  &&
                   (get_gpr(5) == 32'd36)  &&
                   (get_gpr(6) == 32'd576) &&
                   (get_gpr(7) == 32'd36)  &&
                   (get_gpr(8) == 32'd36)  &&
                   (get_gpr(9) == 32'd4));
    end_test(test_passed, $sformatf("End of chain result x9 = %0d (exp 4)", get_gpr(9)));

    // ========================================================================
    // FINAL BENCHMARK SUMMARY
    // ========================================================================
    print_header("R-TYPE BENCHMARK SUMMARY");
    $display("Total R-Type Corner Tests: %0d", total_tests);
    $display("Passed:                    %0d", passed_tests);
    $display("Failed:                    %0d", failed_tests);
    $display("Success Rate:              %0d%%\n", (passed_tests * 100) / total_tests);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                 ALL 30 R-TYPE INSTRUCTION BENCHMARK TESTS PASSED CLEANLY!                               ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                           SOME R-TYPE BENCHMARK TESTS FAILED!                                           ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule
