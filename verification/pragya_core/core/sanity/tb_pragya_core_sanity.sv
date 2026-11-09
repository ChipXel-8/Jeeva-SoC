`timescale 1ns / 1ps

module tb_pragya_core_sanity;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_TESTS  = 45;

  // ============================================================================
  // SIGNALS & WIRES
  // ============================================================================
  logic clk;
  logic rst;

  logic irq_external; // pg_riscv32_mp_eirq_in
  logic irq_timer;    // pg_riscv32_mp_tirq_in
  logic irq_software; // pg_riscv32_mp_sirq_in
  logic debug_req;    // pg_riscv32_mp_debug_req_in

  // Test tracking counters
  int passed_tests;
  int failed_tests;
  int cycle_count;
  logic test_passed;

  // Trap latches
  logic        have_trap;
  logic [31:0] last_trap_cause;
  logic [31:0] mepc_at_trap;

  // ============================================================================
  // INSTANTIATE DUT (pragya_top)
  // ============================================================================
  pragya_top dut (
    .pg_riscv32_mp_clk_in       (clk),
    .pg_riscv32_mp_rst_in       (rst),
    .pg_riscv32_mp_eirq_in      (irq_external),
    .pg_riscv32_mp_tirq_in      (irq_timer),
    .pg_riscv32_mp_sirq_in      (irq_software),
    .pg_riscv32_mp_debug_req_in (debug_req)
  );

  // ============================================================================
  // CLOCK GENERATOR
  // ============================================================================
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  // ============================================================================
  // HELPER FUNCTIONS & TASKS
  // ============================================================================
  function void init_memory();
    for (int i = 0; i < 8192; i++)  dut.I_wrapper.imem.memory[i] = 32'h00000013; // nop (addi x0, x0, 0)
    for (int i = 0; i < 16384; i++) dut.D_wrapper.dmem.memory[i] = 32'h00000000;
  endfunction

  function void print_header(string title);
    $display("");
    $display("=========================================================================================================");
    $display("  %s", title);
    $display("=========================================================================================================");
    $display("");
  endfunction

  function void print_test_start(int num, string name);
    $display("---------------------------------------------------------------------------------------------------------");
    $display("  TEST %2d: %s", num, name);
    $display("---------------------------------------------------------------------------------------------------------");
  endfunction

  function void print_pass(string msg);
    $display("   [PASS] %s", msg);
  endfunction

  function void print_fail(string msg);
    $display("   [FAIL] %s", msg);
  endfunction

  function void end_test(logic passed);
    if (passed) begin
      $display("   *** TEST PASSED ***\n");
      passed_tests++;
    end else begin
      $display("   *** TEST FAILED ***\n");
      failed_tests++;
    end
  endfunction

  task automatic reset_core();
  begin
    rst          = 1'b1;
    irq_software = 1'b0;
    irq_timer    = 1'b0;
    irq_external = 1'b0;
    debug_req    = 1'b0;
    have_trap    = 1'b0;

    #(3 * CLK_PERIOD);
    @(posedge clk);
    rst = 1'b0;
    repeat (6) @(posedge clk);
  end
  endtask

  // Trap monitor
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      last_trap_cause <= 32'd0;
      have_trap       <= 1'b0;
      mepc_at_trap    <= 32'd0;
    end else if (dut.CORE.trap_detected_out) begin
      last_trap_cause <= {dut.CORE.i_or_e_out, 27'd0, dut.CORE.cause_out};
      mepc_at_trap    <= dut.CORE.pc_out;
      have_trap       <= 1'b1;
    end
  end

  // ============================================================================
  // MAIN TEST PROCEDURE
  // ============================================================================
  initial begin
    passed_tests = 0;
    failed_tests = 0;

    print_header("PRAGYA RV32IM M-MODE SANITY TEST SUITE");

    // Initial reset
    rst = 1'b1;
    #30;
    rst = 1'b0;
    @(posedge clk);

    // ========================================================================
    // TEST 1: ADDI - Add Immediate
    // ========================================================================
    print_test_start(1, "ADDI - Add Immediate (x1 = 0 + 5)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00500093;  // addi x1, x0, 5
    dut.I_wrapper.imem.memory[1] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 15; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h00000005);
    if (test_passed) print_pass("x1 = 0x00000005");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x00000005)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 2: ADD - Register Addition
    // ========================================================================
    print_test_start(2, "ADD - Register Addition (x4 = x1 + x2)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00500093;  // addi x1, x0, 5
    dut.I_wrapper.imem.memory[1] = 32'h00300113;  // addi x2, x0, 3
    dut.I_wrapper.imem.memory[2] = 32'h00208233;  // add  x4, x1, x2 (5 + 3 = 8)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 15; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[4] == 32'h00000008);
    if (test_passed) print_pass("x4 = 0x00000008 (5 + 3)");
    else print_fail($sformatf("x4 = 0x%08x (expected 0x00000008)", dut.CORE.regfile_inst.regfile[4]));
    end_test(test_passed);

    // ========================================================================
    // TEST 3: SUB - Register Subtraction
    // ========================================================================
    print_test_start(3, "SUB - Register Subtraction (x4 = x1 - x2)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00a00093;  // addi x1, x0, 10
    dut.I_wrapper.imem.memory[1] = 32'h00300113;  // addi x2, x0, 3
    dut.I_wrapper.imem.memory[2] = 32'h40208233;  // sub  x4, x1, x2 (10 - 3 = 7)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 15; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[4] == 32'h00000007);
    if (test_passed) print_pass("x4 = 0x00000007 (10 - 3)");
    else print_fail($sformatf("x4 = 0x%08x (expected 0x00000007)", dut.CORE.regfile_inst.regfile[4]));
    end_test(test_passed);

    // ========================================================================
    // TEST 4: LUI - Load Upper Immediate
    // ========================================================================
    print_test_start(4, "LUI - Load Upper Immediate (x1 = 0x12345000)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h123450b7;  // lui x1, 0x12345
    dut.I_wrapper.imem.memory[1] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 12; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h12345000);
    if (test_passed) print_pass("x1 = 0x12345000");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x12345000)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 5: AUIPC - Add Upper Immediate to PC (Reset PC = 0x80000000)
    // ========================================================================
    print_test_start(5, "AUIPC - Add Upper Immediate to PC");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h10000097;  // auipc x1, 0x10000 (0x80000000 + 0x10000000 = 0x90000000)
    dut.I_wrapper.imem.memory[1] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 12; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h90000000);
    if (test_passed) print_pass("x1 = 0x90000000 (0x80000000 + 0x10000000)");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x90000000)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 6: SW - Store Word to DMEM (Base 0x80008000)
    // ========================================================================
    print_test_start(6, "SW - Store Word (dmem[0] = x1)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h800082b7;  // lui x5, 0x80008 (DMEM base)
    dut.I_wrapper.imem.memory[1] = 32'h00500093;  // addi x1, x0, 5
    dut.I_wrapper.imem.memory[2] = 32'h0012a023;  // sw   x1, 0(x5)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);

    test_passed = (dut.D_wrapper.dmem.memory[0] == 32'h00000005);
    if (test_passed) print_pass("dmem[0] = 0x00000005");
    else print_fail($sformatf("dmem[0] = 0x%08x (expected 0x00000005)", dut.D_wrapper.dmem.memory[0]));
    end_test(test_passed);

    // ========================================================================
    // TEST 7: LW - Load Word from DMEM
    // ========================================================================
    print_test_start(7, "LW - Load Word (x1 = dmem[0])");
    init_memory();
    dut.D_wrapper.dmem.memory[0] = 32'h12345678;
    dut.I_wrapper.imem.memory[0] = 32'h800082b7;  // lui x5, 0x80008 (DMEM base)
    dut.I_wrapper.imem.memory[1] = 32'h0002a083;  // lw  x1, 0(x5)
    dut.I_wrapper.imem.memory[2] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h12345678);
    if (test_passed) print_pass("x1 = 0x12345678");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x12345678)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 8: SH - Store Half-word
    // ========================================================================
    print_test_start(8, "SH - Store Half-word (dmem[0][15:0] = 0xFFFF)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h800082b7;  // lui  x5, 0x80008
    dut.I_wrapper.imem.memory[1] = 32'hffff0093;  // addi x1, x0, -1
    dut.I_wrapper.imem.memory[2] = 32'h00129023;  // sh   x1, 0(x5)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);

    test_passed = (dut.D_wrapper.dmem.memory[0][15:0] == 16'hFFFF);
    if (test_passed) print_pass("dmem[0][15:0] = 0xFFFF");
    else print_fail($sformatf("dmem[0][15:0] = 0x%04x (expected 0xFFFF)", dut.D_wrapper.dmem.memory[0][15:0]));
    end_test(test_passed);

    // ========================================================================
    // TEST 9: SB - Store Byte
    // ========================================================================
    print_test_start(9, "SB - Store Byte (dmem[0][7:0] = 0xAB)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h800082b7;  // lui  x5, 0x80008
    dut.I_wrapper.imem.memory[1] = 32'h0ab00093;  // addi x1, x0, 0xAB
    dut.I_wrapper.imem.memory[2] = 32'h00128023;  // sb   x1, 0(x5)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);

    test_passed = (dut.D_wrapper.dmem.memory[0][7:0] == 8'hAB);
    if (test_passed) print_pass("dmem[0][7:0] = 0xAB");
    else print_fail($sformatf("dmem[0][7:0] = 0x%02x (expected 0xAB)", dut.D_wrapper.dmem.memory[0][7:0]));
    end_test(test_passed);

    // ========================================================================
    // TEST 10: BEQ - Branch if Equal
    // ========================================================================
    print_test_start(10, "BEQ - Branch if Equal (Taken)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00500093;  // addi x1, x0, 5
    dut.I_wrapper.imem.memory[1] = 32'h00500113;  // addi x2, x0, 5
    dut.I_wrapper.imem.memory[2] = 32'h00208463;  // beq  x1, x2, +8
    dut.I_wrapper.imem.memory[3] = 32'h00100093;  // addi x1, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[4] = 32'h00200093;  // addi x1, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[5] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h00000002);
    if (test_passed) print_pass("Branch taken, x1 = 0x00000002");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x00000002)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 11: BNE - Branch if Not Equal
    // ========================================================================
    print_test_start(11, "BNE - Branch if Not Equal (Taken)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00500093;  // addi x1, x0, 5
    dut.I_wrapper.imem.memory[1] = 32'h00300113;  // addi x2, x0, 3
    dut.I_wrapper.imem.memory[2] = 32'h00209463;  // bne  x1, x2, +8
    dut.I_wrapper.imem.memory[3] = 32'h00100093;  // addi x1, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[4] = 32'h00200093;  // addi x1, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[5] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h00000002);
    if (test_passed) print_pass("Branch taken, x1 = 0x00000002");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x00000002)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 12: JAL - Jump and Link (Return Address = 0x80000004)
    // ========================================================================
    print_test_start(12, "JAL - Jump and Link (x1 = return address)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h008000ef;  // jal  x1, +8
    dut.I_wrapper.imem.memory[1] = 32'h00100113;  // addi x2, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[2] = 32'h00200193;  // addi x3, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h80000004) &&
                  (dut.CORE.regfile_inst.regfile[3] == 32'h00000002);
    if (test_passed) print_pass("x1 = 0x80000004 (return address), x3 = 2");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x80000004)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 13: JALR - Jump and Link Register
    // ========================================================================
    print_test_start(13, "JALR - Jump and Link Register");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h800000b7;  // lui  x1, 0x80000
    dut.I_wrapper.imem.memory[1] = 32'h00c08093;  // addi x1, x1, 0xC (0x8000000C -> index 3)
    dut.I_wrapper.imem.memory[2] = 32'h00008167;  // jalr x2, 0(x1)
    dut.I_wrapper.imem.memory[3] = 32'h00400193;  // addi x3, x0, 4 (TARGET)
    dut.I_wrapper.imem.memory[4] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[2] == 32'h8000000C) &&
                  (dut.CORE.regfile_inst.regfile[3] == 32'h00000004);
    if (test_passed) print_pass("x2 = 0x8000000C (return address), x3 = 4");
    else print_fail($sformatf("x2 = 0x%08x, x3 = 0x%08x", dut.CORE.regfile_inst.regfile[2], dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 14: Load-Use Hazard Resolution
    // ========================================================================
    print_test_start(14, "Load-Use Hazard (Pipeline stall & forwarding)");
    init_memory();
    dut.D_wrapper.dmem.memory[0] = 32'h00000007;
    dut.I_wrapper.imem.memory[0] = 32'h800082b7;  // lui  x5, 0x80008 (DMEM base)
    dut.I_wrapper.imem.memory[1] = 32'h0002a083;  // lw   x1, 0(x5)
    dut.I_wrapper.imem.memory[2] = 32'h00108093;  // addi x1, x1, 1 (Immediately consumes x1)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[1] == 32'h00000008);
    if (test_passed) print_pass("x1 = 0x00000008 (load-use hazard handled)");
    else print_fail($sformatf("x1 = 0x%08x (expected 0x00000008)", dut.CORE.regfile_inst.regfile[1]));
    end_test(test_passed);

    // ========================================================================
    // TEST 15: Complex Program (Fibonacci 5)
    // ========================================================================
    print_test_start(15, "Complex Program - Calculate Fibonacci(5)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00100093;  // addi x1, x0, 1
    dut.I_wrapper.imem.memory[1] = 32'h00100113;  // addi x2, x0, 1
    dut.I_wrapper.imem.memory[2] = 32'h001101b3;  // add  x3, x2, x1 (2)
    dut.I_wrapper.imem.memory[3] = 32'h00218233;  // add  x4, x3, x2 (3)
    dut.I_wrapper.imem.memory[4] = 32'h003202b3;  // add  x5, x4, x3 (5)
    dut.I_wrapper.imem.memory[5] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[5] == 32'h00000005);
    if (test_passed) print_pass("x5 = 0x00000005 (fibonacci(5))");
    else print_fail($sformatf("x5 = 0x%08x (expected 0x00000005)", dut.CORE.regfile_inst.regfile[5]));
    end_test(test_passed);

    // ========================================================================
    // TEST 16: ALU Logic Ops (AND, OR, XOR)
    // ========================================================================
    print_test_start(16, "ALU Bitwise Operations (AND, OR, XOR)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00f00093;  // addi x1, x0, 0x0F
    dut.I_wrapper.imem.memory[1] = 32'h03300113;  // addi x2, x0, 0x33
    dut.I_wrapper.imem.memory[2] = 32'h0020f1b3;  // and  x3, x1, x2 (0x03)
    dut.I_wrapper.imem.memory[3] = 32'h0020e233;  // or   x4, x1, x2 (0x3F)
    dut.I_wrapper.imem.memory[4] = 32'h0020c2b3;  // xor  x5, x1, x2 (0x3C)
    dut.I_wrapper.imem.memory[5] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'h03) &&
                  (dut.CORE.regfile_inst.regfile[4] == 32'h3F) &&
                  (dut.CORE.regfile_inst.regfile[5] == 32'h3C);
    if (test_passed) print_pass("Bitwise ops: AND=0x03, OR=0x3F, XOR=0x3C");
    else print_fail("Bitwise mismatch");
    end_test(test_passed);

    // ========================================================================
    // TEST 17: Shift Operations (SLL, SRL, SRA)
    // ========================================================================
    print_test_start(17, "Shift Operations (SLL, SRL, SRA)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hff000093;  // addi x1, x0, -16 (0xFFFFFFF0)
    dut.I_wrapper.imem.memory[1] = 32'h00209113;  // slli x2, x1, 2   (0xFFFFFFC0)
    dut.I_wrapper.imem.memory[2] = 32'h0040d193;  // srli x3, x1, 4   (0x0FFFFFFF)
    dut.I_wrapper.imem.memory[3] = 32'h4040d213;  // srai x4, x1, 4   (0xFFFFFFFF)
    dut.I_wrapper.imem.memory[4] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[2] == 32'hFFFFFFC0) &&
                  (dut.CORE.regfile_inst.regfile[3] == 32'h0FFFFFFF) &&
                  (dut.CORE.regfile_inst.regfile[4] == 32'hFFFFFFFF);
    if (test_passed) print_pass("SLLI=0xFFFFFFC0, SRLI=0x0FFFFFFF, SRAI=0xFFFFFFFF");
    else print_fail("Shift mismatch");
    end_test(test_passed);

    // ========================================================================
    // TEST 18: Comparisons (SLT, SLTU)
    // ========================================================================
    print_test_start(18, "Set Less Than Signed & Unsigned (SLT, SLTU)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00093;  // addi x1, x0, -1
    dut.I_wrapper.imem.memory[1] = 32'h00100113;  // addi x2, x0, 1
    dut.I_wrapper.imem.memory[2] = 32'h0020a1b3;  // slt  x3, x1, x2 (-1 < 1 signed -> 1)
    dut.I_wrapper.imem.memory[3] = 32'h0020b233;  // sltu x4, x1, x2 (0xFFFFFFFF < 1 unsigned -> 0)
    dut.I_wrapper.imem.memory[4] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd1) &&
                  (dut.CORE.regfile_inst.regfile[4] == 32'd0);
    if (test_passed) print_pass("slt=1, sltu=0");
    else print_fail($sformatf("slt=%0d sltu=%0d", dut.CORE.regfile_inst.regfile[3], dut.CORE.regfile_inst.regfile[4]));
    end_test(test_passed);

    // ========================================================================
    // TEST 19: Unaligned Load/Store (LBU, SB)
    // ========================================================================
    print_test_start(19, "LSU Byte Alignment Offsets");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h800082b7;  // lui  x5, 0x80008
    dut.I_wrapper.imem.memory[1] = 32'h03400093;  // addi x1, x0, 0x34
    dut.I_wrapper.imem.memory[2] = 32'h001280a3;  // sb   x1, 1(x5) -> byte 1
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop
    dut.I_wrapper.imem.memory[4] = 32'h0012c103;  // lbu  x2, 1(x5)
    dut.I_wrapper.imem.memory[5] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[2] == 32'h00000034);
    if (test_passed) print_pass("LBU offset 1 = 0x34");
    else print_fail($sformatf("x2 = 0x%08x (expected 0x34)", dut.CORE.regfile_inst.regfile[2]));
    end_test(test_passed);

    // ========================================================================
    // TEST 20: MUL - Basic Multiply
    // ========================================================================
    print_test_start(20, "MUL - 6 * 7 = 42");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00600093;  // addi x1, x0, 6
    dut.I_wrapper.imem.memory[1] = 32'h00700113;  // addi x2, x0, 7
    dut.I_wrapper.imem.memory[2] = 32'h022081b3;  // mul  x3, x1, x2 (funct7=0000001, funct3=000)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd42);
    if (test_passed) print_pass("x3 = 42");
    else print_fail($sformatf("x3 = %0d (expected 42)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 21: MULH - High 32 bits of Signed Multiply
    // ========================================================================
    print_test_start(21, "MULH - Signed High-Half Multiply");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00093;  // addi x1, x0, -1
    dut.I_wrapper.imem.memory[1] = 32'h00200113;  // addi x2, x0, 2
    dut.I_wrapper.imem.memory[2] = 32'h022091b3;  // mulh x3, x1, x2 (funct3=001)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'hFFFFFFFF);
    if (test_passed) print_pass("x3 = 0xFFFFFFFF (high half of -1 * 2)");
    else print_fail($sformatf("x3 = 0x%08x (expected FFFFFFFF)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 22: MULHU - High 32 bits of Unsigned Multiply
    // ========================================================================
    print_test_start(22, "MULHU - Unsigned High-Half Multiply");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00093;  // addi  x1, x0, -1 (0xFFFFFFFF)
    dut.I_wrapper.imem.memory[1] = 32'hfff00113;  // addi  x2, x0, -1 (0xFFFFFFFF)
    dut.I_wrapper.imem.memory[2] = 32'h0220b1b3;  // mulhu x3, x1, x2 (funct3=011)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'hFFFFFFFE);
    if (test_passed) print_pass("x3 = 0xFFFFFFFE");
    else print_fail($sformatf("x3 = 0x%08x (expected FFFFFFFE)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 23: MULHSU - Signed-Unsigned High-Half Multiply
    // ========================================================================
    print_test_start(23, "MULHSU - Signed x Unsigned High-Half Multiply");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00093;  // addi   x1, x0, -1 (signed -1)
    dut.I_wrapper.imem.memory[1] = 32'h00200113;  // addi   x2, x0, 2  (unsigned 2)
    dut.I_wrapper.imem.memory[2] = 32'h0220a1b3;  // mulhsu x3, x1, x2 (funct3=010)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'hFFFFFFFF);
    if (test_passed) print_pass("x3 = 0xFFFFFFFF (high half of -1 * 2u)");
    else print_fail($sformatf("x3 = 0x%08x (expected FFFFFFFF)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 24: DIV - Signed Division
    // ========================================================================
    print_test_start(24, "DIV - Signed Divide: 20 / -3 = -6");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h01400093;  // addi x1, x0, 20
    dut.I_wrapper.imem.memory[1] = 32'hffd00113;  // addi x2, x0, -3
    dut.I_wrapper.imem.memory[2] = 32'h0220c1b3;  // div  x3, x1, x2 (funct3=100)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == -6);
    if (test_passed) print_pass("x3 = -6");
    else print_fail($sformatf("x3 = %0d (expected -6)", $signed(dut.CORE.regfile_inst.regfile[3])));
    end_test(test_passed);

    // ========================================================================
    // TEST 25: DIVU - Unsigned Division
    // ========================================================================
    print_test_start(25, "DIVU - Unsigned Divide: 20 / 6 = 3");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h01400093;  // addi x1, x0, 20
    dut.I_wrapper.imem.memory[1] = 32'h00600113;  // addi x2, x0, 6
    dut.I_wrapper.imem.memory[2] = 32'h0220d1b3;  // divu x3, x1, x2 (funct3=101)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 3);
    if (test_passed) print_pass("x3 = 3");
    else print_fail($sformatf("x3 = %0d (expected 3)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 26: REM - Signed Remainder
    // ========================================================================
    print_test_start(26, "REM - Signed Remainder: 20 % -3 = 2");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h01400093;  // addi x1, x0, 20
    dut.I_wrapper.imem.memory[1] = 32'hffd00113;  // addi x2, x0, -3
    dut.I_wrapper.imem.memory[2] = 32'h0220e1b3;  // rem  x3, x1, x2 (funct3=110)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 2);
    if (test_passed) print_pass("x3 = 2");
    else print_fail($sformatf("x3 = %0d (expected 2)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 27: REMU - Unsigned Remainder
    // ========================================================================
    print_test_start(27, "REMU - Unsigned Remainder: 20 % 6 = 2");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h01400093;  // addi x1, x0, 20
    dut.I_wrapper.imem.memory[1] = 32'h00600113;  // addi x2, x0, 6
    dut.I_wrapper.imem.memory[2] = 32'h0220f1b3;  // remu x3, x1, x2 (funct3=111)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd2);
    if (test_passed) print_pass("x3 = 2");
    else print_fail($sformatf("x3 = %0d (expected 2)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 28: Division by Zero Corner Cases (x / 0 = -1, x % 0 = x)
    // ========================================================================
    print_test_start(28, "M-Extension Division by Zero Determinism");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00700093;  // addi x1, x0, 7
    dut.I_wrapper.imem.memory[1] = 32'h0200c133;  // div  x2, x1, x0 (7 / 0 = -1)
    dut.I_wrapper.imem.memory[2] = 32'h00000013;  // nop
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop
    dut.I_wrapper.imem.memory[4] = 32'h0200e1b3;  // rem  x3, x1, x0 (7 % 0 = 7)
    dut.I_wrapper.imem.memory[5] = 32'h00000013;  // nop
    dut.I_wrapper.imem.memory[6] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 70; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[2] == 32'hFFFFFFFF) &&
                  (dut.CORE.regfile_inst.regfile[3] == 32'd7);
    if (test_passed) print_pass("div(x2) = 0xFFFFFFFF, rem(x3) = 7");
    else print_fail($sformatf("x2 = 0x%08x, x3 = %0d", dut.CORE.regfile_inst.regfile[2], dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 29: Signed Division Overflow (-2147483648 / -1)
    // ========================================================================
    print_test_start(29, "Signed Division Overflow (-2147483648 / -1 = -2147483648)");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h800000b7;  // lui  x1, 0x80000 (0x80000000 = -2147483648)
    dut.I_wrapper.imem.memory[1] = 32'hfff00113;  // addi x2, x0, -1
    dut.I_wrapper.imem.memory[2] = 32'h0220c1b3;  // div  x3, x1, x2 (overflow corner)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 55; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'h80000000);
    if (test_passed) print_pass("x3 = 0x80000000 (Signed Overflow Handled)");
    else print_fail($sformatf("x3 = 0x%08x (expected 0x80000000)", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 30: CSR - CSRRW on mstatus (Set MIE via bit 3 = 8)
    // ========================================================================
    print_test_start(30, "CSR - CSRRW on mstatus");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00800093;  // addi  x1, x0, 8 (MIE is bit 3)
    dut.I_wrapper.imem.memory[1] = 32'h30009173;  // csrrw x2, mstatus, x1
    dut.I_wrapper.imem.memory[2] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mie_out == 1'b1);
    if (test_passed) print_pass("mstatus MIE updated to 1 (mie_out = 1)");
    else print_fail($sformatf("mstatus_out = 0x%08x, mie_out = %b", dut.CORE.csr_inst.mstatus_out, dut.CORE.csr_inst.mie_out));
    end_test(test_passed);

    // ========================================================================
    // TEST 31: CSR - CSRRWI / CSRRS on mie
    // ========================================================================
    print_test_start(31, "CSR - CSRRWI / CSRRS on mie");
    init_memory();
    // mie register accepts supported bits: 0x888 (MEIE bit 11, MTIE bit 7, MSIE bit 3)
    dut.I_wrapper.imem.memory[0] = 32'h00800093;  // addi  x1, x0, 8 (MSIE bit 3)
    dut.I_wrapper.imem.memory[1] = 32'h30409173;  // csrrw x2, mie, x1
    dut.I_wrapper.imem.memory[2] = 32'h30402273;  // csrrs x4, mie, x0 (read only)
    dut.I_wrapper.imem.memory[3] = 32'h00000013;  // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 20; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mie == 32'h00000008) &&
                  (dut.CORE.regfile_inst.regfile[4] == 32'h00000008);
    if (test_passed) print_pass("mie = 0x00000008, x4 = 0x00000008");
    else print_fail($sformatf("mie = 0x%08x, x4 = 0x%08x", dut.CORE.csr_inst.mie, dut.CORE.regfile_inst.regfile[4]));
    end_test(test_passed);

    // ========================================================================
    // TEST 32: Trap Flow: ECALL -> mtvec handler -> MRET back to main
    // ========================================================================
    print_test_start(32, "Trap Flow: ECALL to mtvec handler and back with MRET");
    init_memory();
    // mtvec handler at 0x80000040 (word index 16):
    dut.I_wrapper.imem.memory[16] = 32'h0aa00193; // addi  x3, x0, 0xAA (mark handler ran)
    dut.I_wrapper.imem.memory[17] = 32'h34102273; // csrrs x4, mepc, x0 (read mepc)
    dut.I_wrapper.imem.memory[18] = 32'h00420213; // addi  x4, x4, 4    (advance mepc by 4)
    dut.I_wrapper.imem.memory[19] = 32'h34121073; // csrrw x0, mepc, x4 (update mepc)
    dut.I_wrapper.imem.memory[20] = 32'h30200073; // mret

    // Main Program:
    dut.I_wrapper.imem.memory[0]  = 32'h800000b7; // lui   x1, 0x80000
    dut.I_wrapper.imem.memory[1]  = 32'h04008093; // addi  x1, x1, 0x40
    dut.I_wrapper.imem.memory[2]  = 32'h30509073; // csrrw x0, mtvec, x1 (mtvec = 0x80000040)
    dut.I_wrapper.imem.memory[3]  = 32'h00000073; // ecall (at PC = 0x8000000C)
    dut.I_wrapper.imem.memory[4]  = 32'h00700293; // addi  x5, x0, 7    (runs AFTER mret)
    dut.I_wrapper.imem.memory[5]  = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mcause == 32'd11) &&
                  (dut.CORE.regfile_inst.regfile[3] == 32'hAA) &&
                  (dut.CORE.regfile_inst.regfile[5] == 32'd7);
    if (test_passed) print_pass("ECALL cause=11, handler ran (x3=0xAA), returned (x5=7)");
    else print_fail($sformatf("mcause=%0d x3=0x%02x x5=%0d", dut.CORE.csr_inst.mcause, dut.CORE.regfile_inst.regfile[3], dut.CORE.regfile_inst.regfile[5]));
    end_test(test_passed);

    // ========================================================================
    // TEST 33: Synchronous Trap: EBREAK Exception
    // ========================================================================
    print_test_start(33, "Synchronous Exception: EBREAK (mcause = 3)");
    init_memory();
    dut.I_wrapper.imem.memory[16] = 32'h0bb00193; // addi x3, x0, 0xBB
    dut.I_wrapper.imem.memory[17] = 32'h30200073; // mret

    dut.I_wrapper.imem.memory[0]  = 32'h800000b7; // lui   x1, 0x80000
    dut.I_wrapper.imem.memory[1]  = 32'h04008093; // addi  x1, x1, 0x40
    dut.I_wrapper.imem.memory[2]  = 32'h30509073; // csrrw x0, mtvec, x1
    dut.I_wrapper.imem.memory[3]  = 32'h00100073; // ebreak
    dut.I_wrapper.imem.memory[4]  = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mcause == 32'd3) &&
                  (dut.CORE.regfile_inst.regfile[3] == 32'hBB);
    if (test_passed) print_pass("EBREAK cause=3, handler executed");
    else print_fail($sformatf("mcause = %0d", dut.CORE.csr_inst.mcause));
    end_test(test_passed);

    // ========================================================================
    // TEST 34: Interrupt Blocked when MSTATUS.MIE = 0
    // ========================================================================
    print_test_start(34, "Interrupt Blocked when MSTATUS.MIE = 0");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h80000193; // addi  x3, x0, 2048 (MEIE bit 11)
    dut.I_wrapper.imem.memory[1] = 32'h30419073; // csrrw x0, mie, x3
    dut.I_wrapper.imem.memory[2] = 32'h00000013; // nop

    reset_core();
    irq_external = 1'b1;
    for (cycle_count = 0; cycle_count < 25; cycle_count++) @(posedge clk);

    test_passed = (have_trap == 1'b0);
    if (test_passed) print_pass("No interrupt taken when MSTATUS.MIE=0");
    else print_fail("Interrupt taken incorrectly when MSTATUS.MIE=0");
    end_test(test_passed);

    // ========================================================================
    // TEST 35: External Interrupt Fires when MIE = 1
    // ========================================================================
    print_test_start(35, "External Interrupt Fires when MIE=1 and MEIE=1");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00800093; // addi  x1, x0, 8 (MIE bit)
    dut.I_wrapper.imem.memory[1] = 32'h30009073; // csrrw x0, mstatus, x1
    dut.I_wrapper.imem.memory[2] = 32'h80000113; // addi  x2, x0, 2048 (MEIE bit 11)
    dut.I_wrapper.imem.memory[3] = 32'h30411073; // csrrw x0, mie, x2
    dut.I_wrapper.imem.memory[4] = 32'h00000013; // nop

    reset_core();
    irq_external = 1'b1;
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mcause == 32'h8000000B);
    if (test_passed) print_pass("External interrupt taken, mcause=0x8000000B");
    else print_fail($sformatf("mcause=0x%08x", dut.CORE.csr_inst.mcause));
    end_test(test_passed);

    // ========================================================================
    // TEST 36: Interrupt Priority: MEIP > MSIP > MTIP
    // ========================================================================
    print_test_start(36, "Interrupt Priority: MEIP > MSIP > MTIP");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00800093; // addi  x1, x0, 8 (MIE)
    dut.I_wrapper.imem.memory[1] = 32'h30009073; // csrrw x0, mstatus, x1
    dut.I_wrapper.imem.memory[2] = 32'hfff00113; // addi  x2, x0, 0xFFF
    dut.I_wrapper.imem.memory[3] = 32'h30411073; // csrrw x0, mie, x2
    dut.I_wrapper.imem.memory[4] = 32'h00000013; // nop

    reset_core();
    // Assert all 3 interrupts simultaneously
    irq_external = 1'b1;
    irq_software = 1'b1;
    irq_timer    = 1'b1;
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mcause == 32'h8000000B); // MEIP must win
    if (test_passed) print_pass("MEIP correctly prioritized over MSIP and MTIP");
    else print_fail($sformatf("mcause=0x%08x (expected 0x8000000B)", dut.CORE.csr_inst.mcause));
    end_test(test_passed);

    // ========================================================================
    // TEST 37: MSIP Interrupt (Software Interrupt)
    // ========================================================================
    print_test_start(37, "MSIP Interrupt: mcause = 0x80000003");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00800093; // addi  x1, x0, 8
    dut.I_wrapper.imem.memory[1] = 32'h30009073; // csrrw x0, mstatus, x1
    dut.I_wrapper.imem.memory[2] = 32'h00800113; // addi  x2, x0, 8 (MSIE bit 3)
    dut.I_wrapper.imem.memory[3] = 32'h30411073; // csrrw x0, mie, x2
    dut.I_wrapper.imem.memory[4] = 32'h00000013; // nop

    reset_core();
    irq_software = 1'b1;
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mcause == 32'h80000003);
    if (test_passed) print_pass("MSIP interrupt verified (mcause=0x80000003)");
    else print_fail($sformatf("mcause=0x%08x", dut.CORE.csr_inst.mcause));
    end_test(test_passed);

    // ========================================================================
    // TEST 38: MTIP Interrupt (Timer Interrupt)
    // ========================================================================
    print_test_start(38, "MTIP Interrupt: mcause = 0x80000007");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00800093; // addi  x1, x0, 8
    dut.I_wrapper.imem.memory[1] = 32'h30009073; // csrrw x0, mstatus, x1
    dut.I_wrapper.imem.memory[2] = 32'h08000113; // addi  x2, x0, 0x80 (MTIE bit 7)
    dut.I_wrapper.imem.memory[3] = 32'h30411073; // csrrw x0, mie, x2
    dut.I_wrapper.imem.memory[4] = 32'h00000013; // nop

    reset_core();
    irq_timer = 1'b1;
    for (cycle_count = 0; cycle_count < 30; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.csr_inst.mcause == 32'h80000007);
    if (test_passed) print_pass("MTIP interrupt verified (mcause=0x80000007)");
    else print_fail($sformatf("mcause=0x%08x", dut.CORE.csr_inst.mcause));
    end_test(test_passed);

    // ========================================================================
    // TEST 39: Interrupt Returns Correctly via MRET
    // ========================================================================
    print_test_start(39, "Interrupt -> Handler -> MRET back to Main");
    init_memory();
    // Handler at 0x80000040:
    dut.I_wrapper.imem.memory[16] = 32'h09900213; // addi x4, x0, 0x99
    dut.I_wrapper.imem.memory[17] = 32'h30200073; // mret

    // Main:
    dut.I_wrapper.imem.memory[0]  = 32'h800000b7; // lui   x1, 0x80000
    dut.I_wrapper.imem.memory[1]  = 32'h04008093; // addi  x1, x1, 0x40
    dut.I_wrapper.imem.memory[2]  = 32'h30509073; // csrrw x0, mtvec, x1
    dut.I_wrapper.imem.memory[3]  = 32'h00800113; // addi  x2, x0, 8
    dut.I_wrapper.imem.memory[4]  = 32'h30011073; // csrrw x0, mstatus, x2
    dut.I_wrapper.imem.memory[5]  = 32'h80000193; // addi  x3, x0, 2048
    dut.I_wrapper.imem.memory[6]  = 32'h30419073; // csrrw x0, mie, x3
    dut.I_wrapper.imem.memory[7]  = 32'h00a00293; // addi  x5, x0, 10 (Executed after MRET)
    dut.I_wrapper.imem.memory[8]  = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 18; cycle_count++) @(posedge clk);
    irq_external = 1'b1;
    for (cycle_count = 0; cycle_count < 5; cycle_count++) @(posedge clk);
    irq_external = 1'b0;
    for (cycle_count = 0; cycle_count < 35; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[4] == 32'h99) &&
                  (dut.CORE.regfile_inst.regfile[5] == 32'd10);
    if (test_passed) print_pass("Returned via MRET and resumed execution (x4=0x99, x5=10)");
    else print_fail($sformatf("x4 = 0x%08x, x5 = 0x%08x", dut.CORE.regfile_inst.regfile[4], dut.CORE.regfile_inst.regfile[5]));
    end_test(test_passed);

    // ========================================================================
    // TEST 40: Low-Power WFI Sleep & Wakeup via Software Interrupt (MSIE / SIRQ)
    // ========================================================================
    print_test_start(40, "WFI Sleep Freeze & Wakeup via Software Interrupt");
    init_memory();

    // ------------------------------------------------------------------------
    // ISR at mtvec = 0x80000040 (word index 16):
    // 1. Mark x6 = 0x77 (confirm ISR ran)
    // 2. Read mepc, add 4 (to skip past the WFI instruction), write back mepc
    // 3. mret (returns to 0x80000020 -> addi x7, x0, 1)
    // ------------------------------------------------------------------------
    dut.I_wrapper.imem.memory[16] = 32'h07700313; // addi  x6, x0, 0x77 (ISR execution marker)
    dut.I_wrapper.imem.memory[17] = 32'h34102273; // csrrs x4, mepc, x0 (read mepc)
    dut.I_wrapper.imem.memory[18] = 32'h00420213; // addi  x4, x4, 4    (advance mepc by 4)
    dut.I_wrapper.imem.memory[19] = 32'h34121073; // csrrw x0, mepc, x4 (update mepc)
    dut.I_wrapper.imem.memory[20] = 32'h30200073; // mret

    // ------------------------------------------------------------------------
    // Main Program:
    // ------------------------------------------------------------------------
    // 0x80000000: Setup mtvec = 0x80000040
    dut.I_wrapper.imem.memory[0]  = 32'h800000b7; // lui   x1, 0x80000
    dut.I_wrapper.imem.memory[1]  = 32'h04008093; // addi  x1, x1, 0x40
    dut.I_wrapper.imem.memory[2]  = 32'h30509073; // csrrw x0, mtvec, x1

    // 0x8000000C: Enable Global Interrupts (mstatus.MIE = bit 3 -> 0x8)
    dut.I_wrapper.imem.memory[3]  = 32'h00800113; // addi  x2, x0, 8
    dut.I_wrapper.imem.memory[4]  = 32'h30011073; // csrrw x0, mstatus, x2

    // 0x80000014: Enable Machine Software Interrupt (mie.MSIE = bit 3 -> 0x8)
    dut.I_wrapper.imem.memory[5]  = 32'h00800193; // addi  x3, x0, 8
    dut.I_wrapper.imem.memory[6]  = 32'h30419073; // csrrw x0, mie, x3

    // 0x8000001C: Put core to Sleep via WFI
    dut.I_wrapper.imem.memory[7]  = 32'h10500073; // wfi

    // 0x80000020: Post-WFI instruction (MUST execute after wakeup and MRET)
    dut.I_wrapper.imem.memory[8]  = 32'h00100393; // addi  x7, x0, 1
    dut.I_wrapper.imem.memory[9]  = 32'h00000013; // nop
    dut.I_wrapper.imem.memory[10] = 32'h00000013; // nop

    reset_core();

    // Run until core reaches and latches WFI sleep state
    for (cycle_count = 0; cycle_count < 28; cycle_count++) begin
      @(posedge clk);
      if (dut.CORE.wfi_stall == 1'b1) break;
    end

    // Verify core is actively sleeping
    test_passed = (dut.CORE.wfi_stall == 1'b1);
    if (test_passed) print_pass("Core successfully entered low-power WFI sleep state");
    else print_fail("Core did not assert wfi_stall");

    // Hold in sleep for 5 cycles to prove it stays frozen
    repeat (5) @(posedge clk);

    // ========================================================================
    // Wake up the core using SOFTWARE INTERRUPT (irq_software = 1)
    // ========================================================================
    irq_software = 1'b1;
    repeat (4) @(posedge clk);
    irq_software = 1'b0;

    // Run clock cycles to let the core:
    // 1. Wake up from WFI
    // 2. Jump to ISR at 0x80000040 (x6 <= 0x77)
    // 3. Increment mepc by 4
    // 4. MRET back to 0x80000020
    // 5. Execute addi x7, x0, 1 (x7 <= 1)
    for (cycle_count = 0; cycle_count < 45; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.wfi_stall == 1'b0) &&
                  (dut.CORE.regfile_inst.regfile[6] == 32'h77) &&
                  (dut.CORE.regfile_inst.regfile[7] == 32'd1);

    if (test_passed)
      print_pass("WFI woke up via Software Interrupt, executed ISR (x6=0x77), and resumed (x7=1)");
    else
      print_fail($sformatf("WFI failure: wfi_stall=%b, ISR x6=0x%02x (exp 0x77), Resumed x7=%0d (exp 1)",
                 dut.CORE.wfi_stall, dut.CORE.regfile_inst.regfile[6], dut.CORE.regfile_inst.regfile[7]));

    end_test(test_passed);

    // ========================================================================
    // TEST 41: Branch Condition: BLT (Branch Less Than - Signed)
    // ========================================================================
    print_test_start(41, "BLT - Branch Less Than Signed");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00093; // addi x1, x0, -1
    dut.I_wrapper.imem.memory[1] = 32'h00500113; // addi x2, x0, 5
    dut.I_wrapper.imem.memory[2] = 32'h0020c463; // blt  x1, x2, +8 (-1 < 5 -> Taken)
    dut.I_wrapper.imem.memory[3] = 32'h00100193; // addi x3, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[4] = 32'h00200193; // addi x3, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[5] = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd2);
    if (test_passed) print_pass("BLT taken: x3 = 2");
    else print_fail($sformatf("x3 = %0d", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 42: Branch Condition: BGE (Branch Greater/Equal - Signed)
    // ========================================================================
    print_test_start(42, "BGE - Branch Greater Than or Equal Signed");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00500093; // addi x1, x0, 5
    dut.I_wrapper.imem.memory[1] = 32'hfff00113; // addi x2, x0, -1
    dut.I_wrapper.imem.memory[2] = 32'h0020d463; // bge  x1, x2, +8 (5 >= -1 -> Taken)
    dut.I_wrapper.imem.memory[3] = 32'h00100193; // addi x3, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[4] = 32'h00200193; // addi x3, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[5] = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd2);
    if (test_passed) print_pass("BGE taken: x3 = 2");
    else print_fail($sformatf("x3 = %0d", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 43: Branch Condition: BLTU (Branch Less Than - Unsigned)
    // ========================================================================
    print_test_start(43, "BLTU - Branch Less Than Unsigned");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'h00200093; // addi x1, x0, 2
    dut.I_wrapper.imem.memory[1] = 32'hfff00113; // addi x2, x0, -1 (0xFFFFFFFF)
    dut.I_wrapper.imem.memory[2] = 32'h0020e463; // bltu x1, x2, +8 (2 < 0xFFFFFFFF -> Taken)
    dut.I_wrapper.imem.memory[3] = 32'h00100193; // addi x3, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[4] = 32'h00200193; // addi x3, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[5] = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd2);
    if (test_passed) print_pass("BLTU taken: x3 = 2");
    else print_fail($sformatf("x3 = %0d", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 44: Branch Condition: BGEU (Branch Greater/Equal - Unsigned)
    // ========================================================================
    print_test_start(44, "BGEU - Branch Greater Than or Equal Unsigned");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00093; // addi x1, x0, -1 (0xFFFFFFFF)
    dut.I_wrapper.imem.memory[1] = 32'h00200113; // addi x2, x0, 2
    dut.I_wrapper.imem.memory[2] = 32'h0020f463; // bgeu x1, x2, +8 (0xFFFFFFFF >= 2 -> Taken)
    dut.I_wrapper.imem.memory[3] = 32'h00100193; // addi x3, x0, 1 (SKIPPED)
    dut.I_wrapper.imem.memory[4] = 32'h00200193; // addi x3, x0, 2 (EXECUTED)
    dut.I_wrapper.imem.memory[5] = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 22; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[3] == 32'd2);
    if (test_passed) print_pass("BGEU taken: x3 = 2");
    else print_fail($sformatf("x3 = %0d", dut.CORE.regfile_inst.regfile[3]));
    end_test(test_passed);

    // ========================================================================
    // TEST 45: x0 Register Hardwired to Zero
    // ========================================================================
    print_test_start(45, "x0 Hardwired to Zero Invariance");
    init_memory();
    dut.I_wrapper.imem.memory[0] = 32'hfff00013; // addi x0, x0, -1 (Attempt write to x0)
    dut.I_wrapper.imem.memory[1] = 32'h00000013; // nop

    reset_core();
    for (cycle_count = 0; cycle_count < 15; cycle_count++) @(posedge clk);

    test_passed = (dut.CORE.regfile_inst.regfile[0] == 32'h00000000);
    if (test_passed) print_pass("x0 remained strictly 0x00000000");
    else print_fail($sformatf("x0 was overwritten: 0x%08x", dut.CORE.regfile_inst.regfile[0]));
    end_test(test_passed);

    // ========================================================================
    // SUMMARY
    // ========================================================================
    print_header("FINAL TEST SUMMARY");
    $display("Total Tests Executed: %0d", NUM_TESTS);
    $display("Passed:               %0d", passed_tests);
    $display("Failed:               %0d", failed_tests);
    $display("");

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                             ALL PRAGYA CORE TESTS PASSED SUCCESSFULLY!                                  ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                                   SOME CORE TESTS FAILED!                                               ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule
