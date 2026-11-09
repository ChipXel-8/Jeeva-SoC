`timescale 1ns / 1ps

module tb_pragya_benchmark_itype;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_ITYPE_TESTS = 30;

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

  // Execution Flow
  initial begin
    total_tests  = 0;
    passed_tests = 0;
    failed_tests = 0;

    print_header("PRAGYA RV32I I-TYPE COMPREHENSIVE CORNER-CASE BENCHMARK");

    // ========================================================================
    // SECTION A: ADDI & SIGN-EXTENSION CORNER CASES
    // ========================================================================

    // TEST 1: ADDI - Maximum Positive Immediate (+2047 = 12'h7FF)
    print_test_start(1, "ADDI: Max positive immediate (+2047: x1 = 0 + 2047)");
    init_memory();
    imem_write_word(0, 32'h7ff00093); // addi x1, x0, 2047
    imem_write_word(1, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'd2047);
    end_test(test_passed, $sformatf("x1 = %0d (exp 2047)", get_gpr(1)));

    // TEST 2: ADDI - Minimum Negative Immediate (-2048 = 12'h800)
    print_test_start(2, "ADDI: Min negative immediate (-2048: x1 = 0 - 2048)");
    init_memory();
    imem_write_word(0, 32'h80000093); // addi x1, x0, -2048 (0xFFFFF800)
    imem_write_word(1, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'hFFFFF800);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0xFFFFF800)", get_gpr(1)));

    // TEST 3: ADDI - Two's Complement -1 Accumulation
    print_test_start(3, "ADDI: Add -1 (0xFFFFFFFF) decrementing register (5 + -1 = 4)");
    init_memory();
    imem_write_word(0, 32'h00500093); // addi x1, x0, 5
    imem_write_word(1, 32'hfff08093); // addi x1, x1, -1 (4)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'd4);
    end_test(test_passed, $sformatf("x1 = %0d (exp 4)", get_gpr(1)));

    // TEST 4: ADDI - Negative to Positive Wraparound (-1 + 1 = 0)
    print_test_start(4, "ADDI: Negative to zero transition (-1 + 1 = 0)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h00108093); // addi x1, x1, 1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'd0);
    end_test(test_passed, $sformatf("x1 = %0d (exp 0)", get_gpr(1)));

    // TEST 5: ADDI - Upper Boundary Wraparound (0x7FFFFFFF + 1 = 0x80000000)
    print_test_start(5, "ADDI: Positive overflow to negative boundary (0x7FFFFFFF + 1)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0010d093); // srli x1, x1, 1 -> 0x7FFFFFFF
    imem_write_word(2, 32'h00108113); // addi x2, x1, 1 -> 0x80000000
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h80000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x80000000)", get_gpr(2)));

    // TEST 6: ADDI - Negative Underflow Wraparound (0x80000000 + -1 = 0x7FFFFFFF)
    print_test_start(6, "ADDI: Negative underflow to positive boundary (0x80000000 + -1)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000 -> 0x80000000
    imem_write_word(1, 32'hfff08113); // addi x2, x1, -1  -> 0x7FFFFFFF
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h7FFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x7FFFFFFF)", get_gpr(2)));

    // ========================================================================
    // SECTION B: IMMEDIATE SHIFTS (SLLI, SRLI, SRAI)
    // ========================================================================

    // TEST 7: SLLI - Shift Left Immediate by 0
    print_test_start(7, "SLLI: Shift left by 0 bits (identity)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345
    imem_write_word(1, 32'h00009113); // slli x2, x1, 0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h12345000);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 8: SLLI - Shift Left Immediate by 1 bit
    print_test_start(8, "SLLI: Single bit shift left (1 << 1 = 2)");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'h00109113); // slli x2, x1, 1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd2);
    end_test(test_passed, $sformatf("x2 = %0d", get_gpr(2)));

    // TEST 9: SLLI - Maximum Shift Left by 31 bits
    print_test_start(9, "SLLI: Maximum shift left (1 << 31 = 0x80000000)");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'h01f09113); // slli x2, x1, 31
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h80000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x80000000)", get_gpr(2)));

    // TEST 10: SRLI - Logical Shift Right Immediate by 0
    print_test_start(10, "SRLI: Shift right by 0 bits (identity)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1 (0xFFFFFFFF)
    imem_write_word(1, 32'h0000d113); // srli x2, x1, 0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 11: SRLI - Logical Right Shift Zero Extension
    print_test_start(11, "SRLI: Zero-fill upper bits (0xFFFFFFFF >> 4 = 0x0FFFFFFF)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0040d113); // srli x2, x1, 4
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h0FFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x0FFFFFFF)", get_gpr(2)));

    // TEST 12: SRLI - Maximum Logical Shift Right by 31 bits
    print_test_start(12, "SRLI: Maximum shift right (0xFFFFFFFF >> 31 = 1)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h01f0d113); // srli x2, x1, 31
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd1);
    end_test(test_passed, $sformatf("x2 = %0d (exp 1)", get_gpr(2)));

    // TEST 13: SRAI - Arithmetic Shift Right Preserving Negative Sign Bit
    print_test_start(13, "SRAI: Arithmetic shift preserving sign (0x80000000 >>> 4 = 0xF8000000)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000 (0x80000000)
    imem_write_word(1, 32'h4040d113); // srai x2, x1, 4
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hF8000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xF8000000)", get_gpr(2)));

    // TEST 14: SRAI - Maximum Arithmetic Shift Right by 31 bits
    print_test_start(14, "SRAI: Shift by 31 on negative value (0x80000000 >>> 31 = 0xFFFFFFFF)");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'h41f0d113); // srai x2, x1, 31
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xFFFFFFFF)", get_gpr(2)));

    // TEST 15: SRAI - Arithmetic Shift Right on Positive Value (Sign = 0)
    print_test_start(15, "SRAI: Shift on positive value (0x40000000 >>> 4 = 0x04000000)");
    init_memory();
    imem_write_word(0, 32'h400000b7); // lui  x1, 0x40000
    imem_write_word(1, 32'h4040d113); // srai x2, x1, 4
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h04000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x04000000)", get_gpr(2)));

    // ========================================================================
    // SECTION C: COMPARISONS WITH IMMEDIATE (SLTI & SLTIU)
    // ========================================================================

    // TEST 16: SLTI - Negative Register vs Positive Immediate (-1 < 1 is true)
    print_test_start(16, "SLTI: Negative register vs positive immediate (-1 < 1)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0010a113); // slti x2, x1, 1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd1);
    end_test(test_passed, $sformatf("x2 = %0d (exp 1)", get_gpr(2)));

    // TEST 17: SLTI - Positive Register vs Negative Immediate (10 < -1 is false)
    print_test_start(17, "SLTI: Positive register vs negative immediate (10 < -1)");
    init_memory();
    imem_write_word(0, 32'h00a00093); // addi x1, x0, 10
    imem_write_word(1, 32'hfff0a113); // slti x2, x1, -1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd0);
    end_test(test_passed, $sformatf("x2 = %0d (exp 0)", get_gpr(2)));

    // TEST 18: SLTIU - Negative Register vs Small Positive Immediate
    print_test_start(18, "SLTIU: Unsigned magnitude (0xFFFFFFFF < 1 is false)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi  x1, x0, -1 (0xFFFFFFFF)
    imem_write_word(1, 32'h0010b113); // sltiu x2, x1, 1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd0);
    end_test(test_passed, $sformatf("x2 = %0d (exp 0)", get_gpr(2)));

    // TEST 19: SLTIU - Sign-Extended Immediate Handling (1 < -1 sign-extended = true)
    print_test_start(19, "SLTIU: 1 < 0xFFFFFFFF (imm=-1 sign-extended is max unsigned)");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi  x1, x0, 1
    imem_write_word(1, 32'hfff0b113); // sltiu x2, x1, -1 (imm sign-extends to 0xFFFFFFFF)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd1);
    end_test(test_passed, $sformatf("x2 = %0d (exp 1)", get_gpr(2)));

    // TEST 20: SLTI - Equal Values (10 < 10 is false)
    print_test_start(20, "SLTI: Identity comparison with equal immediate (10 < 10 is false)");
    init_memory();
    imem_write_word(0, 32'h00a00093); // addi x1, x0, 10
    imem_write_word(1, 32'h00a0a113); // slti x2, x1, 10
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd0);
    end_test(test_passed, $sformatf("x2 = %0d (exp 0)", get_gpr(2)));

    // TEST 21: SLTI - Extreme Signed Lower Boundary (0x80000000 < -2048)
    print_test_start(21, "SLTI: 0x80000000 < -2048 is true");
    init_memory();
    imem_write_word(0, 32'h800000b7); // lui  x1, 0x80000
    imem_write_word(1, 32'h8000a113); // slti x2, x1, -2048
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd1);
    end_test(test_passed, $sformatf("x2 = %0d (exp 1)", get_gpr(2)));

    // ========================================================================
    // SECTION D: BITWISE IMMEDIATE LOGIC (XORI, ORI, ANDI)
    // ========================================================================

    // TEST 22: XORI - Bitwise Inversion / NOT Pseudo-instruction (x ^ -1)
    print_test_start(22, "XORI: Full bitwise inversion using immediate -1 (NOT operation)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui  x1, 0x12345 (0x12345000)
    imem_write_word(1, 32'hfff0c113); // xori x2, x1, -1     (0xEDCBAFFF)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hEDCBAFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0xEDCBAFFF)", get_gpr(2)));

    // TEST 23: XORI - Immediate Sign-Extension Masking (x ^ 0x0AA)
    print_test_start(23, "XORI: Positive immediate XOR (0xFFFFFFFF ^ 0x0AA = 0xFFFFFF55)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0aa0c113); // xori x2, x1, 0x0AA
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFF55);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 24: ORI - Setting Lowest Bits with Positive Immediate
    print_test_start(24, "ORI: Set lowest bits (0x12345000 | 0x055 = 0x12345055)");
    init_memory();
    imem_write_word(0, 32'h123450b7); // lui x1, 0x12345
    imem_write_word(1, 32'h0550e113); // ori x2, x1, 0x055
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h12345055);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 25: ORI - Setting All Upper Bits with Negative Immediate (-1)
    print_test_start(25, "ORI: Sign-extended -1 sets all bits (0 | -1 = 0xFFFFFFFF)");
    init_memory();
    imem_write_word(0, 32'hfff0e113); // ori x2, x0, -1
    imem_write_word(1, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'hFFFFFFFF);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 26: ANDI - Isolating Low Byte with Positive Immediate (0xFFFFFFFF & 0x0FF)
    print_test_start(26, "ANDI: Low-byte mask with positive immediate (0xFFFFFFFF & 0x0FF = 0xFF)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0ff0f113); // andi x2, x1, 0x0FF
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h000000FF);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // TEST 27: ANDI - Clearing All Bits with Immediate 0
    print_test_start(27, "ANDI: Zero clear identity (0xFFFFFFFF & 0 = 0)");
    init_memory();
    imem_write_word(0, 32'hfff00093); // addi x1, x0, -1
    imem_write_word(1, 32'h0000f113); // andi x2, x1, 0
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000000);
    end_test(test_passed, $sformatf("x2 = 0x%08x", get_gpr(2)));

    // ========================================================================
    // SECTION E: FORWARDING, DEPENDENCY CHAINS & x0 INVARIANCE
    // ========================================================================

    // TEST 28: I-Type Consecutive RAW Execution Chain
    print_test_start(28, "RAW: Consecutive dependent I-Type operations without bubbles");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'h00308093); // addi x1, x1, 3   -> 4
    imem_write_word(2, 32'h00209093); // slli x1, x1, 2   -> 16
    imem_write_word(3, 32'h0010c093); // xori x1, x1, 1   -> 17
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'd17);
    end_test(test_passed, $sformatf("x1 = %0d (exp 17)", get_gpr(1)));

    // TEST 29: I-Type Target rd = x0 Invariance
    print_test_start(29, "x0 Invariance: I-type operation with destination rd = x0");
    init_memory();
    imem_write_word(0, 32'h7ff00013); // addi x0, x0, 2047
    imem_write_word(1, 32'hfff00013); // addi x0, x0, -1
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(0) == 32'h00000000);
    end_test(test_passed, $sformatf("x0 = 0x%08x (strictly zero)", get_gpr(0)));

    // TEST 30: Stress: Back-to-Back Shifts and Mixed I-Type Chain
    print_test_start(30, "Stress: Mixed ADDI -> SLLI -> SRAI -> ANDI -> XORI chain");
    init_memory();
    imem_write_word(0, 32'h00100093); // addi x1, x0, 1
    imem_write_word(1, 32'h01f09093); // slli x1, x1, 31  -> 0x80000000
    imem_write_word(2, 32'h4040d093); // srai x1, x1, 4   -> 0xF8000000
    imem_write_word(3, 32'hfff0f093); // andi x1, x1, -1  -> 0xF8000000
    imem_write_word(4, 32'hfff0c093); // xori x1, x1, -1  -> 0x07FFFFFF
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h07FFFFFF);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0x07FFFFFF)", get_gpr(1)));

    // ========================================================================
    // FINAL BENCHMARK SUMMARY
    // ========================================================================
    print_header("I-TYPE BENCHMARK SUMMARY");
    $display("Total I-Type Corner Tests: %0d", total_tests);
    $display("Passed:                    %0d", passed_tests);
    $display("Failed:                    %0d", failed_tests);
    $display("Success Rate:              %0d%%\n", (passed_tests * 100) / total_tests);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                 ALL 30 I-TYPE INSTRUCTION BENCHMARK TESTS PASSED CLEANLY!                               ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                           SOME I-TYPE BENCHMARK TESTS FAILED!                                           ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule