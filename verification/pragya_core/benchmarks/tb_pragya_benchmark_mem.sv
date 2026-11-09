`timescale 1ns / 1ps

module tb_pragya_benchmark_mem;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_MEM_TESTS = 25;

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

  task automatic dmem_write_word(input int word_idx, input logic [31:0] data);
    dut.D_wrapper.dmem.memory[word_idx] = data;
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

    print_header("PRAGYA RV32I LSU LOAD & STORE COMPREHENSIVE BENCHMARK");

    // ========================================================================
    // SECTION A: WORD LOAD & STORE (SW, LW)
    // ========================================================================

    // TEST 1: SW & LW - Word aligned at base (0x80008000)
    print_test_start(1, "SW/LW: Word aligned store and load");
    init_memory();
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008 (DMEM base)
    imem_write_word(1, 32'h12345097); // auipc x1, 0x12345
    imem_write_word(2, 32'h0012a023); // sw   x1, 0(x5)
    imem_write_word(3, 32'h0002a103); // lw   x2, 0(x5)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == get_gpr(1)) && (get_gpr(2) != 0);
    end_test(test_passed, $sformatf("x2 = 0x%08x (matches x1)", get_gpr(2)));

    // TEST 2: SW & LW - Positive offset (+8)
    print_test_start(2, "SW/LW: Word access with positive offset (+8)");
    init_memory();
    dmem_write_word(2, 32'hDEADBEEF);
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h0082a083); // lw   x1, 8(x5)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'hDEADBEEF);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0xDEADBEEF)", get_gpr(1)));

    // TEST 3: SW & LW - Negative offset (-4)
    print_test_start(3, "SW/LW: Word access with negative offset (-4)");
    init_memory();
    dmem_write_word(1, 32'hCAFEBABE);
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h00828293); // addi x5, x5, 8 (point to word 2)
    imem_write_word(2, 32'hffc2a083); // lw   x1, -4(x5) (load from word 1)
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'hCAFEBABE);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0xCAFEBABE)", get_gpr(1)));

    // ========================================================================
    // SECTION B: BYTE ACCESS & BYTE STROBES (SB, LB, LBU)
    // ========================================================================

    // TEST 4: SB - Store byte at offsets 0, 1, 2, 3 within the same word
    print_test_start(4, "SB: Byte writes at offsets 0, 1, 2, 3 (strobe check)");
    init_memory();
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h0aa00093); // addi x1, x0, 0xAA
    imem_write_word(2, 32'h0bb00113); // addi x2, x0, 0xBB
    imem_write_word(3, 32'h0cc00193); // addi x3, x0, 0xCC
    imem_write_word(4, 32'h0dd00213); // addi x4, x0, 0xDD
    imem_write_word(5, 32'h00128023); // sb   x1, 0(x5)
    imem_write_word(6, 32'h002280a3); // sb   x2, 1(x5)
    imem_write_word(7, 32'h00328123); // sb   x3, 2(x5)
    imem_write_word(8, 32'h004281a3); // sb   x4, 3(x5)
    imem_write_word(9, 32'h0002a283); // lw   x5, 0(x5) -> read back entire word
    imem_write_word(10,32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);
    test_passed = (dut.D_wrapper.dmem.memory[0] == 32'hDDCCBBAA) && (get_gpr(5) == 32'hDDCCBBAA);
    end_test(test_passed, $sformatf("dmem[0] = 0x%08x (exp 0xDDCCBBAA)", dut.D_wrapper.dmem.memory[0]));

    // TEST 5: LB - Signed Byte Load (Negative byte sign-extended)
    print_test_start(5, "LB: Signed byte load with MSB=1 (0x85 -> 0xFFFFFF85)");
    init_memory();
    dmem_write_word(0, 32'h00000085); // Byte 0 = 0x85
    imem_write_word(0, 32'h800082b7); // lui x5, 0x80008
    imem_write_word(1, 32'h00028083); // lb  x1, 0(x5)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'hFFFFFF85);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0xFFFFFF85)", get_gpr(1)));

    // TEST 6: LBU - Unsigned Byte Load (Zero-extended)
    print_test_start(6, "LBU: Unsigned byte load with MSB=1 (0x85 -> 0x00000085)");
    init_memory();
    dmem_write_word(0, 32'h00000085); // Byte 0 = 0x85
    imem_write_word(0, 32'h800082b7); // lui x5, 0x80008
    imem_write_word(1, 32'h0002c083); // lbu x1, 0(x5)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000085);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0x00000085)", get_gpr(1)));

    // TEST 7: LB - Read from all byte lanes (Offsets 0, 1, 2, 3)
    print_test_start(7, "LB: Individual reads from byte offsets 0, 1, 2, 3");
    init_memory();
    dmem_write_word(0, 32'h04030201); // Lane 0=1, 1=2, 2=3, 3=4
    imem_write_word(0, 32'h800082b7); // lui x5, 0x80008
    imem_write_word(1, 32'h00028083); // lb  x1, 0(x5) -> 1
    imem_write_word(2, 32'h00128103); // lb  x2, 1(x5) -> 2
    imem_write_word(3, 32'h00228183); // lb  x3, 2(x5) -> 3
    imem_write_word(4, 32'h00328203); // lb  x4, 3(x5) -> 4
    imem_write_word(5, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 28; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 1) && (get_gpr(2) == 2) && (get_gpr(3) == 3) && (get_gpr(4) == 4));
    end_test(test_passed, $sformatf("x1=%0d, x2=%0d, x3=%0d, x4=%0d", get_gpr(1), get_gpr(2), get_gpr(3), get_gpr(4)));

    // ========================================================================
    // SECTION C: HALF-WORD ACCESS (SH, LH, LHU)
    // ========================================================================

    // TEST 8: SH - Store Half-word at offset 0 and offset 2
    print_test_start(8, "SH: Store half-words at offset 0 and 2");
    init_memory();
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h12300093); // addi x1, x0, 0x123 (imm=12'h123 -> x1 = 0x00000123)
    imem_write_word(2, 32'hfff00113); // addi x2, x0, -1    (imm=12'hFFF -> x2 = 0xFFFFFFFF)
    imem_write_word(3, 32'h00129023); // sh   x1, 0(x5)     (writes 0x0123 to lower half)
    imem_write_word(4, 32'h00229123); // sh   x2, 2(x5)     (writes 0xFFFF to upper half)
    imem_write_word(5, 32'h0002a183); // lw   x3, 0(x5)
    imem_write_word(6, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 28; cycle_count++) @(posedge clk);
    test_passed = (dut.D_wrapper.dmem.memory[0] == 32'hFFFF0123) && (get_gpr(3) == 32'hFFFF0123);
    end_test(test_passed, $sformatf("dmem[0] = 0x%08x (exp 0xFFFF0123)", dut.D_wrapper.dmem.memory[0]));

    // TEST 9: LH - Signed Half-word Load (0x8000 -> 0xFFFF8000)
    print_test_start(9, "LH: Signed half-word load (0x8000 sign-extended)");
    init_memory();
    dmem_write_word(0, 32'h00008000);
    imem_write_word(0, 32'h800082b7); // lui x5, 0x80008
    imem_write_word(1, 32'h00029083); // lh  x1, 0(x5)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'hFFFF8000);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0xFFFF8000)", get_gpr(1)));

    // TEST 10: LHU - Unsigned Half-word Load (0x8000 -> 0x00008000)
    print_test_start(10, "LHU: Unsigned half-word load (0x8000 zero-extended)");
    init_memory();
    dmem_write_word(0, 32'h00008000);
    imem_write_word(0, 32'h800082b7); // lui x5, 0x80008
    imem_write_word(1, 32'h0002d083); // lhu x1, 0(x5)
    imem_write_word(2, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00008000);
    end_test(test_passed, $sformatf("x1 = 0x%08x (exp 0x00008000)", get_gpr(1)));

    // ========================================================================
    // SECTION D: PIPELINE FORWARDING & ORDERING HAZARDS
    // ========================================================================

    // TEST 11: Store-to-Load RAW (SW immediately followed by LW from same address)
    print_test_start(11, "RAW: SW immediately followed by LW from same address");
    init_memory();
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h04200093); // addi x1, x0, 0x42
    imem_write_word(2, 32'h0012a023); // sw   x1, 0(x5)
    imem_write_word(3, 32'h0002a103); // lw   x2, 0(x5)
    imem_write_word(4, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 24; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h42);
    end_test(test_passed, $sformatf("x2 = 0x%08x (exp 0x42)", get_gpr(2)));

    // TEST 12: Load-Use Hazard (LW followed immediately by ADD consuming loaded value)
    print_test_start(12, "Load-Use: LW immediately consumed by ADD");
    init_memory();
    dmem_write_word(0, 32'h00000010);
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083); // lw   x1, 0(x5) (16)
    imem_write_word(2, 32'h00108113); // addi x2, x1, 1 (17)
    imem_write_word(3, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 24; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'd17);
    end_test(test_passed, $sformatf("x2 = %0d (exp 17)", get_gpr(2)));

    // TEST 13: Back-to-back Stores (WAW on DMEM)
    print_test_start(13, "WAW: Back-to-back stores to same address");
    init_memory();
    imem_write_word(0, 32'h800082b7); // lui  x5, 0x80008
    imem_write_word(1, 32'h00100093); // addi x1, x0, 1
    imem_write_word(2, 32'h00200113); // addi x2, x0, 2
    imem_write_word(3, 32'h0012a023); // sw   x1, 0(x5)
    imem_write_word(4, 32'h0022a023); // sw   x2, 0(x5) (Last write wins)
    imem_write_word(5, 32'h0002a183); // lw   x3, 0(x5)
    imem_write_word(6, 32'h00000013); // nop
    reset_core();
    for (cycle_count = 0; cycle_count < 28; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2) && (dut.D_wrapper.dmem.memory[0] == 32'd2);
    end_test(test_passed, $sformatf("x3 = %0d (exp 2)", get_gpr(3)));

    // ========================================================================
    // FINAL BENCHMARK SUMMARY
    // ========================================================================
    print_header("LSU LOAD/STORE BENCHMARK SUMMARY");
    $display("Total Memory Tests:   %0d", total_tests);
    $display("Passed:               %0d", passed_tests);
    $display("Failed:               %0d", failed_tests);
    $display("Success Rate:         %0d%%\n", (passed_tests * 100) / total_tests);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("               ALL LOAD/STORE INSTRUCTION BENCHMARK TESTS PASSED CLEANLY!                                ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                         SOME LOAD/STORE BENCHMARK TESTS FAILED!                                         ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule