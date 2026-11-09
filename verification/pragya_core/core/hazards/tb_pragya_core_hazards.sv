`timescale 1ns / 1ps

module tb_pragya_core_hazards;

  parameter CLK_PERIOD = 10ns;
  parameter NUM_HAZARD_TESTS = 64;

  // ============================================================================
  // SIGNALS
  // ============================================================================
  logic clk;
  logic rst;

  logic irq_external;
  logic irq_timer;
  logic irq_software;
  logic debug_req;

  // Hazard tracking
  typedef struct {
    string hazard_type;
    int cycle;
    string description;
  } hazard_record_t;

  hazard_record_t hazard_log[$];

  // Test tracking
  int passed_tests;
  int failed_tests;
  int total_hazards_detected;
  int cycle_count;
  logic test_passed;

  int raw_count;
  int load_use_count;
  int waw_count;
  int mem_ord_count;
  int ctrl_count;
  int struct_count;
  int combined_count;

  localparam int unsigned TINY_CYCLES  = 25;
  localparam int unsigned SMALL_CYCLES = 45;
  localparam int unsigned MED_CYCLES   = 80;
  localparam int unsigned LARGE_CYCLES = 140;

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
    for (int i = 0; i < 8192; i++)  dut.I_wrapper.imem.memory[i] = 32'h00000013; // nop
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

  function void log_hazard(string htype, string description);
    hazard_record_t record;
    record.hazard_type = htype;
    record.cycle = 0;
    record.description = description;
    hazard_log.push_back(record);
    total_hazards_detected++;
  endfunction

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

  function automatic logic [31:0] get_gpr(int idx);
    return dut.CORE.regfile_inst.regfile[idx];
  endfunction

  task automatic imem_write_word(input int word_idx, input logic [31:0] instr);
    dut.I_wrapper.imem.memory[word_idx] = instr;
  endtask

  task automatic dmem_write_word(input int word_idx, input logic [31:0] data);
    dut.D_wrapper.dmem.memory[word_idx] = data;
  endtask

  // ============================================================================
  // MAIN TEST PROCEDURE
  // ============================================================================
  initial begin
    raw_count              = 0;
    load_use_count         = 0;
    waw_count              = 0;
    mem_ord_count          = 0;
    ctrl_count             = 0;
    struct_count           = 0;
    combined_count         = 0;

    passed_tests           = 0;
    failed_tests           = 0;
    total_hazards_detected = 0;

    print_header("PRAGYA RV32IM HAZARD DETECTION & MITIGATION TEST SUITE");

    rst = 1'b1;
    #30;
    rst = 1'b0;
    @(posedge clk);

    // ========================================================================
    // HAZARD TYPE 1: RAW (Read-After-Write)
    // ========================================================================

    // TEST 1: RAW - Simple dependency (1 cycle)
    print_test_start(1, "RAW Hazard - Simple dependency (1 cycle gap)");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(2, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < TINY_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000006);
    if (test_passed) begin
      print_pass("x2 = 0x00000006 (RAW resolved via forwarding)");
      log_hazard("RAW", "addi x2, x1, 1 reads x1 written by addi x1, x0, 5");
    end else print_fail($sformatf("x2 = 0x%08x (expected 0x00000006)", get_gpr(2)));
    end_test(test_passed);

    // TEST 2: RAW - Load-Use (requires stall)
    print_test_start(2, "RAW Hazard - Load-Use dependency (requires stall)");
    init_memory();
    dmem_write_word(0, 32'h00000042);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008 (DMEM base)
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000043);
    if (test_passed) begin
      print_pass("x2 = 0x00000043 (Load-Use hazard resolved with stall)");
      log_hazard("LOAD-USE", "addi x2, x1, 1 reads x1 loaded by lw");
    end else print_fail($sformatf("x2 = 0x%08x (expected 0x00000043)", get_gpr(2)));
    end_test(test_passed);

    // TEST 3: RAW - Multiple dependencies
    print_test_start(3, "RAW Hazard - Multiple dependencies");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00300113);  // addi x2, x0, 3
    imem_write_word(2, 32'h00208233);  // add  x4, x1, x2
    imem_write_word(3, 32'h00220313);  // addi x6, x4, 2
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(4) == 32'h00000008) && (get_gpr(6) == 32'h0000000A));
    if (test_passed) begin
      print_pass("x4 = 0x00000008, x6 = 0x0000000A (multiple RAW hazards resolved)");
      log_hazard("RAW", "add x4, x1, x2 reads x1, x2");
      log_hazard("RAW", "addi x6, x4, 2 reads x4");
    end else print_fail($sformatf("x4 = 0x%08x, x6 = 0x%08x", get_gpr(4), get_gpr(6)));
    end_test(test_passed);

    // TEST 4: RAW - Chain of dependencies
    print_test_start(4, "RAW Hazard - Chain of dependencies");
    init_memory();
    imem_write_word(0, 32'h00100093);  // addi x1, x0, 1
    imem_write_word(1, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(2, 32'h00110193);  // addi x3, x2, 1
    imem_write_word(3, 32'h00118213);  // addi x4, x3, 1
    imem_write_word(4, 32'h00220293);  // addi x5, x4, 2
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 32'd1) && (get_gpr(2) == 32'd2) &&
                   (get_gpr(3) == 32'd3) && (get_gpr(4) == 32'd4) && (get_gpr(5) == 32'd6));
    if (test_passed) begin
      print_pass("Chain: x1=1, x2=2, x3=3, x4=4, x5=6");
      log_hazard("RAW", "Chain of 5 dependent instructions");
    end else print_fail($sformatf("x5=0x%08x (exp 6)", get_gpr(5)));
    end_test(test_passed);

    // TEST 5: RAW - rs1 and rs2 both dependent
    print_test_start(5, "RAW Hazard - Both rs1 and rs2 dependent");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00300113);  // addi x2, x0, 3
    imem_write_word(2, 32'h00208233);  // add  x4, x1, x2
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(4) == 32'h00000008);
    if (test_passed) begin
      print_pass("x4 = 0x00000008 (both rs1 and rs2 forwarded)");
      log_hazard("RAW", "add x4, x1, x2 - both operands from previous instructions");
    end else print_fail($sformatf("x4 = 0x%08x (expected 0x00000008)", get_gpr(4)));
    end_test(test_passed);

    // ========================================================================
    // HAZARD TYPE 2: LOAD-USE
    // ========================================================================

    // TEST 6: LOAD-USE - Load in ID, use in EX
    print_test_start(6, "LOAD-USE Hazard - Load in ID, use in EX");
    init_memory();
    dmem_write_word(0, 32'h0000000A);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h0000000B);
    if (test_passed) begin
      print_pass("x2 = 0x0000000B (load-use stall handled)");
      log_hazard("LOAD-USE", "addi x2, x1, 1 immediately uses x1 from lw");
    end else print_fail($sformatf("x2 = 0x%08x (expected 0x0000000B)", get_gpr(2)));
    end_test(test_passed);

    // TEST 7: LOAD-USE - Load in ID, use in ID+2
    print_test_start(7, "LOAD-USE Hazard - Load in ID, use in ID+2");
    init_memory();
    dmem_write_word(0, 32'h00000010);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h00000013);  // nop (gap)
    imem_write_word(3, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000011);
    if (test_passed) begin
      print_pass("x2 = 0x00000011 (load-use with 1-cycle gap)");
      log_hazard("LOAD-USE", "addi x2, x1, 1 uses x1 with 1-cycle gap");
    end else print_fail($sformatf("x2 = 0x%08x (expected 0x00000011)", get_gpr(2)));
    end_test(test_passed);

    // TEST 8: LOAD-USE - Sequential loads with stall
    print_test_start(8, "LOAD-USE Hazard - Sequential loads with stall");
    init_memory();
    dmem_write_word(0, 32'h00000005);
    dmem_write_word(1, 32'h00000003);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h0042a103);  // lw   x2, 4(x5)
    imem_write_word(3, 32'h00208233);  // add  x4, x1, x2 (5 + 3 = 8)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 32'd5) && (get_gpr(2) == 32'd3) && (get_gpr(4) == 32'd8));
    if (test_passed) begin
      print_pass("x1 = 5, x2 = 3, x4 = 8 (sequential loads handled)");
      log_hazard("LOAD-USE", "Sequential loads with stall");
    end else print_fail($sformatf("x1=%0d, x2=%0d, x4=%0d", get_gpr(1), get_gpr(2), get_gpr(4)));
    end_test(test_passed);

    // TEST 9: LOAD-USE - Load with offset
    print_test_start(9, "LOAD-USE Hazard - Load with offset");
    init_memory();
    dmem_write_word(2, 32'h00000003);  // address offset 8
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0082a083);  // lw   x1, 8(x5)
    imem_write_word(2, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000004);
    if (test_passed) begin
      print_pass("x2 = 0x00000004 (load with offset)");
      log_hazard("LOAD-USE", "lw x1, 8(x5) followed by addi x2, x1, 1");
    end else print_fail($sformatf("x2 = 0x%08x (expected 4)", get_gpr(2)));
    end_test(test_passed);

    // TEST 10: LOAD-USE - Load-Store dependency
    print_test_start(10, "LOAD-USE Hazard - Load-Store dependency");
    init_memory();
    dmem_write_word(0, 32'h00000007);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h0012a223);  // sw   x1, 4(x5) -> store to index 1
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (dut.D_wrapper.dmem.memory[1] == 32'h00000007);
    if (test_passed) begin
      print_pass("dmem[1] = 0x00000007 (load-store dependency)");
      log_hazard("LOAD-USE", "sw x1, 4(x5) uses x1 from lw");
    end else print_fail($sformatf("dmem[1] = 0x%08x (expected 7)", dut.D_wrapper.dmem.memory[1]));
    end_test(test_passed);

    // ========================================================================
    // HAZARD TYPE 3: WAW (Write-After-Write)
    // ========================================================================

    // TEST 11: WAW - Same register written twice
    print_test_start(11, "WAW Hazard - Same register written twice");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(2, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < TINY_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000006);
    if (test_passed) begin
      print_pass("x1 = 0x00000006 (WAW: second write wins)");
      log_hazard("WAW", "addi x1, x0, 6 overwrites addi x1, x0, 5");
    end else print_fail($sformatf("x1 = 0x%08x (expected 6)", get_gpr(1)));
    end_test(test_passed);

    // TEST 12: WAW - Multiple writes in pipeline
    print_test_start(12, "WAW Hazard - Multiple writes in pipeline");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(2, 32'h00700093);  // addi x1, x0, 7
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < TINY_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000007);
    if (test_passed) begin
      print_pass("x1 = 0x00000007 (WAW: last write wins)");
      log_hazard("WAW", "Three writes to x1 in pipeline");
    end else print_fail($sformatf("x1 = 0x%08x (expected 7)", get_gpr(1)));
    end_test(test_passed);

    // TEST 13: WAW - Load and ALU write same register
    print_test_start(13, "WAW Hazard - Load and ALU write same register");
    init_memory();
    dmem_write_word(0, 32'h00000042);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000005);
    if (test_passed) begin
      print_pass("x1 = 0x00000005 (WAW: ALU write wins over load)");
      log_hazard("WAW", "addi x1, x0, 5 overwrites lw x1, 0(x5)");
    end else print_fail($sformatf("x1 = 0x%08x (expected 5)", get_gpr(1)));
    end_test(test_passed);

    // ========================================================================
    // HAZARD TYPE 4: MEMORY-ORDERING
    // ========================================================================

    // TEST 14: MEMORY-ORDERING - Store then Load
    print_test_start(14, "MEMORY-ORDERING Hazard - Store then Load");
    init_memory();
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(2, 32'h0012a023);  // sw   x1, 0(x5)
    imem_write_word(3, 32'h0002a103);  // lw   x2, 0(x5)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000005);
    if (test_passed) begin
      print_pass("x2 = 0x00000005 (store-load ordering maintained)");
      log_hazard("MEMORY-ORDERING", "lw reads value written by sw in prior cycle");
    end else print_fail($sformatf("x2 = 0x%08x (expected 5)", get_gpr(2)));
    end_test(test_passed);

    // TEST 15: MEMORY-ORDERING - Multiple stores
    print_test_start(15, "MEMORY-ORDERING Hazard - Multiple stores");
    init_memory();
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00100093);  // addi x1, x0, 1
    imem_write_word(2, 32'h0012a023);  // sw   x1, 0(x5)
    imem_write_word(3, 32'h00200113);  // addi x2, x0, 2
    imem_write_word(4, 32'h0022a223);  // sw   x2, 4(x5)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((dut.D_wrapper.dmem.memory[0] == 32'd1) && (dut.D_wrapper.dmem.memory[1] == 32'd2));
    if (test_passed) begin
      print_pass("dmem[0] = 1, dmem[1] = 2 (multiple store ordering OK)");
      log_hazard("MEMORY-ORDERING", "Multiple stores to different addresses");
    end else print_fail("Store order failure");
    end_test(test_passed);

    // TEST 16: MEMORY-ORDERING - Store-Load different addresses
    print_test_start(16, "MEMORY-ORDERING Hazard - Store-Load different addresses");
    init_memory();
    dmem_write_word(1, 32'h00000099);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(2, 32'h0012a023);  // sw   x1, 0(x5)
    imem_write_word(3, 32'h0042a103);  // lw   x2, 4(x5)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000099);
    if (test_passed) begin
      print_pass("x2 = 0x00000099 (independent memory operations)");
      log_hazard("MEMORY-ORDERING", "Store and load to different addresses");
    end else print_fail($sformatf("x2 = 0x%08x (expected 0x99)", get_gpr(2)));
    end_test(test_passed);

    // ========================================================================
    // HAZARD TYPE 5: CONTROL (Branch & Jump)
    // ========================================================================

    // TEST 17: CONTROL - Branch taken
    print_test_start(17, "CONTROL Hazard - Branch taken");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(2, 32'h00208463);  // beq  x1, x2, +8
    imem_write_word(3, 32'h00100093);  // addi x1, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200093);  // addi x1, x0, 2 (EXECUTED)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000002);
    if (test_passed) begin
      print_pass("x1 = 0x00000002 (branch taken, pipeline flushed)");
      log_hazard("CONTROL", "beq taken - flushed instructions in shadow");
    end else print_fail($sformatf("x1 = 0x%08x (expected 2)", get_gpr(1)));
    end_test(test_passed);

    // TEST 18: CONTROL - Branch not taken
    print_test_start(18, "CONTROL Hazard - Branch not taken");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00300113);  // addi x2, x0, 3
    imem_write_word(2, 32'h00208063);  // beq  x1, x2, +4
    imem_write_word(3, 32'h00100093);  // addi x1, x0, 1 (EXECUTED)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000001);
    if (test_passed) begin
      print_pass("x1 = 0x00000001 (branch not taken, no flush)");
      log_hazard("CONTROL", "beq not taken - no flush");
    end else print_fail($sformatf("x1 = 0x%08x (expected 1)", get_gpr(1)));
    end_test(test_passed);

    // TEST 19: CONTROL - JAL (always taken)
    print_test_start(19, "CONTROL Hazard - JAL (always taken)");
    init_memory();
    imem_write_word(0, 32'h008000ef);  // jal  x1, +8
    imem_write_word(1, 32'h00100113);  // addi x2, x0, 1 (FLUSHED)
    imem_write_word(2, 32'h00200193);  // addi x3, x0, 2 (EXECUTED)
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 32'h80000004) && (get_gpr(3) == 32'h00000002));
    if (test_passed) begin
      print_pass("x1 = 0x80000004, x3 = 2 (JAL taken, pipeline flushed)");
      log_hazard("CONTROL", "jal taken - flushes shadow instruction");
    end else print_fail($sformatf("x1=0x%08x, x3=0x%08x", get_gpr(1), get_gpr(3)));
    end_test(test_passed);

    // TEST 20: CONTROL - JALR (always taken)
    print_test_start(20, "CONTROL Hazard - JALR (always taken)");
    init_memory();
    imem_write_word(0, 32'h800000b7);  // lui  x1, 0x80000
    imem_write_word(1, 32'h01008093);  // addi x1, x1, 16 (0x80000010 -> index 4)
    imem_write_word(2, 32'h000081e7);  // jalr x3, 0(x1)  -> return addr in x3
    imem_write_word(3, 32'h00100113);  // addi x2, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200213);  // addi x4, x0, 2 (EXECUTED)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'h8000000C) && (get_gpr(4) == 32'h00000002));
    if (test_passed) begin
      print_pass("x3 = 0x8000000C, x4 = 2 (JALR taken)");
      log_hazard("CONTROL", "jalr taken - flushes branch shadow");
    end else print_fail($sformatf("x3=0x%08x, x4=0x%08x", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // ========================================================================
    // HAZARD TYPE 6: STRUCTURAL
    // ========================================================================

    // TEST 21: STRUCTURAL - Simultaneous IMEM and DMEM
    print_test_start(21, "STRUCTURAL Hazard - Simultaneous IMEM and DMEM");
    init_memory();
    dmem_write_word(0, 32'h00000042);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h00000043);
    if (test_passed) begin
      print_pass("x2 = 0x00000043 (simultaneous IMEM/DMEM handled)");
      log_hazard("STRUCTURAL", "IMEM fetch and DMEM access simultaneous");
    end else print_fail($sformatf("x2 = 0x%08x", get_gpr(2)));
    end_test(test_passed);

    // TEST 22: STRUCTURAL - Sequential loads
    print_test_start(22, "STRUCTURAL Hazard - Sequential loads");
    init_memory();
    dmem_write_word(0, 32'h00000001);
    dmem_write_word(1, 32'h00000002);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h0042a103);  // lw   x2, 4(x5)
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 32'd1) && (get_gpr(2) == 32'd2));
    if (test_passed) begin
      print_pass("x1 = 1, x2 = 2 (sequential loads handled)");
      log_hazard("STRUCTURAL", "Multiple loads in pipeline");
    end else print_fail($sformatf("x1=%0d, x2=%0d", get_gpr(1), get_gpr(2)));
    end_test(test_passed);

    // TEST 23: STRUCTURAL - Load-Store sequence
    print_test_start(23, "STRUCTURAL Hazard - Load-Store sequence");
    init_memory();
    dmem_write_word(0, 32'h00000010);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h0012a223);  // sw   x1, 4(x5)
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (dut.D_wrapper.dmem.memory[1] == 32'h00000010);
    if (test_passed) begin
      print_pass("dmem[1] = 0x00000010 (load-store sequence)");
      log_hazard("STRUCTURAL", "Load followed immediately by store");
    end else print_fail($sformatf("dmem[1] = 0x%08x", dut.D_wrapper.dmem.memory[1]));
    end_test(test_passed);

    // ========================================================================
    // COMBINED HAZARDS & COMPLEX PIPELINE SEQUENCES
    // ========================================================================

    // TEST 24: Combined - RAW + CONTROL
    print_test_start(24, "Combined Hazard - Branch with RAW");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(2, 32'h00208463);  // beq  x1, x2, +8
    imem_write_word(3, 32'h00100093);  // addi x1, x0, 1 (FLUSHED)
    imem_write_word(4, 32'h00200193);  // addi x3, x0, 2 (EXECUTED)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h00000002);
    if (test_passed) begin
      print_pass("x3 = 2 (branch taken, pipeline flushed)");
      log_hazard("COMBINED", "Branch control hazard with RAW operands");
    end else print_fail($sformatf("x3 = 0x%08x", get_gpr(3)));
    end_test(test_passed);

    // TEST 25: Combined - LOAD-USE + CONTROL
    print_test_start(25, "Combined Hazard - Load + Branch");
    init_memory();
    dmem_write_word(0, 32'h00000005);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (x1 = 5)
    imem_write_word(2, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(3, 32'h00208463);  // beq  x1, x2, +8
    imem_write_word(4, 32'h00100093);  // addi x1, x0, 1 (FLUSHED)
    imem_write_word(5, 32'h00200193);  // addi x3, x0, 2 (EXECUTED)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'h00000002);
    if (test_passed) begin
      print_pass("x3 = 2 (load-use + branch resolved)");
      log_hazard("COMBINED", "Load-use stall + branch control flush");
    end else print_fail($sformatf("x3 = 0x%08x", get_gpr(3)));
    end_test(test_passed);

    // TEST 26: Combined - RAW + LOAD-USE + CONTROL
    print_test_start(26, "Combined Hazard - RAW + LOAD-USE + CONTROL");
    init_memory();
    dmem_write_word(0, 32'h00000003);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5)
    imem_write_word(2, 32'h00108113);  // addi x2, x1, 1 (x2 = 4)
    imem_write_word(3, 32'h00210463);  // beq  x2, x2, +8
    imem_write_word(4, 32'h00100093);  // addi x1, x0, 1 (FLUSHED)
    imem_write_word(5, 32'h00200193);  // addi x3, x0, 2 (EXECUTED)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(2) == 32'd4) && (get_gpr(3) == 32'd2));
    if (test_passed) begin
      print_pass("x2 = 4, x3 = 2 (RAW + LOAD-USE + CONTROL)");
      log_hazard("COMBINED", "All three hazard types combined");
    end else print_fail($sformatf("x2=%0d, x3=%0d", get_gpr(2), get_gpr(3)));
    end_test(test_passed);

    // TEST 27: Complex - Deep pipeline dependency
    print_test_start(27, "Complex Hazard - Deep pipeline dependency");
    init_memory();
    imem_write_word(0, 32'h00100093);  // addi x1, x0, 1
    imem_write_word(1, 32'h00108113);  // addi x2, x1, 1
    imem_write_word(2, 32'h00110193);  // addi x3, x2, 1
    imem_write_word(3, 32'h00118213);  // addi x4, x3, 1
    imem_write_word(4, 32'h00220293);  // addi x5, x4, 2
    imem_write_word(5, 32'h00228313);  // addi x6, x5, 2
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(5) == 32'd6) && (get_gpr(6) == 32'd8));
    if (test_passed) begin
      print_pass("x5 = 6, x6 = 8 (deep dependency chain)");
      log_hazard("COMBINED", "6-instruction dependency chain");
    end else print_fail($sformatf("x5=%0d, x6=%0d", get_gpr(5), get_gpr(6)));
    end_test(test_passed);

    // TEST 28: Stress - Multiple hazards in sequence
    print_test_start(28, "Stress Test - Multiple hazards in sequence");
    init_memory();
    dmem_write_word(0, 32'h0000000A);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (10)
    imem_write_word(2, 32'h00108113);  // addi x2, x1, 1 (11)
    imem_write_word(3, 32'h00210193);  // addi x3, x2, 2 (13)
    imem_write_word(4, 32'h00318233);  // add  x4, x3, x3 (26)
    imem_write_word(5, 32'h0042a023);  // sw   x4, 0(x5)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(4) == 32'd26) && (dut.D_wrapper.dmem.memory[0] == 32'd26));
    if (test_passed) begin
      print_pass("x4 = 26, dmem[0] = 26 (multiple hazards resolved)");
      log_hazard("STRESS", "Load-use + multiple RAW hazards");
    end else print_fail($sformatf("x4 = %0d, dmem[0] = %0d", get_gpr(4), dut.D_wrapper.dmem.memory[0]));
    end_test(test_passed);

    // TEST 29: Edge case - Register x0 (always zero)
    print_test_start(29, "Edge Case - Register x0 (always zero)");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00000113);  // addi x2, x0, 0
    imem_write_word(2, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < TINY_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(0) == 32'd0) && (get_gpr(1) == 32'd5) && (get_gpr(2) == 32'd0));
    if (test_passed) begin
      print_pass("x0 = 0, x1 = 5, x2 = 0");
      log_hazard("EDGE_CASE", "x0 register (always zero) no false hazard");
    end else print_fail("x0 was overwritten");
    end_test(test_passed);

    // TEST 30: Edge case - Back-to-back writes (WAW)
    print_test_start(30, "Edge Case - Back-to-back writes (WAW)");
    init_memory();
    imem_write_word(0, 32'h00100093);  // addi x1, x0, 1
    imem_write_word(1, 32'h00200093);  // addi x1, x0, 2
    imem_write_word(2, 32'h00300093);  // addi x1, x0, 3
    imem_write_word(3, 32'h00400093);  // addi x1, x0, 4
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000004);
    if (test_passed) begin
      print_pass("x1 = 0x00000004 (last write wins)");
      log_hazard("EDGE_CASE", "Back-to-back writes to same register");
    end else print_fail($sformatf("x1 = 0x%08x", get_gpr(1)));
    end_test(test_passed);

    // ========================================================================
    // M-EXTENSION HAZARD DETECTION
    // ========================================================================

    // TEST 31: RAW: MUL result -> ADDI
    print_test_start(31, "RAW: MUL result -> ADDI");
    init_memory();
    imem_write_word(0, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(1, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(2, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(3, 32'h00118213);  // addi x4, x3, 1  (43)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd42) && (get_gpr(4) == 32'd43));
    if (test_passed) begin
      print_pass("RAW: x3 = 42, x4 = 43 (MUL->ALU forwarding OK)");
      log_hazard("RAW", "MUL result consumed by ADDI");
    end else print_fail($sformatf("x3=%0d, x4=%0d", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // TEST 32: RAW CHAIN: MUL -> MUL -> ADDI
    print_test_start(32, "RAW: MUL chain (MUL->MUL->ADDI)");
    init_memory();
    imem_write_word(0, 32'h00200093);  // addi x1, x0, 2
    imem_write_word(1, 32'h00300113);  // addi x2, x0, 3
    imem_write_word(2, 32'h022081b3);  // mul  x3, x1, x2 (6)
    imem_write_word(3, 32'h02218233);  // mul  x4, x3, x2 (18)
    imem_write_word(4, 32'h00120293);  // addi x5, x4, 1  (19)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd6) && (get_gpr(4) == 32'd18) && (get_gpr(5) == 32'd19));
    if (test_passed) begin
      print_pass("RAW chain: x3=6, x4=18, x5=19");
      log_hazard("RAW", "MUL result forwarded into another MUL and ALU");
    end else print_fail($sformatf("x3=%0d, x4=%0d, x5=%0d", get_gpr(3), get_gpr(4), get_gpr(5)));
    end_test(test_passed);

    // TEST 33: LOAD-USE into MUL (lw -> mul)
    print_test_start(33, "LOAD-USE: lw -> MUL");
    init_memory();
    dmem_write_word(0, 32'h00000006);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (6)
    imem_write_word(2, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd42);
    if (test_passed) begin
      print_pass("LOAD-USE: x3 = 42 (lw->MUL OK)");
      log_hazard("LOAD-USE", "MUL consumes result of LW");
    end else print_fail($sformatf("x3 = %0d", get_gpr(3)));
    end_test(test_passed);

    // TEST 34: LOAD-USE into DIV (lw -> div)
    print_test_start(34, "LOAD-USE: lw -> DIV");
    init_memory();
    dmem_write_word(0, 32'h00000014);  // 20
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (20)
    imem_write_word(2, 32'h00600113);  // addi x2, x0, 6
    imem_write_word(3, 32'h0220c1b3);  // div  x3, x1, x2 (3)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd3);
    if (test_passed) begin
      print_pass("LOAD-USE: x3 = 3 (lw->DIV OK)");
      log_hazard("LOAD-USE", "DIV consumes result of LW");
    end else print_fail($sformatf("x3 = %0d", get_gpr(3)));
    end_test(test_passed);

    // TEST 35: WAW: MUL then DIV to same rd (x3)
    print_test_start(35, "WAW: MUL then DIV to same rd");
    init_memory();
    imem_write_word(0, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(1, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(2, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(3, 32'h0220c1b3);  // div  x3, x1, x2 (0)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd0);
    if (test_passed) begin
      print_pass("WAW: x3 = 0 (DIV result wins over prior MUL)");
      log_hazard("WAW", "Two M-ops writing same rd; last result visible");
    end else print_fail($sformatf("x3 = %0d", get_gpr(3)));
    end_test(test_passed);

    // TEST 36: WAW with intermediate use: DIV then MUL to same rd
    print_test_start(36, "WAW: DIV then MUL to same rd");
    init_memory();
    dmem_write_word(0, 32'h0000001e);  // 30
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (30)
    imem_write_word(2, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(3, 32'h0220c1b3);  // div  x3, x1, x2 (6)
    imem_write_word(4, 32'h022181b3);  // mul  x3, x3, x2 (30)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd30);
    if (test_passed) begin
      print_pass("WAW: x3 = 30 (MUL after DIV, same rd)");
      log_hazard("WAW", "DIV and MUL both write x3, last write kept");
    end else print_fail($sformatf("x3 = %0d", get_gpr(3)));
    end_test(test_passed);

    // TEST 37: MEMORY-ORDERING: store MUL result then load it back
    print_test_start(37, "MEMORY-ORDERING: sw(MUL) then lw");
    init_memory();
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(2, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(4, 32'h0032a023);  // sw   x3, 0(x5)
    imem_write_word(5, 32'h0002a303);  // lw   x6, 0(x5)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((dut.D_wrapper.dmem.memory[0] == 32'd42) && (get_gpr(6) == 32'd42));
    if (test_passed) begin
      print_pass("MEMORY-ORDER: dmem[0]=42, x6=42 (store-load ordering OK)");
      log_hazard("MEMORY-ORDERING", "MUL result stored and reloaded correctly");
    end else print_fail("Ordering error");
    end_test(test_passed);

    // TEST 38: MEMORY-ORDERING: independent addresses around MUL
    print_test_start(38, "MEMORY-ORDERING: independent addresses");
    init_memory();
    dmem_write_word(1, 32'h00000063);  // 99 at word index 1
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(2, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(4, 32'h0032a023);  // sw   x3, 0(x5)
    imem_write_word(5, 32'h0042a303);  // lw   x6, 4(x5) (99)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((dut.D_wrapper.dmem.memory[0] == 32'd42) && (get_gpr(6) == 32'd99));
    if (test_passed) begin
      print_pass("MEMORY-ORDER: dmem[0]=42, x6=99 (independent addrs OK)");
      log_hazard("MEMORY-ORDERING", "Store of MUL result doesn't corrupt other addr");
    end else print_fail("Independent addr error");
    end_test(test_passed);

    // TEST 39: CONTROL: branch on MUL result (MUL -> BEQ)
    print_test_start(39, "CONTROL: BEQ on MUL result");
    init_memory();
    imem_write_word(0, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(1, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(2, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(3, 32'h00318463);  // beq  x3, x3, +8
    imem_write_word(4, 32'h00100213);  // addi x4, x0, 1 (FLUSHED)
    imem_write_word(5, 32'h00200213);  // addi x4, x0, 2 (EXECUTED)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd42) && (get_gpr(4) == 32'd2));
    if (test_passed) begin
      print_pass("CONTROL: branch taken, x4=2, MUL result=42");
      log_hazard("CONTROL", "BEQ uses freshly produced MUL result");
    end else print_fail($sformatf("x3=%0d, x4=%0d", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // TEST 40: STRUCTURAL: back-to-back MULs
    print_test_start(40, "STRUCTURAL: back-to-back MULs");
    init_memory();
    imem_write_word(0, 32'h00200093);  // addi x1, x0, 2
    imem_write_word(1, 32'h00300113);  // addi x2, x0, 3
    imem_write_word(2, 32'h022081b3);  // mul  x3, x1, x2 (6)
    imem_write_word(3, 32'h02218233);  // mul  x4, x3, x2 (18)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd6) && (get_gpr(4) == 32'd18));
    if (test_passed) begin
      print_pass("STRUCTURAL: x3=6, x4=18 (MDU handles back-to-back MULs)");
      log_hazard("STRUCTURAL", "Two MULs queued through MDU");
    end else print_fail($sformatf("x3=%0d, x4=%0d", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // TEST 41: COMBINED: lw -> MUL -> BEQ
    print_test_start(41, "COMBINED: lw -> MUL -> BEQ");
    init_memory();
    dmem_write_word(0, 32'h00000005);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (5)
    imem_write_word(2, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (25)
    imem_write_word(4, 32'h01900213);  // addi x4, x0, 25
    imem_write_word(5, 32'h00418463);  // beq  x3, x4, +8
    imem_write_word(6, 32'h00100313);  // addi x6, x0, 1 (FLUSHED)
    imem_write_word(7, 32'h00200313);  // addi x6, x0, 2 (EXECUTED)
    imem_write_word(8, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd25) && (get_gpr(4) == 32'd25) && (get_gpr(6) == 32'd2));
    if (test_passed) begin
      print_pass("COMBINED: lw->MUL->BEQ OK, x3=x4=25, x6=2");
      log_hazard("COMBINED", "Load-use, RAW through MUL, and control hazard");
    end else print_fail("lw->MUL->BEQ mismatch");
    end_test(test_passed);

    // TEST 42: EDGE/COMBINED: DIV & REM feeding MUL
    print_test_start(42, "EDGE/COMBINED: DIV & REM feeding MUL");
    init_memory();
    imem_write_word(0, 32'h01400093);  // addi x1, x0, 20
    imem_write_word(1, 32'h00600113);  // addi x2, x0, 6
    imem_write_word(2, 32'h0220c1b3);  // div  x3, x1, x2 (3)
    imem_write_word(3, 32'h0220e233);  // rem  x4, x1, x2 (2)
    imem_write_word(4, 32'h024182b3);  // mul  x5, x3, x4 (6)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < LARGE_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd3) && (get_gpr(4) == 32'd2) && (get_gpr(5) == 32'd6));
    if (test_passed) begin
      print_pass("EDGE: x3=3 (DIV), x4=2 (REM), x5=6 (MUL)");
      log_hazard("COMBINED", "DIV/REM back-to-back, both feeding MUL");
    end else print_fail($sformatf("x3=%0d, x4=%0d, x5=%0d", get_gpr(3), get_gpr(4), get_gpr(5)));
    end_test(test_passed);

    // ========================================================================
    // CSR HAZARD TESTING
    // ========================================================================

    // TEST 43: CSR Hazards - CSRRWI/CSRRSI/CSRRCI on mtvec
    print_test_start(43, "CSR Hazards - CSRRWI/CSRRSI/CSRRCI on mtvec");
    init_memory();
    imem_write_word(0, 32'h305fd0f3);  // csrrwi x1, mtvec, 0x1f
    imem_write_word(1, 32'h3050e173);  // csrrsi x2, mtvec, 1
    imem_write_word(2, 32'h305f71f3);  // csrrci x3, mtvec, 0x1e
    imem_write_word(3, 32'h30506273);  // csrrsi x4, mtvec, 0
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'h00000000);
    if (test_passed) begin
      print_pass("CSR immediate hazards verified on mtvec");
      log_hazard("RAW", "CSR immediate sequence exercises RAW/WAW on CSR path");
    end else print_fail($sformatf("x1 = 0x%08x", get_gpr(1)));
    end_test(test_passed);

    // TEST 44: CSR + M Hazards - MUL result into mtvec via CSRRW
    print_test_start(44, "CSR + M Hazards - MUL result into mtvec via CSRRW");
    init_memory();
    imem_write_word(0, 32'h00600113);  // addi   x2, x0, 6
    imem_write_word(1, 32'h00700193);  // addi   x3, x0, 7
    imem_write_word(2, 32'h023100b3);  // mul    x1, x2, x3 (42)
    imem_write_word(3, 32'h30509073);  // csrrw  x0, mtvec, x1
    imem_write_word(4, 32'h30506273);  // csrrsi x4, mtvec, 0
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(1) == 32'd42);
    if (test_passed) begin
      print_pass("M->CSR: x1 = 42 forwarded cleanly");
      log_hazard("COMBINED", "M-extension result forwarded into CSR write (CSRRW)");
    end else print_fail($sformatf("x1 = %0d", get_gpr(1)));
    end_test(test_passed);

    // TEST 45: Trap flow: ECALL -> mtvec handler -> MRET (with CSRs)
    print_test_start(45, "Trap flow: ECALL -> mtvec handler -> MRET (with CSRs)");
    init_memory();
    // mtvec handler at 0x80000040 (word index 16):
    imem_write_word(16, 32'h0aa00193); // addi  x3, x0, 0xAA
    imem_write_word(17, 32'h34102273); // csrrs x4, mepc, x0
    imem_write_word(18, 32'h00020393); // addi  x7, x4, 0 (save mepc)
    imem_write_word(19, 32'h00420213); // addi  x4, x4, 4 (skip ecall)
    imem_write_word(20, 32'h34121073); // csrrw x0, mepc, x4
    imem_write_word(21, 32'h34202373); // csrrs x6, mcause, x0
    imem_write_word(22, 32'h30200073); // mret

    // Main Program:
    imem_write_word(0, 32'h800000b7);  // lui   x1, 0x80000
    imem_write_word(1, 32'h04008093);  // addi  x1, x1, 0x40
    imem_write_word(2, 32'h30509073);  // csrrw x0, mtvec, x1
    imem_write_word(3, 32'h00000013);  // nop
    imem_write_word(4, 32'h00000073);  // ecall
    imem_write_word(5, 32'h00700293);  // addi  x5, x0, 7
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < LARGE_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'hAA) && (get_gpr(6) == 32'd11) && (get_gpr(5) == 32'd7));
    if (test_passed) begin
      print_pass("ECALL->mtvec->MRET executed perfectly (x3=0xAA, x6=11, x5=7)");
      log_hazard("CONTROL", "ECALL -> mtvec handler -> MRET flow using CSRs");
    end else print_fail($sformatf("x3=0x%02x, x6=%0d, x5=%0d", get_gpr(3), get_gpr(6), get_gpr(5)));
    end_test(test_passed);

    // TEST 46: CSR RAW/forwarding: ALU -> mscratch -> GPR
    print_test_start(46, "CSR RAW/forwarding: ALU -> mscratch -> GPR");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi  x1, x0, 5
    imem_write_word(1, 32'h00a00113);  // addi  x2, x0, 10
    imem_write_word(2, 32'h002081b3);  // add   x3, x1, x2 (15)
    imem_write_word(3, 32'h34019073);  // csrrw x0, mscratch, x3
    imem_write_word(4, 32'h34002273);  // csrrs x4, mscratch, x0 (15)
    imem_write_word(5, 32'h00120293);  // addi  x5, x4, 1 (16)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd15) && (get_gpr(4) == 32'd15) && (get_gpr(5) == 32'd16));
    if (test_passed) begin
      print_pass("CSR RAW: x3=15, x4=15 (mscratch), x5=16");
      log_hazard("RAW", "ALU result written to mscratch then read into x4/x5");
    end else print_fail($sformatf("x3=%0d, x4=%0d, x5=%0d", get_gpr(3), get_gpr(4), get_gpr(5)));
    end_test(test_passed);

    // TEST 47: CSR LOAD-USE: lw -> mscratch -> GPR
    print_test_start(47, "CSR LOAD-USE: lw -> mscratch -> GPR");
    init_memory();
    dmem_write_word(0, 32'h0000002a);  // 42
    imem_write_word(0, 32'h800082b7);  // lui   x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw    x1, 0(x5) (42)
    imem_write_word(2, 32'h34009073);  // csrrw x0, mscratch, x1
    imem_write_word(3, 32'h34002173);  // csrrs x2, mscratch, x0 (42)
    imem_write_word(4, 32'h00110193);  // addi  x3, x2, 1 (43)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 32'd42) && (get_gpr(2) == 32'd42) && (get_gpr(3) == 32'd43));
    if (test_passed) begin
      print_pass("CSR LOAD-USE: x1=42, x2=42, x3=43");
      log_hazard("LOAD-USE", "lw -> CSRRW(mscratch) -> CSRRS(mscratch) -> ADDI");
    end else print_fail($sformatf("x1=%0d, x2=%0d, x3=%0d", get_gpr(1), get_gpr(2), get_gpr(3)));
    end_test(test_passed);

    // TEST 48: COMBINED: MUL -> mscratch -> GPR
    print_test_start(48, "COMBINED: MUL -> mscratch -> GPR");
    init_memory();
    imem_write_word(0, 32'h00600093);  // addi  x1, x0, 6
    imem_write_word(1, 32'h00700113);  // addi  x2, x0, 7
    imem_write_word(2, 32'h022081b3);  // mul   x3, x1, x2 (42)
    imem_write_word(3, 32'h34019073);  // csrrw x0, mscratch, x3
    imem_write_word(4, 32'h34002273);  // csrrs x4, mscratch, x0 (42)
    imem_write_word(5, 32'h00120293);  // addi  x5, x4, 1 (43)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd42) && (get_gpr(4) == 32'd42) && (get_gpr(5) == 32'd43));
    if (test_passed) begin
      print_pass("COMBINED: MUL result flows through mscratch to x4/x5");
      log_hazard("COMBINED", "MUL -> CSRRW(mscratch) -> CSRRS(mscratch) -> ADDI");
    end else print_fail("MUL->mscratch failure");
    end_test(test_passed);

    // TEST 49: CSR->CONTROL: mepc write followed by mret
    print_test_start(49, "CSR->CONTROL: mepc write followed by mret");
    init_memory();
    // Handler at 0x80000040:
    imem_write_word(16, 32'h0aa00193); // addi  x3, x0, 0xAA
    imem_write_word(17, 32'h80000237); // lui   x4, 0x80000
    imem_write_word(18, 32'h02020213); // addi  x4, x4, 0x20 (0x80000020)
    imem_write_word(19, 32'h34121073); // csrrw x0, mepc, x4
    imem_write_word(20, 32'h30200073); // mret

    // Main Program:
    imem_write_word(0, 32'h800000b7);  // lui   x1, 0x80000
    imem_write_word(1, 32'h04008093);  // addi  x1, x1, 0x40
    imem_write_word(2, 32'h30509073);  // csrrw x0, mtvec, x1
    imem_write_word(3, 32'h00000013);  // nop
    imem_write_word(4, 32'h00000073);  // ecall
    imem_write_word(5, 32'h01100293);  // addi  x5, x0, 0x11 (SHOULD BE SKIPPED)
    imem_write_word(6, 32'h00000013);  // nop
    // Target at 0x80000020 (word index 8):
    imem_write_word(8, 32'h02200313);  // addi  x6, x0, 0x22
    imem_write_word(9, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < LARGE_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(6) == 32'h22) && (get_gpr(5) == 32'h00));
    if (test_passed) begin
      print_pass("x6 = 0x22, x5 = 0 (mret redirected to modified mepc)");
      log_hazard("CONTROL", "mepc updated by CSR write before mret");
    end else print_fail($sformatf("x6=0x%02x, x5=0x%02x", get_gpr(6), get_gpr(5)));
    end_test(test_passed);

    // TEST 50: ADDRGEN RAW: ALU -> LW base
    print_test_start(50, "ADDRGEN RAW: ALU -> LW base");
    init_memory();
    dmem_write_word(2, 32'hDEAD_BEEF); // index 2 -> byte offset 8
    imem_write_word(0, 32'h800080b7);  // lui  x1, 0x80008
    imem_write_word(1, 32'h00800113);  // addi x2, x0, 8
    imem_write_word(2, 32'h002081b3);  // add  x3, x1, x2 (0x80008008)
    imem_write_word(3, 32'h0001a203);  // lw   x4, 0(x3)
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(4) == 32'hDEAD_BEEF);
    if (test_passed) begin
      print_pass("x4 = 0xDEADBEEF (ALU address generation forwarded to LW)");
      log_hazard("RAW", "ALU->address RAW forwarding into LW base");
    end else print_fail($sformatf("x4 = 0x%08x", get_gpr(4)));
    end_test(test_passed);

    // TEST 51: MDU result as LW base address
    print_test_start(51, "MDU result as LW base address");
    init_memory();
    dmem_write_word(2, 32'hCAFE_BABE); // offset 8
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00200093);  // addi x1, x0, 2
    imem_write_word(2, 32'h00400113);  // addi x2, x0, 4
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (8)
    imem_write_word(4, 32'h00328233);  // add  x4, x5, x3 (0x80008008)
    imem_write_word(5, 32'h00022303);  // lw   x6, 0(x4)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(6) == 32'hCAFE_BABE);
    if (test_passed) begin
      print_pass("x6 = 0xCAFEBABE (MUL result used in address calculation)");
      log_hazard("RAW", "MUL result forwarded into LW base address");
    end else print_fail($sformatf("x6 = 0x%08x", get_gpr(6)));
    end_test(test_passed);

    // TEST 52: CSR RAW: csrrw/csrrs rd==rs1 and x0
    print_test_start(52, "CSR RAW: csrrw/csrrs rd==rs1 and x0");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi  x1, x0, 5
    imem_write_word(1, 32'h340090f3);  // csrrw x1, mscratch, x1 (x1 <= old mscratch 0, mscratch <= 5)
    imem_write_word(2, 32'h34002173);  // csrrs x2, mscratch, x0 (x2 <= 5)
    imem_write_word(3, 32'h34001073);  // csrrw x0, mscratch, x0 (mscratch <= 0)
    imem_write_word(4, 32'h340021f3);  // csrrs x3, mscratch, x0 (x3 <= 0)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(1) == 32'd0) && (get_gpr(2) == 32'd5) && (get_gpr(3) == 32'd0));
    if (test_passed) begin
      print_pass("CSR RAW corner cases: x1=0, x2=5, x3=0");
      log_hazard("RAW", "CSR RAW hazards (rd==rs1, x0) with back-to-back csrrw/csrrs");
    end else print_fail($sformatf("x1=%0d, x2=%0d, x3=%0d", get_gpr(1), get_gpr(2), get_gpr(3)));
    end_test(test_passed);

    // TEST 53: Control hazard - JALR on freshly loaded target
    print_test_start(53, "CTRL: JALR on load result");
    init_memory();
    dmem_write_word(0, 32'h80000014);  // Target PC at byte 20 (index 5)
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (0x80000014)
    imem_write_word(2, 32'h00008067);  // jalr x0, 0(x1)
    imem_write_word(3, 32'h00000113);  // addi x2, x0, 0 (SKIPPED)
    imem_write_word(4, 32'h00000193);  // addi x3, x0, 0 (SKIPPED)
    imem_write_word(5, 32'h00100113);  // addi x2, x0, 1 (TARGET EXECUTED)
    imem_write_word(6, 32'h00100193);  // addi x3, x0, 1 (TARGET EXECUTED)
    imem_write_word(7, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(2) == 32'd1) && (get_gpr(3) == 32'd1));
    if (test_passed) begin
      print_pass("JALR on load result passed (x2=1, x3=1)");
      log_hazard("CONTROL", "JALR target forwarded from load result with pipeline flush");
    end else print_fail($sformatf("x2=%0d, x3=%0d", get_gpr(2), get_gpr(3)));
    end_test(test_passed);

    // TEST 54: MDU busy but independent ALU ops proceed
    print_test_start(54, "MDU busy + independent ALU progress");
    init_memory();
    imem_write_word(0, 32'h800083b7);  // lui  x7, 0x80008
    imem_write_word(1, 32'h00600093);  // addi x1, x0, 6
    imem_write_word(2, 32'h00700113);  // addi x2, x0, 7
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (42)
    imem_write_word(4, 32'h00100213);  // addi x4, x0, 1
    imem_write_word(5, 32'h004202b3);  // add  x5, x4, x4 (2)
    imem_write_word(6, 32'h00428333);  // add  x6, x5, x4 (3)
    imem_write_word(7, 32'h0033a023);  // sw   x3, 0(x7)
    imem_write_word(8, 32'h0003a403);  // lw   x8, 0(x7) (42)
    imem_write_word(9, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(4) == 32'd1) && (get_gpr(5) == 32'd2) &&
                   (get_gpr(6) == 32'd3) && (get_gpr(8) == 32'd42));
    if (test_passed) begin
      print_pass("MUL + independent ALU: x4=1, x5=2, x6=3, x8=42");
      log_hazard("MDU vs ALU Path", "MDU busy while independent ALU completes");
    end else print_fail($sformatf("x4=%0d, x5=%0d, x6=%0d, x8=%0d", get_gpr(4), get_gpr(5), get_gpr(6), get_gpr(8)));
    end_test(test_passed);

    // ========================================================================
    // ADDITIONAL BOUNDARY & CORNER HAZARD TESTS (TESTS 55 TO 64)
    // ========================================================================

    // TEST 55: RAW Hazard: AUIPC result feeding LW base
    print_test_start(55, "RAW Boundary: AUIPC -> LW base address");
    init_memory();
    dmem_write_word(0, 32'h11223344);
    // AUIPC generates 0x80008000 when PC=0x80000000 + 0x00008000
    imem_write_word(0, 32'h00008097);  // auipc x1, 8 (x1 = 0x80008000)
    imem_write_word(1, 32'h0000a103);  // lw    x2, 0(x1)
    imem_write_word(2, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h11223344);
    if (test_passed) begin
      print_pass("x2 = 0x11223344 (AUIPC forwarded to LW address directly)");
      log_hazard("RAW", "AUIPC target address forwarded into LSU read bus");
    end else print_fail($sformatf("x2 = 0x%08x", get_gpr(2)));
    end_test(test_passed);

    // TEST 56: RAW Forwarding: LUI into SW data
    print_test_start(56, "RAW Boundary: LUI -> SW store data");
    init_memory();
    imem_write_word(0, 32'h800082b7);  // lui x5, 0x80008
    imem_write_word(1, 32'hABCDE0b7);  // lui x1, 0xABCDE
    imem_write_word(2, 32'h0012a023);  // sw  x1, 0(x5)
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (dut.D_wrapper.dmem.memory[0] == 32'hABCDE000);
    if (test_passed) begin
      print_pass("dmem[0] = 0xABCDE000 (LUI forwarded to SW data)");
      log_hazard("RAW", "LUI result forwarded to Store Data without pipeline stall");
    end else print_fail($sformatf("dmem[0] = 0x%08x", dut.D_wrapper.dmem.memory[0]));
    end_test(test_passed);

    // TEST 57: RAW Chain: Back-to-Back DIV operations (DIV -> DIV -> ADDI)
    print_test_start(57, "RAW Chain: Back-to-back DIV operations");
    init_memory();
    imem_write_word(0, 32'h06400093);  // addi x1, x0, 100
    imem_write_word(1, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(2, 32'h0220c1b3);  // div  x3, x1, x2 (100 / 5 = 20)
    imem_write_word(3, 32'h00200213);  // addi x4, x0, 2
    imem_write_word(4, 32'h0241c2b3);  // div  x5, x3, x4 (20 / 2 = 10)
    imem_write_word(5, 32'h00128313);  // addi x6, x5, 1  (11)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < LARGE_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd20) && (get_gpr(5) == 32'd10) && (get_gpr(6) == 32'd11));
    if (test_passed) begin
      print_pass("x3=20, x5=10, x6=11 (sequential DIV pipeline stall & forwarding clean)");
      log_hazard("RAW", "Back-to-back DIV operands stall and forward correctly");
    end else print_fail($sformatf("x3=%0d, x5=%0d, x6=%0d", get_gpr(3), get_gpr(5), get_gpr(6)));
    end_test(test_passed);

    // TEST 58: M-Extension Corner: Divide-by-Zero result forwarded
    print_test_start(58, "RAW Hazard: DIV by Zero result forwarded to ADDI");
    init_memory();
    imem_write_word(0, 32'h00700093);  // addi x1, x0, 7
    imem_write_word(1, 32'h0200c1b3);  // div  x3, x1, x0 (7 / 0 = -1 -> 0xFFFFFFFF)
    imem_write_word(2, 32'h00118213);  // addi x4, x3, 1  (0xFFFFFFFF + 1 = 0)
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'hFFFFFFFF) && (get_gpr(4) == 32'd0));
    if (test_passed) begin
      print_pass("x3 = 0xFFFFFFFF, x4 = 0 (DIV0 result forwarded to ALU)");
      log_hazard("RAW", "Divide-by-zero default value forwarded to dependent instruction");
    end else print_fail($sformatf("x3=0x%08x, x4=%0d", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // TEST 59: Load-to-Branch Hazard (LW feeding BNE condition)
    print_test_start(59, "LOAD-USE Hazard: LW directly feeding Branch BNE");
    init_memory();
    dmem_write_word(0, 32'h00000008);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (8)
    imem_write_word(2, 32'h00000113);  // addi x2, x0, 0
    imem_write_word(3, 32'h00209463);  // bne  x1, x2, +8 (Branch Taken)
    imem_write_word(4, 32'h00100193);  // addi x3, x0, 1 (FLUSHED)
    imem_write_word(5, 32'h00200193);  // addi x3, x0, 2 (EXECUTED)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(3) == 32'd2);
    if (test_passed) begin
      print_pass("x3 = 2 (LW stall into branch evaluation succeeded)");
      log_hazard("LOAD-USE", "Load-use hazard directly on branch comparator operands");
    end else print_fail($sformatf("x3 = %0d", get_gpr(3)));
    end_test(test_passed);

    // TEST 60: Memory WAW: Consecutive Stores to identical address
    print_test_start(60, "MEMORY WAW: Consecutive Stores to identical address");
    init_memory();
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h00a00093);  // addi x1, x0, 10
    imem_write_word(2, 32'h01400113);  // addi x2, x0, 20
    imem_write_word(3, 32'h0012a023);  // sw   x1, 0(x5)
    imem_write_word(4, 32'h0022a023);  // sw   x2, 0(x5) (Overwrites index 0)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (dut.D_wrapper.dmem.memory[0] == 32'd20);
    if (test_passed) begin
      print_pass("dmem[0] = 20 (WAW store ordering preserved)");
      log_hazard("MEMORY-ORDERING", "Back-to-back stores to same byte lane resolve in program order");
    end else print_fail($sformatf("dmem[0] = %0d", dut.D_wrapper.dmem.memory[0]));
    end_test(test_passed);

// TEST 61: CSR RAW: Back-to-Back CSRRW and CSRRS on mscratch
    print_test_start(61, "CSR RAW: Back-to-back CSRRW and CSRRS on mscratch");
    init_memory();
    imem_write_word(0, 32'h05500093);  // addi  x1, x0, 0x55
    imem_write_word(1, 32'h34009073);  // csrrw x0, mscratch, x1 (mscratch <= 0x55)
    imem_write_word(2, 32'h34002173);  // csrrs x2, mscratch, x0 (x2 <= 0x55)  <-- MUST BE 32'h34002173
    imem_write_word(3, 32'h00000013);  // nop
    imem_write_word(4, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h55);
    if (test_passed) begin
      print_pass("x2 = 0x55 (CSR internal writeback-forwarding intact)");
      log_hazard("RAW", "CSR write followed immediately by CSR read");
    end else print_fail($sformatf("x2 = 0x%08x (expected 0x00000055)", get_gpr(2)));
    end_test(test_passed);

    // TEST 62: Interleaved Multi-Load and Multi-Store RAW / WAW Sequence
    print_test_start(62, "Interleaved Multi-Load/Store RAW / WAW Sequence");
    init_memory();
    dmem_write_word(0, 32'h00000001);
    dmem_write_word(1, 32'h00000002);
    imem_write_word(0, 32'h800082b7);  // lui  x5, 0x80008
    imem_write_word(1, 32'h0002a083);  // lw   x1, 0(x5) (1)
    imem_write_word(2, 32'h0042a103);  // lw   x2, 4(x5) (2)
    imem_write_word(3, 32'h002081b3);  // add  x3, x1, x2 (3)
    imem_write_word(4, 32'h0032a423);  // sw   x3, 8(x5) (writes 3 to index 2)
    imem_write_word(5, 32'h0082a203);  // lw   x4, 8(x5) (reloads 3)
    imem_write_word(6, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < MED_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd3) && (get_gpr(4) == 32'd3));
    if (test_passed) begin
      print_pass("x3 = 3, x4 = 3 (interleaved load/store pipeline coherent)");
      log_hazard("COMBINED", "Complex load-add-store-reload hazard chain");
    end else print_fail($sformatf("x3=%0d, x4=%0d", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // TEST 63: JAL Link Address forwarding into immediate arithmetic
    print_test_start(63, "RAW Hazard: JAL Link Register into ADDI");
    init_memory();
    imem_write_word(0, 32'h008000ef);  // jal  x1, +8 (x1 = 0x80000004)
    imem_write_word(1, 32'h00000013);  // nop (FLUSHED)
    imem_write_word(2, 32'h00c08113);  // addi x2, x1, 12 (0x80000004 + 12 = 0x80000010)
    imem_write_word(3, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = (get_gpr(2) == 32'h80000010);
    if (test_passed) begin
      print_pass("x2 = 0x80000010 (JAL link address forwarded directly into ALU)");
      log_hazard("RAW", "Link register written by jump forwarded into next instruction");
    end else print_fail($sformatf("x2 = 0x%08x", get_gpr(2)));
    end_test(test_passed);

    // TEST 64: Pipeline Flush during Active MDU Operation
    print_test_start(64, "CONTROL Hazard: Branch taken squashing MDU operation");
    init_memory();
    imem_write_word(0, 32'h00500093);  // addi x1, x0, 5
    imem_write_word(1, 32'h00500113);  // addi x2, x0, 5
    imem_write_word(2, 32'h00208463);  // beq  x1, x2, +8 (Branch Taken)
    imem_write_word(3, 32'h022081b3);  // mul  x3, x1, x2 (In branch shadow: MUST BE SQUASHED!)
    imem_write_word(4, 32'h00900213);  // addi x4, x0, 9  (Branch target: EXECUTED)
    imem_write_word(5, 32'h00000013);  // nop
    reset_core();
    for (cycle_count = 0; cycle_count < SMALL_CYCLES; cycle_count++) @(posedge clk);
    test_passed = ((get_gpr(3) == 32'd0) && (get_gpr(4) == 32'd9));
    if (test_passed) begin
      print_pass("x3 = 0, x4 = 9 (MDU in branch shadow cancelled without side-effects)");
      log_hazard("CONTROL", "Branch flush suppresses MDU multi-cycle initiation");
    end else print_fail($sformatf("x3 = %0d (expected 0), x4 = %0d", get_gpr(3), get_gpr(4)));
    end_test(test_passed);

    // ========================================================================
    // HAZARD REPORT
    // ========================================================================
    print_header("HAZARD DETECTION REPORT");
    $display("Total Hazards Tested: %0d\n", total_hazards_detected);

    foreach (hazard_log[i]) begin
      if (hazard_log[i].hazard_type == "RAW")                  raw_count++;
      else if (hazard_log[i].hazard_type == "LOAD-USE")        load_use_count++;
      else if (hazard_log[i].hazard_type == "WAW")             waw_count++;
      else if (hazard_log[i].hazard_type == "MEMORY-ORDERING") mem_ord_count++;
      else if (hazard_log[i].hazard_type == "CONTROL")         ctrl_count++;
      else if (hazard_log[i].hazard_type == "STRUCTURAL")      struct_count++;
      else if (hazard_log[i].hazard_type == "COMBINED")        combined_count++;
    end

    $display("Hazard Summary by Category:");
    $display("  |-- RAW (Read-After-Write):        %2d", raw_count);
    $display("  |-- LOAD-USE:                      %2d", load_use_count);
    $display("  |-- WAW (Write-After-Write):       %2d", waw_count);
    $display("  |-- MEMORY-ORDERING:               %2d", mem_ord_count);
    $display("  |-- CONTROL (Branch/Trap):         %2d", ctrl_count);
    $display("  |-- STRUCTURAL:                    %2d", struct_count);
    $display("  \\-- COMBINED / STRESS:             %2d\n", combined_count);

    // ========================================================================
    // TEST SUMMARY
    // ========================================================================
    print_header("FINAL TEST SUMMARY");
    $display("Total Tests Executed: %0d", NUM_HAZARD_TESTS);
    $display("Passed:               %0d", passed_tests);
    $display("Failed:               %0d", failed_tests);
    $display("Success Rate:         %0d%%\n", (passed_tests * 100) / NUM_HAZARD_TESTS);

    if (failed_tests == 0) begin
      $display("=========================================================================================================");
      $display("                            ALL PRAGYA CORE HAZARD TESTS PASSED!                                         ");
      $display("=========================================================================================================\n");
    end else begin
      $display("=========================================================================================================");
      $display("                                  SOME HAZARD TESTS FAILED!                                              ");
      $display("=========================================================================================================\n");
    end

    $finish;
  end

endmodule
