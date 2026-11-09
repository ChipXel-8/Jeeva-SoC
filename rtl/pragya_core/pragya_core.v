/*`timescale 1ns / 1ps

module pragya_core(
    input          pg_riscv32_mp_clk_in,
    input          pg_riscv32_mp_rst_in,
    input          pg_riscv32_mp_eirq_in,
    input          pg_riscv32_mp_tirq_in,
    input          pg_riscv32_mp_sirq_in,
    input          pg_riscv32_mp_instr_valid,
    input          pg_riscv32_mp_data_valid,
    input          pg_riscv32_mp_data_gnt,
    input          pg_riscv32_mp_instr_gnt,
    input [31:0]   pg_riscv32_mp_instr_in,
    input [31:0]   pg_riscv32_mp_dmdata_in,
    
    output [31:0] pg_riscv32_mp_dmdata_out,
    output [31:0] pg_riscv32_mp_dmaddr_out,
    output [31:0] pg_riscv32_mp_imaddr_out,
    output        pg_riscv32_mp_dmwen_out,
    output [3:0]  pg_riscv32_mp_dmbe_out,
    output        pg_riscv32_mp_dmreq_out,
    output        pg_riscv32_mp_imreq_out,
    output        commit_valid,
    output [31:0] commit_pc,
    output [31:0] commit_instr,
    output [4:0]  commit_rd,
    output [31:0] commit_data,
    output        commit_store,
    output [31:0] commit_store_addr,
    output [31:0] commit_store_data,
    output [31:0] commit_store_pc,
    output [31:0] commit_store_instr,
    output [3:0]  commit_store_be,
    output        commit_instr_valid,
    output [31:0] commit_rs1_data,
    output [31:0] commit_rs2_data
);
   
    // PC outputs
    wire        misaligned_instr_out;
    wire [31:0] pc_plus_4_out;
    wire [31:0] pc_out;
  
    // Pipeline 1 outputs
    wire [31:0] id_instr;
    wire        id_valid;

    // Decoder outputs
    wire [6:0]   opcode_out;
    wire [14:12] funct3_out;
    wire [31:25] funct7_out;
    wire [19:15] rs_1_addrs_out;
    wire [24:20] rs_2_addrs_out;
    wire [11:7]  rd_addrs_out;
    wire [31:7]  instr_out;
    wire [2:0]   mdu_op_out;
    wire [3:0]   alu_control_out;
    wire         reg_write_out;
    wire [2:0]   imm_src_out;
    wire         alu_src_out;
    wire         mem_write_out;
    wire         mem_req_out;
    wire [2:0]   wb_mux_sel_out;
    wire         i_adder_src_out;
    wire [6:2]   opcode6_to_2_out;
    wire [11:0]  csr_addr_out;
    wire         csr_wr_en_out;
    wire [2:0]   csr_op_out;
    wire         illegal_instr_out;
    wire         jalr;

    // Hazard unit signals
    wire        forward_a;
    wire        forward_b;
    wire        flush_DE;
    wire [31:0] rs1_forward;
    wire [31:0] rs2_forward;

    // Register file outputs
    wire [31:0] rs_1_out;  
    wire [31:0] rs_2_out;

    // Immediate generation & branch unit
    wire [31:0] imm_out;
    wire [31:0] i_adder_out;
    wire        branch_taken_out;

    // Execution unit outputs
    wire [31:0] op_2_out;
    wire [31:0] alu_result_out;
    wire [31:0] mdu_result_out;

    // CSR / Machine Control signals
    wire [31:0] csr_data_out;
    wire [31:0] epc_out;
    wire [31:0] trap_address_out;
    wire        mie_out;
    wire        trap_detected_out;
    wire [1:0]  pc_src_out;
    wire        mret_detected_out;
    wire        i_or_e_out;
    wire        set_epc_out;
    wire        set_cause_out;
    wire [3:0]  cause_out;
    wire        instret_inc_out;
    wire        mie_clear_out;
    wire        mie_set_out;
    wire [31:0] trap_value_out;
    wire        meie, mtie, msie;
    wire        meip, mtip, msip;
    wire [31:0] trap_pc_out;

    // Machine-mode pipeline redirect / flush
    wire trap_redirect    = (pc_src_out == 2'b10);
    wire mret_redirect    = (pc_src_out == 2'b01);
    wire machine_redirect = trap_redirect | mret_redirect;
    wire flush_if_id      = flush_DE | trap_detected_out | machine_redirect | mret_detected_out;

    // Pipeline 2 (DE -> MW) outputs
    wire        mem_wb_valid;
    wire        mem_req_reg_out;
    wire        mem_write_reg_out;
    wire [31:0] mdu_result_reg_out;
    wire [31:0] alu_result_reg_out;
    wire [31:0] i_adder_reg_out;
    wire [31:0] imm_reg_out;
    wire [31:0] pc_plus_4_reg_out;
    wire [31:0] rs_2_reg_out;
    wire [4:0]  rd_addrs_reg_out;
    wire [2:0]  funct3_reg_out;
    wire [2:0]  wb_mux_sel_reg_out;
    wire        reg_write_reg_out;
    wire [31:0] pc_reg_out;
    wire [31:0] instr_reg_out;
    wire        csr_wr_en_reg_out;
    wire [11:0] csr_addr_reg_out;
    wire [2:0]  csr_op_reg_out;
    wire [31:0] csr_data_reg_out;
    wire [4:0]  csr_imm_reg_out;

    // WB Mux & LSU outputs
    wire [31:0] wb_mux_out;
    wire [31:0] load_data_out;

    wire stallD;
    wire [31:0] pc;
    wire [31:0] pc_plus_4_pipline1_out;
    wire flush_de_mw;

    assign pg_riscv32_mp_imaddr_out = pc;
    assign pg_riscv32_mp_imreq_out  = ~pg_riscv32_mp_rst_in;

    pc_unit #(
        .RESET_PC(32'h80000000)
    ) u_pc_unit (
        .clk                 (pg_riscv32_mp_clk_in),
        .rst                 (pg_riscv32_mp_rst_in),
        .stall               (stallD),
        .branch_taken_in     (branch_taken_out),
        .pc_target           (i_adder_out),
        .pc_src_in           (pc_src_out),
        .epc_in              (epc_out),
        .trap_address_in     (trap_address_out),
        .pc                  (pc),
        .pc_plus4            (pc_plus_4_out),
        .misaligned_instr_out(misaligned_instr_out)
    );

    pragya_if_id_reg if_id_reg_inst (
        .clk_in                (pg_riscv32_mp_clk_in),
        .rst_in                (pg_riscv32_mp_rst_in),
        .pc_mux_in             (pc),
        .pc_plus_4_pipline1_in (pc_plus_4_out),
        .if_instr              (pg_riscv32_mp_instr_in),
        .if_valid              (pg_riscv32_mp_instr_valid),
        .stall_d               (stallD),
        .flush                 (flush_if_id),
        .pc_out                (pc_out),
        .pc_plus_4_pipline1_out(pc_plus_4_pipline1_out),
        .id_instr              (id_instr),
        .id_valid              (id_valid)
    );

    pragya_decoder decoder_inst (
        .instr_in         (id_instr),
        .rs_1_addrs_out   (rs_1_addrs_out),
        .rs_2_addrs_out   (rs_2_addrs_out),
        .rd_addrs_out     (rd_addrs_out),
        .instr_out        (instr_out),
        .funct3_out       (funct3_out),
        .funct7_out       (funct7_out),
        .opcode_out       (opcode_out),
        .mdu_op_out       (mdu_op_out),
        .alu_control_out  (alu_control_out),
        .reg_write_out    (reg_write_out),
        .imm_src_out      (imm_src_out),
        .alu_src_out      (alu_src_out),
        .jalr_out         (jalr),
        .mem_write_out    (mem_write_out),
        .mem_req_out      (mem_req_out),
        .wb_mux_sel_out   (wb_mux_sel_out),
        .i_adder_src_out  (i_adder_src_out),
        .opcode6_to_2_out (opcode6_to_2_out),
        .csr_addr_out     (csr_addr_out),
        .csr_wr_en_out    (csr_wr_en_out),
        .csr_op_out       (csr_op_out),
        .illegal_instr_out(illegal_instr_out)
    );

    // Load Writeback 1-Cycle Delay logic
    reg        load_wb_valid_reg;
    reg [4:0]  load_wb_rd_reg;
    reg [2:0]  load_wb_sel_reg;  

    wire is_load_mw = (mem_req_reg_out && !mem_write_reg_out);

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            load_wb_valid_reg <= 1'b0;
            load_wb_rd_reg    <= 5'b0;
            load_wb_sel_reg   <= 3'b0;
        end else begin
            load_wb_valid_reg <= is_load_mw;
            load_wb_rd_reg    <= rd_addrs_reg_out;
            load_wb_sel_reg   <= wb_mux_sel_reg_out;
        end
    end

    wire [4:0] final_rd_addrs = load_wb_valid_reg ? load_wb_rd_reg  : rd_addrs_reg_out;
    wire final_reg_write      = (is_load_mw ? 1'b0 : (load_wb_valid_reg ? 1'b1 : reg_write_reg_out)) && (final_rd_addrs != 5'd0);
    wire [2:0] final_wb_sel   = load_wb_valid_reg ? load_wb_sel_reg : wb_mux_sel_reg_out;

    pragya_regfile regfile_inst (
        .clk_in       (pg_riscv32_mp_clk_in),
        .rst_in       (pg_riscv32_mp_rst_in),
        .reg_write_in (final_reg_write),
        .rs_1_addrs_in(rs_1_addrs_out),
        .rs_2_addrs_in(rs_2_addrs_out),
        .rd_addrs_in  (final_rd_addrs),
        .wb_mux_in    (wb_mux_out),
        .rs_1_out     (rs_1_out),
        .rs_2_out     (rs_2_out)
    );

    pragya_csr csr_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .csr_wr_en_in    (csr_wr_en_reg_out),
        .csr_addr_in     (csr_addr_reg_out),
        .csr_op_in       (csr_op_reg_out),
        .csr_imm_in      (csr_imm_reg_out),
        .csr_data_in     (csr_data_reg_out),
        .trap_value_in   (trap_value_out),
        .pc_in           (trap_pc_out),
        .set_epc_in      (set_epc_out),
        .set_cause_in    (set_cause_out),
        .i_or_e_in       (i_or_e_out),
        .cause_in        (cause_out),
        .mie_clear_in    (mie_clear_out),
        .mie_set_in      (mie_set_out),
        .instret_inc_in  (instret_inc_out),
        .csr_data_out    (csr_data_out),
        .epc_out         (epc_out),
        .trap_address_out(trap_address_out),
        .mie_out         (mie_out),
        .meie_out        (meie),
        .mtie_out        (mtie),
        .msie_out        (msie)
    );

    assign meip = 1'b0;
    assign mtip = 1'b0;
    assign msip = 1'b0;

    wire retire_valid = mem_wb_valid &&
                       (instr_reg_out != 32'h00000013) &&
                       (!mem_req_reg_out || mem_write_reg_out || pg_riscv32_mp_data_valid);

    pragya_machine_control machine_control_inst (
        .clk_in             (pg_riscv32_mp_clk_in),
        .rst_in             (pg_riscv32_mp_rst_in),
        .pc_in              (pc_out),
        .id_valid_in        (id_valid),
        .mem_addr_in        (i_adder_out),
        .retire_valid_in    (retire_valid),
        .instr_in           (id_instr),
        .mret_detected_out  (mret_detected_out),
        .illegal_instr_in   (illegal_instr_out),
        .misaligned_instr_in(misaligned_instr_out),
        .opcode_6_to_2_in   (opcode_out[6:2]),
        .funct3_in          (funct3_out),
        .funct7_in          (funct7_out),
        .rs1_addr_in        (rs_1_addrs_out),
        .rs2_addr_in        (rs_2_addrs_out),
        .rd_addr_in         (rd_addrs_out),
        .trap_detected_out  (trap_detected_out),
        .trap_pc_out        (trap_pc_out),
        .trap_value_out     (trap_value_out),
        .e_irq_in           (pg_riscv32_mp_eirq_in),
        .t_irq_in           (pg_riscv32_mp_tirq_in),
        .s_irq_in           (pg_riscv32_mp_sirq_in),
        .mie_in             (mie_out),
        .meie_in            (meie),
        .mtie_in            (mtie),
        .msie_in            (msie),
        .meip_in            (meip),
        .mtip_in            (mtip),
        .msip_in            (msip),
        .i_or_e_out         (i_or_e_out),
        .set_epc_out        (set_epc_out),
        .set_cause_out      (set_cause_out),
        .cause_out          (cause_out),
        .instret_inc_out    (instret_inc_out),
        .mie_clear_out      (mie_clear_out),
        .mie_set_out        (mie_set_out),
        .pc_src_out         (pc_src_out)
    );

    wire wait_for_mem = mem_req_reg_out && !mem_write_reg_out && !pg_riscv32_mp_data_valid;

    // ============================================================
    // MDU Control & Hazard Signals
    // ============================================================
    wire        mdu_stall;
    wire        mdu_wb_valid;
    wire [4:0]  mdu_rd;
    wire [31:0] mdu_pc;
    wire [31:0] mdu_instr;
    
    // Identifies ANY MDU operation (Multiply OR Divide)
    wire        is_mdu_de = (wb_mux_sel_out == 3'b101) && id_valid;

    pragya_hazard_unit hazard_inst (
        .rs1_DE      (rs_1_addrs_out),
        .rs2_DE      (rs_2_addrs_out),
        .rd_DE       (rd_addrs_out),
        .wb_sel_DE   (wb_mux_sel_out),
        .mem_req_DE  (mem_req_out),
        .wait_for_mem(wait_for_mem),
        .mdu_stall   (mdu_stall),
        .instr_IF    (id_instr),
        .rd_MW       (final_rd_addrs),
        .reg_write_MW(final_reg_write),
        .branch_taken(branch_taken_out),
        .forward_a   (forward_a),
        .forward_b   (forward_b),
        .stallD      (stallD),
        .flush_DE    (flush_DE),
        .flush_de_mw (flush_de_mw)
    );

    pragya_imm_generator imm_gen_inst (
        .imm_gen_in(instr_out),
        .imm_src   (imm_src_out),
        .imm_out   (imm_out)
    );

    pragya_imm_adder imm_adder_inst (
        .pc_in          (pc_out),
        .rs_1_in        (rs1_forward),
        .imm_in         (imm_out),
        .jalr_in        (jalr),
        .i_adder_src_in (i_adder_src_out),
        .i_adder_out    (i_adder_out)
    );

    pragya_branch_unit branch_inst (
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .opcode6_to_2_in (opcode_out[6:2]),
        .funct3_in       (funct3_out),
        .branch_taken_out(branch_taken_out)
    );

    assign rs1_forward = forward_a ? wb_mux_out : rs_1_out;
    assign rs2_forward = forward_b ? wb_mux_out : rs_2_out;

    pragya_alu_mux alu_mux_inst (
        .rs_2_in   (rs2_forward),
        .imm_in    (imm_out),
        .alu_src_in(alu_src_out),
        .op_2_out  (op_2_out)
    );

    pragya_alu alu_inst (
        .rs_1_in       (rs1_forward),
        .rs_2_in       (op_2_out),
        .alu_control   (alu_control_out),
        .alu_result_out(alu_result_out)
    );

    pragya_mdu mdu_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .mdu_valid_in    (is_mdu_de),
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .mdu_op_in       (mdu_op_out),
        .rd_in           (rd_addrs_out),
        .pc_in           (pc_out),
        .instr_in        (id_instr),
        .mdu_result_out  (mdu_result_out),
        .mdu_rd_out      (mdu_rd),
        .mdu_pc_out      (mdu_pc),
        .mdu_instr_out   (mdu_instr),
        .mdu_wb_valid_out(mdu_wb_valid),
        .mdu_stall_out   (mdu_stall)
    );

    // ============================================================
    // FIX: Suppress ALL MDU operations (Multiply & Divide) on Cycle 1!
    // They ONLY enter Pipeline 2 when mdu_wb_valid pulses high!
    // ============================================================
    wire        pipe2_valid_in = mdu_wb_valid ? 1'b1 : (id_valid && !is_mdu_de && !trap_detected_out && !mret_detected_out);
    wire [4:0]  pipe2_rd       = mdu_wb_valid ? mdu_rd    : rd_addrs_out;
    wire [31:0] pipe2_pc       = mdu_wb_valid ? mdu_pc    : pc_out;
    wire [31:0] pipe2_instr    = mdu_wb_valid ? mdu_instr : id_instr;
    wire [2:0]  pipe2_wb_sel   = mdu_wb_valid ? 3'b101    : wb_mux_sel_out;
    wire        pipe2_reg_wr   = mdu_wb_valid ? (mdu_rd != 5'd0) : (reg_write_out && !is_mdu_de);

    pragya_de_mw_pipeline pipeline2_inst (
        .clk_in            (pg_riscv32_mp_clk_in),
        .rst_in            (pg_riscv32_mp_rst_in),
        .valid_de          (pipe2_valid_in),
        .stall_mw          (wait_for_mem),
        .mem_req_in        (mdu_wb_valid ? 1'b0 : mem_req_out),
        .mem_write_in      (mdu_wb_valid ? 1'b0 : mem_write_out),
        .mdu_result_in     (mdu_result_out),
        .alu_result_in     (alu_result_out),
        .i_adder_in        (i_adder_out),
        .imm_in            (imm_out),
        .csr_wr_en_in      (mdu_wb_valid ? 1'b0 : csr_wr_en_out),
        .csr_addr_in       (csr_addr_out),
        .csr_op_in         (csr_op_out),
        .csr_data_in       (rs1_forward),
        .csr_imm_in        (rs_1_addrs_out),
        .pc_plus_4_in      (pc_plus_4_pipline1_out),
        .pc_in             (pipe2_pc),
        .instr_in          (pipe2_instr),
        .rs_2_in           (rs2_forward),
        .rd_addrs_in       (pipe2_rd),
        .funct3_in         (funct3_out),
        .wb_mux_sel_in     (pipe2_wb_sel),
        .reg_write_in      (pipe2_reg_wr),
        .rvalid            (pg_riscv32_mp_data_valid),
        .flush             (flush_de_mw),
        .mem_wb_valid      (mem_wb_valid),
        .mem_req_reg_out   (mem_req_reg_out),
        .mem_write_reg_out (mem_write_reg_out),
        .mdu_result_reg_out(mdu_result_reg_out),
        .alu_result_reg_out(alu_result_reg_out),
        .i_adder_reg_out   (i_adder_reg_out),
        .imm_reg_out       (imm_reg_out),
        .pc_plus_4_reg_out (pc_plus_4_reg_out),
        .pc_reg_out        (pc_reg_out),
        .csr_wr_en_reg_out (csr_wr_en_reg_out),
        .csr_addr_reg_out  (csr_addr_reg_out),
        .csr_op_reg_out    (csr_op_reg_out),
        .csr_data_reg_out  (csr_data_reg_out),
        .csr_imm_reg_out   (csr_imm_reg_out),
        .instr_reg_out     (instr_reg_out),
        .rs_2_reg_out      (rs_2_reg_out),
        .rd_addrs_reg_out  (rd_addrs_reg_out),
        .funct3_reg_out    (funct3_reg_out),
        .wb_mux_sel_reg_out(wb_mux_sel_reg_out),
        .reg_write_reg_out (reg_write_reg_out)
    );

    pragya_wb_mux wb_mux_inst (
        .alu_result_in (alu_result_reg_out),
        .load_data_in  (load_data_out),
        .pc_plus4_in   (pc_plus_4_reg_out),
        .imm_in        (imm_reg_out),
        .i_adder_in    (i_adder_reg_out),
        .mdu_result_in (mdu_result_reg_out),
        .csr_data_in   (csr_data_out),
        .wb_mux_sel_in (final_wb_sel),
        .wb_mux_out    (wb_mux_out)
    );

    pragya_lsu lsu_inst (
        .clk_in                  (pg_riscv32_mp_clk_in),
        .rst_in                  (pg_riscv32_mp_rst_in),
        .mem_req_in              (mem_req_reg_out),
        .mem_write_in            (mem_write_reg_out),
        .funct3_in               (funct3_reg_out),
        .i_adder_in              (i_adder_reg_out),
        .rs_2_in                 (rs_2_reg_out),
        .dm_rvalid_in            (pg_riscv32_mp_data_valid),
        .dm_rdata_in             (pg_riscv32_mp_dmdata_in),
        .pg_riscv32_mp_dmreq_out (pg_riscv32_mp_dmreq_out),
        .pg_riscv32_mp_dmwen_out (pg_riscv32_mp_dmwen_out),
        .pg_riscv32_mp_dmbe_out  (pg_riscv32_mp_dmbe_out),
        .pg_riscv32_mp_dmaddr_out(pg_riscv32_mp_dmaddr_out),
        .pg_riscv32_mp_dmdata_out(pg_riscv32_mp_dmdata_out),
        .load_data_out           (load_data_out)
    );

    reg [31:0] commit_instr_reg;
    reg [31:0] commit_pc_reg;

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            commit_instr_reg <= 32'b0;
            commit_pc_reg    <= 32'b0;
        end else begin
            commit_instr_reg <= instr_reg_out;
            commit_pc_reg    <= pc_reg_out;
        end
    end

    // Commit Interface
    assign commit_valid       = final_reg_write && (final_rd_addrs != 5'd0);
    assign commit_pc          = load_wb_valid_reg ? commit_pc_reg : pc_reg_out;
    assign commit_instr       = load_wb_valid_reg ? commit_instr_reg : instr_reg_out;
    assign commit_rd          = final_rd_addrs;
    assign commit_data        = wb_mux_out;
    assign commit_instr_valid = mem_wb_valid;
    assign commit_rs1_data    = rs1_forward;
    assign commit_rs2_data    = rs2_forward;

    // Store Commit
    wire store_commit         = mem_wb_valid && mem_req_reg_out && mem_write_reg_out;
    assign commit_store       = store_commit;
    assign commit_store_addr  = i_adder_reg_out;
    assign commit_store_be    = pg_riscv32_mp_dmbe_out;

    reg [31:0] commit_store_data_arch;
    always @(*) begin
        case (funct3_reg_out)
            3'b000:  commit_store_data_arch = {24'b0, rs_2_reg_out[7:0]};
            3'b001:  commit_store_data_arch = {16'b0, rs_2_reg_out[15:0]};
            3'b010:  commit_store_data_arch = rs_2_reg_out;
            default: commit_store_data_arch = 32'b0;
        endcase
    end

    assign commit_store_data  = commit_store_data_arch;
    assign commit_store_pc    = pc_reg_out;
    assign commit_store_instr = instr_reg_out;

endmodule*/









/*`timescale 1ns / 1ps

module pragya_core(
    input          pg_riscv32_mp_clk_in,
    input          pg_riscv32_mp_rst_in,
    input          pg_riscv32_mp_eirq_in,
    input          pg_riscv32_mp_tirq_in,
    input          pg_riscv32_mp_sirq_in,
    input          pg_riscv32_mp_instr_valid,
    input          pg_riscv32_mp_data_valid,
    input          pg_riscv32_mp_data_gnt,
    input          pg_riscv32_mp_instr_gnt,
    input [31:0]   pg_riscv32_mp_instr_in,
    input [31:0]   pg_riscv32_mp_dmdata_in,
    
    output [31:0] pg_riscv32_mp_dmdata_out,
    output [31:0] pg_riscv32_mp_dmaddr_out,
    output [31:0] pg_riscv32_mp_imaddr_out,
    output        pg_riscv32_mp_dmwen_out,
    output [3:0]  pg_riscv32_mp_dmbe_out,
    output        pg_riscv32_mp_dmreq_out,
    output        pg_riscv32_mp_imreq_out,
    output        commit_valid,
    output [31:0] commit_pc,
    output [31:0] commit_instr,
    output [4:0]  commit_rd,
    output [31:0] commit_data,
    output        commit_store,
    output [31:0] commit_store_addr,
    output [31:0] commit_store_data,
    output [31:0] commit_store_pc,
    output [31:0] commit_store_instr,
    output [3:0]  commit_store_be,
    output        commit_instr_valid,
    output [31:0] commit_rs1_data,
    output [31:0] commit_rs2_data
);
   
    // PC outputs
    wire        misaligned_instr_out;
    wire [31:0] pc_plus_4_out;
    wire [31:0] pc_out;
  
    // Pipeline 1 outputs
    wire [31:0] id_instr;
    wire        id_valid;

    // Decoder outputs
    wire [6:0]   opcode_out;
    wire [14:12] funct3_out;
    wire [31:25] funct7_out;
    wire [19:15] rs_1_addrs_out;
    wire [24:20] rs_2_addrs_out;
    wire [11:7]  rd_addrs_out;
    wire [31:7]  instr_out;
    wire [2:0]   mdu_op_out;
    wire [3:0]   alu_control_out;
    wire         reg_write_out;
    wire [2:0]   imm_src_out;
    wire         alu_src_out;
    wire         mem_write_out;
    wire         mem_req_out;
    wire [2:0]   wb_mux_sel_out;
    wire         i_adder_src_out;
    wire [6:2]   opcode6_to_2_out;
    wire [11:0]  csr_addr_out;
    wire         csr_wr_en_out;
    wire [2:0]   csr_op_out;
    wire         illegal_instr_out;
    wire         jalr;

    // Hazard unit signals
    wire        forward_a;
    wire        forward_b;
    wire        flush_DE;
    wire [31:0] rs1_forward;
    wire [31:0] rs2_forward;

    // Register file outputs
    wire [31:0] rs_1_out;  
    wire [31:0] rs_2_out;

    // Immediate generation & branch unit
    wire [31:0] imm_out;
    wire [31:0] i_adder_out;
    wire        branch_taken_out;

    // Execution unit outputs
    wire [31:0] op_2_out;
    wire [31:0] alu_result_out;
    wire [31:0] mdu_result_out;

    // CSR / Machine Control signals
    wire [31:0] csr_data_out;
    wire [31:0] epc_out;
    wire [31:0] trap_address_out;
    wire        mie_out;
    wire        trap_detected_out;
    wire [1:0]  pc_src_out;
    wire        mret_detected_out;
    wire        i_or_e_out;
    wire        set_epc_out;
    wire        set_cause_out;
    wire [3:0]  cause_out;
    wire        instret_inc_out;
    wire        mie_clear_out;
    wire        mie_set_out;
    wire [31:0] trap_value_out;
    wire        meie, mtie, msie;
    wire        meip, mtip, msip;
    wire [31:0] trap_pc_out;

    // Machine-mode pipeline redirect / flush
    wire trap_redirect    = (pc_src_out == 2'b10);
    wire mret_redirect    = (pc_src_out == 2'b01);
    wire machine_redirect = trap_redirect | mret_redirect;
    wire flush_if_id      = flush_DE | trap_detected_out | machine_redirect | mret_detected_out;

    // Pipeline 2 (DE -> MW) outputs
    wire        mem_wb_valid;
    wire        mem_req_reg_out;
    wire        mem_write_reg_out;
    wire [31:0] mdu_result_reg_out;
    wire [31:0] alu_result_reg_out;
    wire [31:0] i_adder_reg_out;
    wire [31:0] imm_reg_out;
    wire [31:0] pc_plus_4_reg_out;
    wire [31:0] rs_2_reg_out;
    wire [4:0]  rd_addrs_reg_out;
    wire [2:0]  funct3_reg_out;
    wire [2:0]  wb_mux_sel_reg_out;
    wire        reg_write_reg_out;
    wire [31:0] pc_reg_out;
    wire [31:0] instr_reg_out;
    wire        csr_wr_en_reg_out;
    wire [11:0] csr_addr_reg_out;
    wire [2:0]  csr_op_reg_out;
    wire [31:0] csr_data_reg_out;
    wire [4:0]  csr_imm_reg_out;

    // WB Mux & LSU outputs
    wire [31:0] wb_mux_out;
    wire [31:0] load_data_out;

    wire stallD;
    wire [31:0] pc;
    wire [31:0] pc_plus_4_pipline1_out;
    wire flush_de_mw;

    assign pg_riscv32_mp_imaddr_out = pc;
    assign pg_riscv32_mp_imreq_out  = ~pg_riscv32_mp_rst_in;

    pc_unit #(
        .RESET_PC(32'h80000000)
    ) u_pc_unit (
        .clk                 (pg_riscv32_mp_clk_in),
        .rst                 (pg_riscv32_mp_rst_in),
        .stall               (stallD),
        .branch_taken_in     (branch_taken_out),
        .pc_target           (i_adder_out),
        .pc_src_in           (pc_src_out),
        .epc_in              (epc_out),
        .trap_address_in     (trap_address_out),
        .pc                  (pc),
        .pc_plus4            (pc_plus_4_out),
        .misaligned_instr_out(misaligned_instr_out)
    );

    pragya_if_id_reg if_id_reg_inst (
        .clk_in                (pg_riscv32_mp_clk_in),
        .rst_in                (pg_riscv32_mp_rst_in),
        .pc_mux_in             (pc),
        .pc_plus_4_pipline1_in (pc_plus_4_out),
        .if_instr              (pg_riscv32_mp_instr_in),
        .if_valid              (pg_riscv32_mp_instr_valid),
        .stall_d               (stallD),
        .flush                 (flush_if_id),
        .pc_out                (pc_out),
        .pc_plus_4_pipline1_out(pc_plus_4_pipline1_out),
        .id_instr              (id_instr),
        .id_valid              (id_valid)
    );

    pragya_decoder decoder_inst (
        .instr_in         (id_instr),
        .rs_1_addrs_out   (rs_1_addrs_out),
        .rs_2_addrs_out   (rs_2_addrs_out),
        .rd_addrs_out     (rd_addrs_out),
        .instr_out        (instr_out),
        .funct3_out       (funct3_out),
        .funct7_out       (funct7_out),
        .opcode_out       (opcode_out),
        .mdu_op_out       (mdu_op_out),
        .alu_control_out  (alu_control_out),
        .reg_write_out    (reg_write_out),
        .imm_src_out      (imm_src_out),
        .alu_src_out      (alu_src_out),
        .jalr_out         (jalr),
        .mem_write_out    (mem_write_out),
        .mem_req_out      (mem_req_out),
        .wb_mux_sel_out   (wb_mux_sel_out),
        .i_adder_src_out  (i_adder_src_out),
        .opcode6_to_2_out (opcode6_to_2_out),
        .csr_addr_out     (csr_addr_out),
        .csr_wr_en_out    (csr_wr_en_out),
        .csr_op_out       (csr_op_out),
        .illegal_instr_out(illegal_instr_out)
    );

    // Load Writeback 1-Cycle Delay logic
    reg        load_wb_valid_reg;
    reg [4:0]  load_wb_rd_reg;
    reg [2:0]  load_wb_sel_reg;  

    wire is_load_mw = (mem_req_reg_out && !mem_write_reg_out);

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            load_wb_valid_reg <= 1'b0;
            load_wb_rd_reg    <= 5'b0;
            load_wb_sel_reg   <= 3'b0;
        end else begin
            load_wb_valid_reg <= is_load_mw;
            load_wb_rd_reg    <= rd_addrs_reg_out;
            load_wb_sel_reg   <= wb_mux_sel_reg_out;
        end
    end

    wire [4:0] final_rd_addrs = load_wb_valid_reg ? load_wb_rd_reg  : rd_addrs_reg_out;
    wire final_reg_write      = (is_load_mw ? 1'b0 : (load_wb_valid_reg ? 1'b1 : reg_write_reg_out)) && (final_rd_addrs != 5'd0);
    wire [2:0] final_wb_sel   = load_wb_valid_reg ? load_wb_sel_reg : wb_mux_sel_reg_out;

    pragya_regfile regfile_inst (
        .clk_in       (pg_riscv32_mp_clk_in),
        .rst_in       (pg_riscv32_mp_rst_in),
        .reg_write_in (final_reg_write),
        .rs_1_addrs_in(rs_1_addrs_out),
        .rs_2_addrs_in(rs_2_addrs_out),
        .rd_addrs_in  (final_rd_addrs),
        .wb_mux_in    (wb_mux_out),
        .rs_1_out     (rs_1_out),
        .rs_2_out     (rs_2_out)
    );

    pragya_csr csr_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .csr_wr_en_in    (csr_wr_en_reg_out),
        .csr_addr_in     (csr_addr_reg_out),
        .csr_op_in       (csr_op_reg_out),
        .csr_imm_in      (csr_imm_reg_out),
        .csr_data_in     (csr_data_reg_out),
        .trap_value_in   (trap_value_out),
        .pc_in           (trap_pc_out),
        .set_epc_in      (set_epc_out),
        .set_cause_in    (set_cause_out),
        .i_or_e_in       (i_or_e_out),
        .cause_in        (cause_out),
        .mie_clear_in    (mie_clear_out),
        .mie_set_in      (mie_set_out),
        .instret_inc_in  (instret_inc_out),
        .csr_data_out    (csr_data_out),
        .epc_out         (epc_out),
        .trap_address_out(trap_address_out),
        .mie_out         (mie_out),
        .meie_out        (meie),
        .mtie_out        (mtie),
        .msie_out        (msie)
    );

    assign meip = 1'b0;
    assign mtip = 1'b0;
    assign msip = 1'b0;

    wire retire_valid = mem_wb_valid &&
                       (instr_reg_out != 32'h00000013) &&
                       (!mem_req_reg_out || mem_write_reg_out || pg_riscv32_mp_data_valid);

    pragya_machine_control machine_control_inst (
        .clk_in             (pg_riscv32_mp_clk_in),
        .rst_in             (pg_riscv32_mp_rst_in),
        .pc_in              (pc_out),
        .id_valid_in        (id_valid),
        .mem_addr_in        (i_adder_out),
        .retire_valid_in    (retire_valid),
        .instr_in           (id_instr),
        .mret_detected_out  (mret_detected_out),
        .illegal_instr_in   (illegal_instr_out),
        .misaligned_instr_in(misaligned_instr_out),
        .opcode_6_to_2_in   (opcode_out[6:2]),
        .funct3_in          (funct3_out),
        .funct7_in          (funct7_out),
        .rs1_addr_in        (rs_1_addrs_out),
        .rs2_addr_in        (rs_2_addrs_out),
        .rd_addr_in         (rd_addrs_out),
        .trap_detected_out  (trap_detected_out),
        .trap_pc_out        (trap_pc_out),
        .trap_value_out     (trap_value_out),
        .e_irq_in           (pg_riscv32_mp_eirq_in),
        .t_irq_in           (pg_riscv32_mp_tirq_in),
        .s_irq_in           (pg_riscv32_mp_sirq_in),
        .mie_in             (mie_out),
        .meie_in            (meie),
        .mtie_in            (mtie),
        .msie_in            (msie),
        .meip_in            (meip),
        .mtip_in            (mtip),
        .msip_in            (msip),
        .i_or_e_out         (i_or_e_out),
        .set_epc_out        (set_epc_out),
        .set_cause_out      (set_cause_out),
        .cause_out          (cause_out),
        .instret_inc_out    (instret_inc_out),
        .mie_clear_out      (mie_clear_out),
        .mie_set_out        (mie_set_out),
        .pc_src_out         (pc_src_out)
    );

    wire wait_for_mem = mem_req_reg_out && !mem_write_reg_out && !pg_riscv32_mp_data_valid;

    // ============================================================
    // MDU Control & Hazard Signals
    // ============================================================
    wire        mdu_stall;
    wire        mdu_wb_valid;
    wire [4:0]  mdu_rd;
    wire [31:0] mdu_pc;
    wire [31:0] mdu_instr;
    
    // Identifies ANY MDU operation (Multiply OR Divide)
    wire        is_mdu_de = (wb_mux_sel_out == 3'b101) && id_valid;

    pragya_hazard_unit hazard_inst (
        .rs1_DE      (rs_1_addrs_out),
        .rs2_DE      (rs_2_addrs_out),
        .rd_DE       (rd_addrs_out),
        .wb_sel_DE   (wb_mux_sel_out),
        .mem_req_DE  (mem_req_out),
        .wait_for_mem(wait_for_mem),
        .mdu_stall   (mdu_stall),
        .instr_IF    (id_instr),
        .rd_MW       (final_rd_addrs),
        .reg_write_MW(final_reg_write),
        .branch_taken(branch_taken_out),
        .forward_a   (forward_a),
        .forward_b   (forward_b),
        .stallD      (stallD),
        .flush_DE    (flush_DE),
        .flush_de_mw (flush_de_mw)
    );

    pragya_imm_generator imm_gen_inst (
        .imm_gen_in(instr_out),
        .imm_src   (imm_src_out),
        .imm_out   (imm_out)
    );

    pragya_imm_adder imm_adder_inst (
        .pc_in          (pc_out),
        .rs_1_in        (rs1_forward),
        .imm_in         (imm_out),
        .jalr_in        (jalr),
        .i_adder_src_in (i_adder_src_out),
        .i_adder_out    (i_adder_out)
    );

    pragya_branch_unit branch_inst (
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .opcode6_to_2_in (opcode_out[6:2]),
        .funct3_in       (funct3_out),
        .branch_taken_out(branch_taken_out)
    );

    assign rs1_forward = forward_a ? wb_mux_out : rs_1_out;
    assign rs2_forward = forward_b ? wb_mux_out : rs_2_out;

    pragya_alu_mux alu_mux_inst (
        .rs_2_in   (rs2_forward),
        .imm_in    (imm_out),
        .alu_src_in(alu_src_out),
        .op_2_out  (op_2_out)
    );

    pragya_alu alu_inst (
        .rs_1_in       (rs1_forward),
        .rs_2_in       (op_2_out),
        .alu_control   (alu_control_out),
        .alu_result_out(alu_result_out)
    );

    pragya_mdu mdu_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .mdu_valid_in    (is_mdu_de),
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .mdu_op_in       (mdu_op_out),
        .rd_in           (rd_addrs_out),
        .pc_in           (pc_out),
        .instr_in        (id_instr),
        .mdu_result_out  (mdu_result_out),
        .mdu_rd_out      (mdu_rd),
        .mdu_pc_out      (mdu_pc),
        .mdu_instr_out   (mdu_instr),
        .mdu_wb_valid_out(mdu_wb_valid),
        .mdu_stall_out   (mdu_stall)
    );

    // ============================================================
    // FIX: Suppress ALL MDU operations (Multiply & Divide) on Cycle 1!
    // They ONLY enter Pipeline 2 when mdu_wb_valid pulses high!
    // ============================================================
    wire        pipe2_valid_in = mdu_wb_valid ? 1'b1 : (id_valid && !is_mdu_de && !trap_detected_out && !mret_detected_out);
    wire [4:0]  pipe2_rd       = mdu_wb_valid ? mdu_rd    : rd_addrs_out;
    wire [31:0] pipe2_pc       = mdu_wb_valid ? mdu_pc    : pc_out;
    wire [31:0] pipe2_instr    = mdu_wb_valid ? mdu_instr : id_instr;
    wire [2:0]  pipe2_wb_sel   = mdu_wb_valid ? 3'b101    : wb_mux_sel_out;
    wire        pipe2_reg_wr   = mdu_wb_valid ? (mdu_rd != 5'd0) : (reg_write_out && !is_mdu_de);

    pragya_de_mw_pipeline pipeline2_inst (
        .clk_in            (pg_riscv32_mp_clk_in),
        .rst_in            (pg_riscv32_mp_rst_in),
        .valid_de          (pipe2_valid_in),
        .stall_mw          (wait_for_mem),
        .mem_req_in        (mdu_wb_valid ? 1'b0 : mem_req_out),
        .mem_write_in      (mdu_wb_valid ? 1'b0 : mem_write_out),
        .mdu_result_in     (mdu_result_out),
        .alu_result_in     (alu_result_out),
        .i_adder_in        (i_adder_out),
        .imm_in            (imm_out),
        .csr_wr_en_in      (mdu_wb_valid ? 1'b0 : csr_wr_en_out),
        .csr_addr_in       (csr_addr_out),
        .csr_op_in         (csr_op_out),
        .csr_data_in       (rs1_forward),
        .csr_imm_in        (rs_1_addrs_out),
        .pc_plus_4_in      (pc_plus_4_pipline1_out),
        .pc_in             (pipe2_pc),
        .instr_in          (pipe2_instr),
        .rs_2_in           (rs2_forward),
        .rd_addrs_in       (pipe2_rd),
        .funct3_in         (funct3_out),
        .wb_mux_sel_in     (pipe2_wb_sel),
        .reg_write_in      (pipe2_reg_wr),
        .rvalid            (pg_riscv32_mp_data_valid),
        .flush             (flush_de_mw),
        .mem_wb_valid      (mem_wb_valid),
        .mem_req_reg_out   (mem_req_reg_out),
        .mem_write_reg_out (mem_write_reg_out),
        .mdu_result_reg_out(mdu_result_reg_out),
        .alu_result_reg_out(alu_result_reg_out),
        .i_adder_reg_out   (i_adder_reg_out),
        .imm_reg_out       (imm_reg_out),
        .pc_plus_4_reg_out (pc_plus_4_reg_out),
        .pc_reg_out        (pc_reg_out),
        .csr_wr_en_reg_out (csr_wr_en_reg_out),
        .csr_addr_reg_out  (csr_addr_reg_out),
        .csr_op_reg_out    (csr_op_reg_out),
        .csr_data_reg_out  (csr_data_reg_out),
        .csr_imm_reg_out   (csr_imm_reg_out),
        .instr_reg_out     (instr_reg_out),
        .rs_2_reg_out      (rs_2_reg_out),
        .rd_addrs_reg_out  (rd_addrs_reg_out),
        .funct3_reg_out    (funct3_reg_out),
        .wb_mux_sel_reg_out(wb_mux_sel_reg_out),
        .reg_write_reg_out (reg_write_reg_out)
    );

    pragya_wb_mux wb_mux_inst (
        .alu_result_in (alu_result_reg_out),
        .load_data_in  (load_data_out),
        .pc_plus4_in   (pc_plus_4_reg_out),
        .imm_in        (imm_reg_out),
        .i_adder_in    (i_adder_reg_out),
        .mdu_result_in (mdu_result_reg_out),
        .csr_data_in   (csr_data_out),
        .wb_mux_sel_in (final_wb_sel),
        .wb_mux_out    (wb_mux_out)
    );

    pragya_lsu lsu_inst (
        .clk_in                  (pg_riscv32_mp_clk_in),
        .rst_in                  (pg_riscv32_mp_rst_in),
        .mem_req_in              (mem_req_reg_out),
        .mem_write_in            (mem_write_reg_out),
        .funct3_in               (funct3_reg_out),
        .i_adder_in              (i_adder_reg_out),
        .rs_2_in                 (rs_2_reg_out),
        .dm_rvalid_in            (pg_riscv32_mp_data_valid),
        .dm_rdata_in             (pg_riscv32_mp_dmdata_in),
        .pg_riscv32_mp_dmreq_out (pg_riscv32_mp_dmreq_out),
        .pg_riscv32_mp_dmwen_out (pg_riscv32_mp_dmwen_out),
        .pg_riscv32_mp_dmbe_out  (pg_riscv32_mp_dmbe_out),
        .pg_riscv32_mp_dmaddr_out(pg_riscv32_mp_dmaddr_out),
        .pg_riscv32_mp_dmdata_out(pg_riscv32_mp_dmdata_out),
        .load_data_out           (load_data_out)
    );

    reg [31:0] commit_instr_reg;
    reg [31:0] commit_pc_reg;

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            commit_instr_reg <= 32'b0;
            commit_pc_reg    <= 32'b0;
        end else begin
            commit_instr_reg <= instr_reg_out;
            commit_pc_reg    <= pc_reg_out;
        end
    end

    // Commit Interface
    assign commit_valid       = final_reg_write && (final_rd_addrs != 5'd0);
    assign commit_pc          = load_wb_valid_reg ? commit_pc_reg : pc_reg_out;
    assign commit_instr       = load_wb_valid_reg ? commit_instr_reg : instr_reg_out;
    assign commit_rd          = final_rd_addrs;
    assign commit_data        = wb_mux_out;
    assign commit_instr_valid = mem_wb_valid;
    assign commit_rs1_data    = rs1_forward;
    assign commit_rs2_data    = rs2_forward;

    // Store Commit
    wire store_commit         = mem_wb_valid && mem_req_reg_out && mem_write_reg_out;
    assign commit_store       = store_commit;
    assign commit_store_addr  = i_adder_reg_out;
    assign commit_store_be    = pg_riscv32_mp_dmbe_out;

    reg [31:0] commit_store_data_arch;
    always @(*) begin
        case (funct3_reg_out)
            3'b000:  commit_store_data_arch = {24'b0, rs_2_reg_out[7:0]};
            3'b001:  commit_store_data_arch = {16'b0, rs_2_reg_out[15:0]};
            3'b010:  commit_store_data_arch = rs_2_reg_out;
            default: commit_store_data_arch = 32'b0;
        endcase
    end

    assign commit_store_data  = commit_store_data_arch;
    assign commit_store_pc    = pc_reg_out;
    assign commit_store_instr = instr_reg_out;

endmodule*/


/*
`timescale 1ns / 1ps

module pragya_core(
    input          pg_riscv32_mp_clk_in,
    input          pg_riscv32_mp_rst_in,
    input          pg_riscv32_mp_debug_req_in,
    input          pg_riscv32_mp_eirq_in,
    input          pg_riscv32_mp_tirq_in,
    input          pg_riscv32_mp_sirq_in,
    input          pg_riscv32_mp_instr_valid,
    input          pg_riscv32_mp_data_valid,
    input          pg_riscv32_mp_data_gnt,
    input          pg_riscv32_mp_instr_gnt,
    input [31:0]   pg_riscv32_mp_instr_in,
    input [31:0]   pg_riscv32_mp_dmdata_in,
    
    output [31:0] pg_riscv32_mp_dmdata_out,
    output [31:0] pg_riscv32_mp_dmaddr_out,
    output [31:0] pg_riscv32_mp_imaddr_out,
    output        pg_riscv32_mp_dmwen_out,
    output [3:0]  pg_riscv32_mp_dmbe_out,
    output        pg_riscv32_mp_dmreq_out,
    output        pg_riscv32_mp_imreq_out,
    output        commit_valid,
    output [31:0] commit_pc,
    output [31:0] commit_instr,
    output [4:0]  commit_rd,
    output [31:0] commit_data,
    output        commit_store,
    output [31:0] commit_store_addr,
    output [31:0] commit_store_data,
    output [31:0] commit_store_pc,
    output [31:0] commit_store_instr,
    output [3:0]  commit_store_be,
    output        commit_instr_valid,
    output [31:0] commit_rs1_data,
    output [31:0] commit_rs2_data
);
   
    // PC outputs
    wire        misaligned_instr_out;
    wire [31:0] pc_plus_4_out;
    wire [31:0] pc_out;
  
    // Pipeline 1 outputs
    wire [31:0] id_instr;
    wire        id_valid;


// =========================================================
// Debug Interconnect Wires
// =========================================================
wire        is_dret_wire;
wire        debug_update_dpc_wire;
wire [31:0] debug_pc_save_wire;
wire [2:0]  debug_cause_wire;
wire [31:0] dpc_wire;

    // Decoder outputs
    wire [6:0]   opcode_out;
    wire [14:12] funct3_out;
    wire [31:25] funct7_out;
    wire [19:15] rs_1_addrs_out;
    wire [24:20] rs_2_addrs_out;
    wire [11:7]  rd_addrs_out;
    wire [31:7]  instr_out;
    wire [2:0]   mdu_op_out;
    wire [3:0]   alu_control_out;
    wire         reg_write_out;
    wire [2:0]   imm_src_out;
    wire         alu_src_out;
    wire         mem_write_out;
    wire         mem_req_out;
    wire [2:0]   wb_mux_sel_out;
    wire         i_adder_src_out;
    wire [6:2]   opcode6_to_2_out;
    wire [11:0]  csr_addr_out;
    wire         csr_wr_en_out;
    wire [2:0]   csr_op_out;
    wire         illegal_instr_out;
    wire         jalr;

    // Hazard unit signals
    wire        forward_a;
    wire        forward_b;
    wire        flush_DE;
    wire [31:0] rs1_forward;
    wire [31:0] rs2_forward;

    // Register file outputs
    wire [31:0] rs_1_out;  
    wire [31:0] rs_2_out;

    // Immediate generation & branch unit
    wire [31:0] imm_out;
    wire [31:0] i_adder_out;
    wire        branch_taken_out;

    // Execution unit outputs
    wire [31:0] op_2_out;
    wire [31:0] alu_result_out;
    wire [31:0] mdu_result_out;

    // CSR / Machine Control signals
    wire [31:0] csr_data_out;
    wire [31:0] epc_out;
    wire [31:0] trap_address_out;
    wire        mie_out;
    wire        trap_detected_out;
    wire [1:0]  pc_src_out;
    wire        mret_detected_out;
    wire        i_or_e_out;
    wire        set_epc_out;
    wire        set_cause_out;
    wire [3:0]  cause_out;
    wire        instret_inc_out;
    wire        mie_clear_out;
    wire        mie_set_out;
    wire [31:0] trap_value_out;
    wire        meie, mtie, msie;
    wire        meip, mtip, msip;
    wire [31:0] trap_pc_out;
    wire        wfi_stall;

    // Machine-mode pipeline redirect / flush
    wire trap_redirect    = (pc_src_out == 2'b10);
    wire mret_redirect    = (pc_src_out == 2'b01);
    wire machine_redirect = trap_redirect | mret_redirect;
    wire flush_if_id      = flush_DE | trap_detected_out | machine_redirect | mret_detected_out;

    // Pipeline 2 (DE -> MW) outputs
    wire        mem_wb_valid;
    wire        mem_req_reg_out;
    wire        mem_write_reg_out;
    wire [31:0] mdu_result_reg_out;
    wire [31:0] alu_result_reg_out;
    wire [31:0] i_adder_reg_out;
    wire [31:0] imm_reg_out;
    wire [31:0] pc_plus_4_reg_out;
    wire [31:0] rs_2_reg_out;
    wire [4:0]  rd_addrs_reg_out;
    wire [2:0]  funct3_reg_out;
    wire [2:0]  wb_mux_sel_reg_out;
    wire        reg_write_reg_out;
    wire [31:0] pc_reg_out;
    wire [31:0] instr_reg_out;
    wire        csr_wr_en_reg_out;
    wire [11:0] csr_addr_reg_out;
    wire [2:0]  csr_op_reg_out;
    wire [31:0] csr_data_reg_out;
    wire [4:0]  csr_imm_reg_out;

    // WB Mux & LSU outputs
    wire [31:0] wb_mux_out;
    wire [31:0] load_data_out;

    wire stallD;
    wire [31:0] pc;
    wire [31:0] pc_plus_4_pipline1_out;
    wire flush_de_mw;

    assign pg_riscv32_mp_imaddr_out = pc;
    //assign pg_riscv32_mp_imreq_out  = ~pg_riscv32_mp_rst_in;
    assign pg_riscv32_mp_imreq_out  = ~pg_riscv32_mp_rst_in & ~wfi_stall;


    pc_unit #(
        .RESET_PC(32'h80000000),
        .DEBUG_BASE_ADDR(32'h1A110800)
    ) u_pc_unit (
        .clk                 (pg_riscv32_mp_clk_in),
        .rst                 (pg_riscv32_mp_rst_in),
        .stall               (stallD),
        .branch_taken_in     (branch_taken_out),
        .pc_target           (i_adder_out),

// NEW DEBUG ROUTING
    .debug_req_i          (pg_riscv32_mp_debug_req_in),
    .is_dret_inst         (is_dret_wire),
    .dpc_in               (dpc_wire), 
    .debug_update_dpc_o   (debug_update_dpc_wire),
    .debug_pc_save_o      (debug_pc_save_wire),
    .debug_cause_o        (debug_cause_wire),

        .pc_src_in           (pc_src_out),
        .epc_in              (epc_out),
        .trap_address_in     (trap_address_out),
        .pc                  (pc),
        .pc_plus4            (pc_plus_4_out),
        .misaligned_instr_out(misaligned_instr_out)
    );

    pragya_if_id_reg if_id_reg_inst (
        .clk_in                (pg_riscv32_mp_clk_in),
        .rst_in                (pg_riscv32_mp_rst_in),
        .pc_mux_in             (pc),
        .pc_plus_4_pipline1_in (pc_plus_4_out),
        .if_instr              (pg_riscv32_mp_instr_in),
        .if_valid              (pg_riscv32_mp_instr_valid),
        .stall_d               (stallD),
        .flush                 (flush_if_id),
        .pc_out                (pc_out),
        .pc_plus_4_pipline1_out(pc_plus_4_pipline1_out),
        .id_instr              (id_instr),
        .id_valid              (id_valid)
    );

    pragya_decoder decoder_inst (
        .instr_in         (id_instr),
        .rs_1_addrs_out   (rs_1_addrs_out),
        .rs_2_addrs_out   (rs_2_addrs_out),
        .rd_addrs_out     (rd_addrs_out),
        .instr_out        (instr_out),
        .funct3_out       (funct3_out),
        .funct7_out       (funct7_out),
        .opcode_out       (opcode_out),
        .mdu_op_out       (mdu_op_out),
        .alu_control_out  (alu_control_out),
        .reg_write_out    (reg_write_out),
        .imm_src_out      (imm_src_out),
        .alu_src_out      (alu_src_out),
        .jalr_out         (jalr),
        .mem_write_out    (mem_write_out),
        .mem_req_out      (mem_req_out),
        .wb_mux_sel_out   (wb_mux_sel_out),
        .i_adder_src_out  (i_adder_src_out),
        .opcode6_to_2_out (opcode6_to_2_out),
        .csr_addr_out     (csr_addr_out),
        .csr_wr_en_out    (csr_wr_en_out),
        .csr_op_out       (csr_op_out),
        .illegal_instr_out(illegal_instr_out),
        .is_dret_out      (is_dret_wire)
    );

    // Load Writeback 1-Cycle Delay logic
    reg        load_wb_valid_reg;
    reg [4:0]  load_wb_rd_reg;
    reg [2:0]  load_wb_sel_reg;  

    wire is_load_mw = (mem_req_reg_out && !mem_write_reg_out);

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            load_wb_valid_reg <= 1'b0;
            load_wb_rd_reg    <= 5'b0;
            load_wb_sel_reg   <= 3'b0;
        end else begin
            load_wb_valid_reg <= is_load_mw;
            load_wb_rd_reg    <= rd_addrs_reg_out;
            load_wb_sel_reg   <= wb_mux_sel_reg_out;
        end
    end

    wire [4:0] final_rd_addrs = load_wb_valid_reg ? load_wb_rd_reg  : rd_addrs_reg_out;
    wire final_reg_write      = (is_load_mw ? 1'b0 : (load_wb_valid_reg ? 1'b1 : reg_write_reg_out)) && (final_rd_addrs != 5'd0);
    wire [2:0] final_wb_sel   = load_wb_valid_reg ? load_wb_sel_reg : wb_mux_sel_reg_out;

    pragya_regfile regfile_inst (
        .clk_in       (pg_riscv32_mp_clk_in),
        .rst_in       (pg_riscv32_mp_rst_in),
        .reg_write_in (final_reg_write),
        .rs_1_addrs_in(rs_1_addrs_out),
        .rs_2_addrs_in(rs_2_addrs_out),
        .rd_addrs_in  (final_rd_addrs),
        .wb_mux_in    (wb_mux_out),
        .rs_1_out     (rs_1_out),
        .rs_2_out     (rs_2_out)
    );

    pragya_csr csr_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .csr_wr_en_in    (csr_wr_en_reg_out),
        .csr_addr_in     (csr_addr_reg_out),
        .csr_op_in       (csr_op_reg_out),
        .csr_imm_in      (csr_imm_reg_out),
        .csr_data_in     (csr_data_reg_out),
        .trap_value_in   (trap_value_out),
        .pc_in           (trap_pc_out),
        .set_epc_in      (set_epc_out),
        .set_cause_in    (set_cause_out),
        .i_or_e_in       (i_or_e_out),
        .cause_in        (cause_out),
        .mie_clear_in    (mie_clear_out),
        .mie_set_in      (mie_set_out),
        .instret_inc_in  (instret_inc_out),
        .csr_data_out    (csr_data_out),
        .epc_out         (epc_out),
        .trap_address_out(trap_address_out),
        .mie_out         (mie_out),
        .meie_out        (meie),
        .mtie_out        (mtie),
        .msie_out        (msie),
        // NEW DEBUG ROUTING
    .debug_update_dpc_in (debug_update_dpc_wire),
    .debug_pc_save_in    (debug_pc_save_wire),
    .debug_cause_in      (debug_cause_wire),
    .dpc_out             (dpc_wire)
    );

    assign meip = 1'b0;
    assign mtip = 1'b0;
    assign msip = 1'b0;

    wire retire_valid = mem_wb_valid &&
                       (instr_reg_out != 32'h00000013) &&
                       (!mem_req_reg_out || mem_write_reg_out || pg_riscv32_mp_data_valid);

    pragya_machine_control machine_control_inst (
        .clk_in             (pg_riscv32_mp_clk_in),
        .rst_in             (pg_riscv32_mp_rst_in),
        .pc_in              (pc_out),
        .id_valid_in        (id_valid),
        .mem_addr_in        (i_adder_out),
        .retire_valid_in    (retire_valid),
        .instr_in           (id_instr),
        .mret_detected_out  (mret_detected_out),
        .illegal_instr_in   (illegal_instr_out),
        .misaligned_instr_in(misaligned_instr_out),
        .opcode_6_to_2_in   (opcode_out[6:2]),
        .funct3_in          (funct3_out),
        .funct7_in          (funct7_out),
        .rs1_addr_in        (rs_1_addrs_out),
        .rs2_addr_in        (rs_2_addrs_out),
        .rd_addr_in         (rd_addrs_out),
        .trap_detected_out  (trap_detected_out),
        .trap_pc_out        (trap_pc_out),
        .trap_value_out     (trap_value_out),
        .e_irq_in           (pg_riscv32_mp_eirq_in),
        .t_irq_in           (pg_riscv32_mp_tirq_in),
        .s_irq_in           (pg_riscv32_mp_sirq_in),
        .mie_in             (mie_out),
        .meie_in            (meie),
        .mtie_in            (mtie),
        .msie_in            (msie),
        .meip_in            (meip),
        .mtip_in            (mtip),
        .msip_in            (msip),
        .i_or_e_out         (i_or_e_out),
        .set_epc_out        (set_epc_out),
        .set_cause_out      (set_cause_out),
        .cause_out          (cause_out),
        .instret_inc_out    (instret_inc_out),
        .mie_clear_out      (mie_clear_out),
        .mie_set_out        (mie_set_out),
        .pc_src_out         (pc_src_out),
        .wfi_stall_out      (wfi_stall)
    );

    wire wait_for_mem = mem_req_reg_out && !mem_write_reg_out && !pg_riscv32_mp_data_valid;

    // ============================================================
    // MDU Control & Hazard Signals
    // ============================================================
    wire        mdu_stall;
    wire        mdu_wb_valid;
    wire [4:0]  mdu_rd;
    wire [31:0] mdu_pc;
    wire [31:0] mdu_instr;
    
    // Identifies ANY MDU operation (Multiply OR Divide)
    wire        is_mdu_de = (wb_mux_sel_out == 3'b101) && id_valid;

    pragya_hazard_unit hazard_inst (
        .rs1_DE      (rs_1_addrs_out),
        .rs2_DE      (rs_2_addrs_out),
        .rd_DE       (rd_addrs_out),
        .wb_sel_DE   (wb_mux_sel_out),
        .mem_req_DE  (mem_req_out),
        .wait_for_mem(wait_for_mem),
        .wfi_stall   (wfi_stall),
        .mdu_stall   (mdu_stall),
        .instr_IF    (id_instr),
        .rd_MW       (final_rd_addrs),
        .reg_write_MW(final_reg_write),
        .branch_taken(branch_taken_out),
        .forward_a   (forward_a),
        .forward_b   (forward_b),
        .stallD      (stallD),
        .flush_DE    (flush_DE),
        .flush_de_mw (flush_de_mw)
    );

    pragya_imm_generator imm_gen_inst (
        .imm_gen_in(instr_out),
        .imm_src   (imm_src_out),
        .imm_out   (imm_out)
    );

    pragya_imm_adder imm_adder_inst (
        .pc_in          (pc_out),
        .rs_1_in        (rs1_forward),
        .imm_in         (imm_out),
        .jalr_in        (jalr),
        .i_adder_src_in (i_adder_src_out),
        .i_adder_out    (i_adder_out)
    );

    pragya_branch_unit branch_inst (
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .opcode6_to_2_in (opcode_out[6:2]),
        .funct3_in       (funct3_out),
        .branch_taken_out(branch_taken_out)
    );

    assign rs1_forward = forward_a ? wb_mux_out : rs_1_out;
    assign rs2_forward = forward_b ? wb_mux_out : rs_2_out;

    pragya_alu_mux alu_mux_inst (
        .rs_2_in   (rs2_forward),
        .imm_in    (imm_out),
        .alu_src_in(alu_src_out),
        .op_2_out  (op_2_out)
    );

    pragya_alu alu_inst (
        .rs_1_in       (rs1_forward),
        .rs_2_in       (op_2_out),
        .alu_control   (alu_control_out),
        .alu_result_out(alu_result_out)
    );

    pragya_mdu mdu_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .mdu_valid_in    (is_mdu_de),
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .mdu_op_in       (mdu_op_out),
        .rd_in           (rd_addrs_out),
        .pc_in           (pc_out),
        .instr_in        (id_instr),
        .mdu_result_out  (mdu_result_out),
        .mdu_rd_out      (mdu_rd),
        .mdu_pc_out      (mdu_pc),
        .mdu_instr_out   (mdu_instr),
        .mdu_wb_valid_out(mdu_wb_valid),
        .mdu_stall_out   (mdu_stall)
    );

    // ============================================================
    // FIX: Suppress ALL MDU operations (Multiply & Divide) on Cycle 1!
    // They ONLY enter Pipeline 2 when mdu_wb_valid pulses high!
    // ============================================================
    wire        pipe2_valid_in = mdu_wb_valid ? 1'b1 : (id_valid && !is_mdu_de && !trap_detected_out && !mret_detected_out);
    wire [4:0]  pipe2_rd       = mdu_wb_valid ? mdu_rd    : rd_addrs_out;
    wire [31:0] pipe2_pc       = mdu_wb_valid ? mdu_pc    : pc_out;
    wire [31:0] pipe2_instr    = mdu_wb_valid ? mdu_instr : id_instr;
    wire [2:0]  pipe2_wb_sel   = mdu_wb_valid ? 3'b101    : wb_mux_sel_out;
    wire        pipe2_reg_wr   = mdu_wb_valid ? (mdu_rd != 5'd0) : (reg_write_out && !is_mdu_de);

    pragya_de_mw_pipeline pipeline2_inst (
        .clk_in            (pg_riscv32_mp_clk_in),
        .rst_in            (pg_riscv32_mp_rst_in),
        .valid_de          (pipe2_valid_in),
        .stall_mw          (wait_for_mem),
        .mem_req_in        (mdu_wb_valid ? 1'b0 : mem_req_out),
        .mem_write_in      (mdu_wb_valid ? 1'b0 : mem_write_out),
        .mdu_result_in     (mdu_result_out),
        .alu_result_in     (alu_result_out),
        .i_adder_in        (i_adder_out),
        .imm_in            (imm_out),
        .csr_wr_en_in      (mdu_wb_valid ? 1'b0 : csr_wr_en_out),
        .csr_addr_in       (csr_addr_out),
        .csr_op_in         (csr_op_out),
        .csr_data_in       (rs1_forward),
        .csr_imm_in        (rs_1_addrs_out),
        .pc_plus_4_in      (pc_plus_4_pipline1_out),
        .pc_in             (pipe2_pc),
        .instr_in          (pipe2_instr),
        .rs_2_in           (rs2_forward),
        .rd_addrs_in       (pipe2_rd),
        .funct3_in         (funct3_out),
        .wb_mux_sel_in     (pipe2_wb_sel),
        .reg_write_in      (pipe2_reg_wr),
        .rvalid            (pg_riscv32_mp_data_valid),
        .flush             (flush_de_mw),
        .mem_wb_valid      (mem_wb_valid),
        .mem_req_reg_out   (mem_req_reg_out),
        .mem_write_reg_out (mem_write_reg_out),
        .mdu_result_reg_out(mdu_result_reg_out),
        .alu_result_reg_out(alu_result_reg_out),
        .i_adder_reg_out   (i_adder_reg_out),
        .imm_reg_out       (imm_reg_out),
        .pc_plus_4_reg_out (pc_plus_4_reg_out),
        .pc_reg_out        (pc_reg_out),
        .csr_wr_en_reg_out (csr_wr_en_reg_out),
        .csr_addr_reg_out  (csr_addr_reg_out),
        .csr_op_reg_out    (csr_op_reg_out),
        .csr_data_reg_out  (csr_data_reg_out),
        .csr_imm_reg_out   (csr_imm_reg_out),
        .instr_reg_out     (instr_reg_out),
        .rs_2_reg_out      (rs_2_reg_out),
        .rd_addrs_reg_out  (rd_addrs_reg_out),
        .funct3_reg_out    (funct3_reg_out),
        .wb_mux_sel_reg_out(wb_mux_sel_reg_out),
        .reg_write_reg_out (reg_write_reg_out)
    );

    pragya_wb_mux wb_mux_inst (
        .alu_result_in (alu_result_reg_out),
        .load_data_in  (load_data_out),
        .pc_plus4_in   (pc_plus_4_reg_out),
        .imm_in        (imm_reg_out),
        .i_adder_in    (i_adder_reg_out),
        .mdu_result_in (mdu_result_reg_out),
        .csr_data_in   (csr_data_out),
        .wb_mux_sel_in (final_wb_sel),
        .wb_mux_out    (wb_mux_out)
    );

    pragya_lsu lsu_inst (
        .clk_in                  (pg_riscv32_mp_clk_in),
        .rst_in                  (pg_riscv32_mp_rst_in),
        .mem_req_in              (mem_req_reg_out),
        .mem_write_in            (mem_write_reg_out),
        .funct3_in               (funct3_reg_out),
        .i_adder_in              (i_adder_reg_out),
        .rs_2_in                 (rs_2_reg_out),
        .dm_rvalid_in            (pg_riscv32_mp_data_valid),
        .dm_rdata_in             (pg_riscv32_mp_dmdata_in),
        .pg_riscv32_mp_dmreq_out (pg_riscv32_mp_dmreq_out),
        .pg_riscv32_mp_dmwen_out (pg_riscv32_mp_dmwen_out),
        .pg_riscv32_mp_dmbe_out  (pg_riscv32_mp_dmbe_out),
        .pg_riscv32_mp_dmaddr_out(pg_riscv32_mp_dmaddr_out),
        .pg_riscv32_mp_dmdata_out(pg_riscv32_mp_dmdata_out),
        .load_data_out           (load_data_out)
    );

    reg [31:0] commit_instr_reg;
    reg [31:0] commit_pc_reg;

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            commit_instr_reg <= 32'b0;
            commit_pc_reg    <= 32'b0;
        end else begin
            commit_instr_reg <= instr_reg_out;
            commit_pc_reg    <= pc_reg_out;
        end
    end

    // Commit Interface
    assign commit_valid       = final_reg_write && (final_rd_addrs != 5'd0);
    assign commit_pc          = load_wb_valid_reg ? commit_pc_reg : pc_reg_out;
    assign commit_instr       = load_wb_valid_reg ? commit_instr_reg : instr_reg_out;
    assign commit_rd          = final_rd_addrs;
    assign commit_data        = wb_mux_out;
    assign commit_instr_valid = mem_wb_valid;
    assign commit_rs1_data    = rs1_forward;
    assign commit_rs2_data    = rs2_forward;

    // Store Commit
    wire store_commit         = mem_wb_valid && mem_req_reg_out && mem_write_reg_out;
    assign commit_store       = store_commit;
    assign commit_store_addr  = i_adder_reg_out;
    assign commit_store_be    = pg_riscv32_mp_dmbe_out;

    reg [31:0] commit_store_data_arch;
    always @(*) begin
        case (funct3_reg_out)
            3'b000:  commit_store_data_arch = {24'b0, rs_2_reg_out[7:0]};
            3'b001:  commit_store_data_arch = {16'b0, rs_2_reg_out[15:0]};
            3'b010:  commit_store_data_arch = rs_2_reg_out;
            default: commit_store_data_arch = 32'b0;
        endcase
    end

    assign commit_store_data  = commit_store_data_arch;
    assign commit_store_pc    = pc_reg_out;
    assign commit_store_instr = instr_reg_out;

endmodule
*/
`timescale 1ns / 1ps

module pragya_core(
    input          pg_riscv32_mp_clk_in,
    input          pg_riscv32_mp_rst_in,
    input          pg_riscv32_mp_debug_req_in,
    input          pg_riscv32_mp_eirq_in,
    input          pg_riscv32_mp_tirq_in,
    input          pg_riscv32_mp_sirq_in,
    input          pg_riscv32_mp_instr_valid,
    input          pg_riscv32_mp_data_valid,
    input          pg_riscv32_mp_data_gnt,
    input          pg_riscv32_mp_instr_gnt,
    input [31:0]   pg_riscv32_mp_instr_in,
    input [31:0]   pg_riscv32_mp_dmdata_in,
    
    output [31:0] pg_riscv32_mp_dmdata_out,
    output [31:0] pg_riscv32_mp_dmaddr_out,
    output [31:0] pg_riscv32_mp_imaddr_out,
    output        pg_riscv32_mp_dmwen_out,
    output [3:0]  pg_riscv32_mp_dmbe_out,
    output        pg_riscv32_mp_dmreq_out,
    output        pg_riscv32_mp_imreq_out,
    output        commit_valid,
    output [31:0] commit_pc,
    output [31:0] commit_instr,
    output [4:0]  commit_rd,
    output [31:0] commit_data,
    output        commit_store,
    output [31:0] commit_store_addr,
    output [31:0] commit_store_data,
    output [31:0] commit_store_pc,
    output [31:0] commit_store_instr,
    output [3:0]  commit_store_be,
    output        commit_instr_valid,
    output [31:0] commit_rs1_data,
    output [31:0] commit_rs2_data
);
   
    // PC outputs
    wire        misaligned_instr_out;
    wire [31:0] pc_plus_4_out;
    wire [31:0] pc_out;
  
    // Pipeline 1 outputs
    wire [31:0] id_instr;
    wire        id_valid;


// =========================================================
// Debug Interconnect Wires
// =========================================================
wire        is_dret_wire;
wire        debug_update_dpc_wire;
wire [31:0] debug_pc_save_wire;
wire [2:0]  debug_cause_wire;
wire [31:0] dpc_wire;

    // Decoder outputs
    wire [6:0]   opcode_out;
    wire [14:12] funct3_out;
    wire [31:25] funct7_out;
    wire [19:15] rs_1_addrs_out;
    wire [24:20] rs_2_addrs_out;
    wire [11:7]  rd_addrs_out;
    wire [31:7]  instr_out;
    wire [2:0]   mdu_op_out;
    wire [3:0]   alu_control_out;
    wire         reg_write_out;
    wire [2:0]   imm_src_out;
    wire         alu_src_out;
    wire         mem_write_out;
    wire         mem_req_out;
    wire [2:0]   wb_mux_sel_out;
    wire         i_adder_src_out;
    wire [6:2]   opcode6_to_2_out;
    wire [11:0]  csr_addr_out;
    wire         csr_wr_en_out;
    wire [2:0]   csr_op_out;
    wire         illegal_instr_out;
    wire         jalr;

    // Hazard unit signals
    wire        forward_a;
    wire        forward_b;
    wire        flush_DE;
    wire [31:0] rs1_forward;
    wire [31:0] rs2_forward;

    // Register file outputs
    wire [31:0] rs_1_out;  
    wire [31:0] rs_2_out;

    // Immediate generation & branch unit
    wire [31:0] imm_out;
    wire [31:0] i_adder_out;
    wire        branch_taken_out;

    // Execution unit outputs
    wire [31:0] op_2_out;
    wire [31:0] alu_result_out;
    wire [31:0] mdu_result_out;

    // CSR / Machine Control signals
    wire [31:0] csr_data_out;
    wire [31:0] epc_out;
    wire [31:0] trap_address_out;
    wire        mie_out;
    wire        trap_detected_out;
    wire [1:0]  pc_src_out;
    wire        mret_detected_out;
    wire        i_or_e_out;
    wire        set_epc_out;
    wire        set_cause_out;
    wire [3:0]  cause_out;
    wire        instret_inc_out;
    wire        mie_clear_out;
    wire        mie_set_out;
    wire [31:0] trap_value_out;
    wire        meie, mtie, msie;
    wire        meip, mtip, msip;
    wire [31:0] trap_pc_out;
    wire        wfi_stall;

// Machine-mode pipeline redirect / flush
    wire trap_redirect    = (pc_src_out == 2'b10);
    wire mret_redirect    = (pc_src_out == 2'b01);
    wire machine_redirect = trap_redirect | mret_redirect;
    
    // NEW: Detect when the PC jumps due to Debug Entry or Exit
    wire debug_redirect   = debug_update_dpc_wire | is_dret_wire;
    
    // Update flush logic to include debug_redirect
    reg wfi_stall_d;
    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) wfi_stall_d <= 1'b0;
        else wfi_stall_d <= wfi_stall;
    end
    wire wfi_wake_flush = wfi_stall_d && !wfi_stall;
    wire flush_if_id      = flush_DE | trap_detected_out | machine_redirect | mret_detected_out | debug_redirect | wfi_wake_flush;											  

    // Pipeline 2 (DE -> MW) outputs
    wire        mem_wb_valid;
    wire        mem_req_reg_out;
    wire        mem_write_reg_out;
    wire [31:0] mdu_result_reg_out;
    wire [31:0] alu_result_reg_out;
    wire [31:0] i_adder_reg_out;
    wire [31:0] imm_reg_out;
    wire [31:0] pc_plus_4_reg_out;
    wire [31:0] rs_2_reg_out;
    wire [4:0]  rd_addrs_reg_out;
    wire [2:0]  funct3_reg_out;
    wire [2:0]  wb_mux_sel_reg_out;
    wire        reg_write_reg_out;
    wire [31:0] pc_reg_out;
    wire [31:0] instr_reg_out;
    wire        csr_wr_en_reg_out;
    wire [11:0] csr_addr_reg_out;
    wire [2:0]  csr_op_reg_out;
    wire [31:0] csr_data_reg_out;
    wire [4:0]  csr_imm_reg_out;

    // WB Mux & LSU outputs
    wire [31:0] wb_mux_out;
    wire [31:0] load_data_out;

    wire stallD;
    wire [31:0] pc;
    wire [31:0] pc_plus_4_pipline1_out;
    wire flush_de_mw;
wire is_ebreak_wire;
wire        debug_mode_status_wire;
    assign pg_riscv32_mp_imaddr_out = pc;
    //assign pg_riscv32_mp_imreq_out  = ~pg_riscv32_mp_rst_in;
    assign pg_riscv32_mp_imreq_out  = ~pg_riscv32_mp_rst_in & ~wfi_stall;


    pc_unit #(
        .RESET_PC(32'h80000000),
        .DEBUG_BASE_ADDR(32'h1A110800)
    ) u_pc_unit (
        .clk                 (pg_riscv32_mp_clk_in),
        .rst                 (pg_riscv32_mp_rst_in),
        .stall               (stallD),
        .branch_taken_in     (branch_taken_out),
        .pc_target           (i_adder_out),

// NEW DEBUG ROUTING
    .debug_req_i          (pg_riscv32_mp_debug_req_in),
    .is_dret_inst         (is_dret_wire),
    .dpc_in               (dpc_wire), 
    .debug_update_dpc_o   (debug_update_dpc_wire),
    .debug_pc_save_o      (debug_pc_save_wire),
    .debug_cause_o        (debug_cause_wire),
.is_ebreak_inst (is_ebreak_wire),
        .pc_src_in           (pc_src_out),
        .epc_in              (epc_out),
        .trap_address_in     (trap_address_out),
.debug_mode_status_o  (debug_mode_status_wire),											   
        .pc                  (pc),
        .pc_plus4            (pc_plus_4_out),
        .misaligned_instr_out(misaligned_instr_out)
    );

    pragya_if_id_reg if_id_reg_inst (
        .clk_in                (pg_riscv32_mp_clk_in),
        .rst_in                (pg_riscv32_mp_rst_in),
        .pc_mux_in             (pc),
        .pc_plus_4_pipline1_in (pc_plus_4_out),
        .if_instr              (pg_riscv32_mp_instr_in),
        .if_valid              (pg_riscv32_mp_instr_valid),
        .stall_d               (stallD),
        .flush                 (flush_if_id),
        .pc_out                (pc_out),
        .pc_plus_4_pipline1_out(pc_plus_4_pipline1_out),
        .id_instr              (id_instr),
        .id_valid              (id_valid)
    );

    pragya_decoder decoder_inst (
        .instr_in         (id_instr),
        .rs_1_addrs_out   (rs_1_addrs_out),
        .rs_2_addrs_out   (rs_2_addrs_out),
        .rd_addrs_out     (rd_addrs_out),
        .instr_out        (instr_out),
        .funct3_out       (funct3_out),
        .funct7_out       (funct7_out),
        .opcode_out       (opcode_out),
        .mdu_op_out       (mdu_op_out),
        .alu_control_out  (alu_control_out),
        .reg_write_out    (reg_write_out),
        .imm_src_out      (imm_src_out),
        .alu_src_out      (alu_src_out),
        .jalr_out         (jalr),
        .mem_write_out    (mem_write_out),
        .mem_req_out      (mem_req_out),
        .wb_mux_sel_out   (wb_mux_sel_out),
        .i_adder_src_out  (i_adder_src_out),
        .opcode6_to_2_out (opcode6_to_2_out),
        .csr_addr_out     (csr_addr_out),
        .csr_wr_en_out    (csr_wr_en_out),
        .csr_op_out       (csr_op_out),
        .illegal_instr_out(illegal_instr_out),
        .is_dret_out      (is_dret_wire),
.is_ebreak_out            (is_ebreak_wire)										  
    );

    // Load Writeback 1-Cycle Delay logic
    reg        load_wb_valid_reg;
    reg [4:0]  load_wb_rd_reg;
    reg [2:0]  load_wb_sel_reg;  

    wire is_load_mw = (mem_req_reg_out && !mem_write_reg_out);

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            load_wb_valid_reg <= 1'b0;
            load_wb_rd_reg    <= 5'b0;
            load_wb_sel_reg   <= 3'b0;
        end else begin
            load_wb_valid_reg <= is_load_mw;
            load_wb_rd_reg    <= rd_addrs_reg_out;
            load_wb_sel_reg   <= wb_mux_sel_reg_out;
        end
    end

    wire [4:0] final_rd_addrs = load_wb_valid_reg ? load_wb_rd_reg  : rd_addrs_reg_out;
    wire final_reg_write      = (is_load_mw ? 1'b0 : (load_wb_valid_reg ? 1'b1 : reg_write_reg_out)) && (final_rd_addrs != 5'd0);
    wire [2:0] final_wb_sel   = load_wb_valid_reg ? load_wb_sel_reg : wb_mux_sel_reg_out;

    pragya_regfile regfile_inst (
        .clk_in       (pg_riscv32_mp_clk_in),
        .rst_in       (pg_riscv32_mp_rst_in),
        .reg_write_in (final_reg_write),
        .rs_1_addrs_in(rs_1_addrs_out),
        .rs_2_addrs_in(rs_2_addrs_out),
        .rd_addrs_in  (final_rd_addrs),
        .wb_mux_in    (wb_mux_out),
        .rs_1_out     (rs_1_out),
        .rs_2_out     (rs_2_out)
    );

    pragya_csr csr_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .csr_wr_en_in    (csr_wr_en_reg_out),
        .csr_addr_in     (csr_addr_reg_out),
        .csr_op_in       (csr_op_reg_out),
        .csr_imm_in      (csr_imm_reg_out),
        .csr_data_in     (csr_data_reg_out),
        .trap_value_in   (trap_value_out),
        .pc_in           (trap_pc_out),
        .set_epc_in      (set_epc_out),
        .set_cause_in    (set_cause_out),
        .i_or_e_in       (i_or_e_out),
        .cause_in        (cause_out),
        .mie_clear_in    (mie_clear_out),
        .mie_set_in      (mie_set_out),
        .instret_inc_in  (instret_inc_out),
        .csr_data_out    (csr_data_out),
        .epc_out         (epc_out),
        .trap_address_out(trap_address_out),
        .mie_out         (mie_out),
        .meie_out        (meie),
        .mtie_out        (mtie),
        .msie_out        (msie),
        // NEW DEBUG ROUTING
    .debug_update_dpc_in (debug_update_dpc_wire),
    .debug_pc_save_in    (debug_pc_save_wire),
    .debug_cause_in      (debug_cause_wire),
    .dpc_out             (dpc_wire)
    );

    assign meip = 1'b0;
    assign mtip = 1'b0;
    assign msip = 1'b0;

    wire retire_valid = mem_wb_valid &&
                       (instr_reg_out != 32'h00000013) &&
                       (!mem_req_reg_out || mem_write_reg_out || pg_riscv32_mp_data_valid);

    pragya_machine_control machine_control_inst (
        .clk_in             (pg_riscv32_mp_clk_in),
        .rst_in             (pg_riscv32_mp_rst_in),
.debug_req_in(pg_riscv32_mp_debug_req_in),
.debug_mode_status_in(debug_mode_status_wire),										  
        .pc_in              (pc_out),
        .id_valid_in        (id_valid),
        .mem_addr_in        (i_adder_out),
        .retire_valid_in    (retire_valid),
        .instr_in           (id_instr),
        .mret_detected_out  (mret_detected_out),
        .illegal_instr_in   (illegal_instr_out),
        .misaligned_instr_in(misaligned_instr_out),
        .opcode_6_to_2_in   (opcode_out[6:2]),
        .funct3_in          (funct3_out),
        .funct7_in          (funct7_out),
        .rs1_addr_in        (rs_1_addrs_out),
        .rs2_addr_in        (rs_2_addrs_out),
        .rd_addr_in         (rd_addrs_out),
        .trap_detected_out  (trap_detected_out),
        .trap_pc_out        (trap_pc_out),
        .trap_value_out     (trap_value_out),
        .e_irq_in           (pg_riscv32_mp_eirq_in),
        .t_irq_in           (pg_riscv32_mp_tirq_in),
        .s_irq_in           (pg_riscv32_mp_sirq_in),
        .mie_in             (mie_out),
        .meie_in            (meie),
        .mtie_in            (mtie),
        .msie_in            (msie),
        .meip_in            (meip),
        .mtip_in            (mtip),
        .msip_in            (msip),
        .i_or_e_out         (i_or_e_out),
        .set_epc_out        (set_epc_out),
        .set_cause_out      (set_cause_out),
        .cause_out          (cause_out),
        .instret_inc_out    (instret_inc_out),
        .mie_clear_out      (mie_clear_out),
        .mie_set_out        (mie_set_out),
        .pc_src_out         (pc_src_out),
        .wfi_stall_out      (wfi_stall)
    );

    wire wait_for_mem = mem_req_reg_out && !mem_write_reg_out && !pg_riscv32_mp_data_valid;

    // ============================================================
    // MDU Control & Hazard Signals
    // ============================================================
    wire        mdu_stall;
    wire        mdu_wb_valid;
    wire [4:0]  mdu_rd;
    wire [31:0] mdu_pc;
    wire [31:0] mdu_instr;
    
    // Identifies ANY MDU operation (Multiply OR Divide)
    wire        is_mdu_de = (wb_mux_sel_out == 3'b101) && id_valid;

    pragya_hazard_unit hazard_inst (
        .rs1_DE      (rs_1_addrs_out),
        .rs2_DE      (rs_2_addrs_out),
        .rd_DE       (rd_addrs_out),
        .wb_sel_DE   (wb_mux_sel_out),
        .mem_req_DE  (mem_req_out),
        .wait_for_mem(wait_for_mem),
        .wfi_stall   (wfi_stall),
	//.data_gnt    (pg_riscv32_mp_data_gnt),										  
        .mdu_stall   (mdu_stall),
        .instr_IF    (id_instr),
        .rd_MW       (final_rd_addrs),
        .reg_write_MW(final_reg_write),
        .branch_taken(branch_taken_out),
        .forward_a   (forward_a),
        .forward_b   (forward_b),
        .stallD      (stallD),
        .flush_DE    (flush_DE),
        .flush_de_mw (flush_de_mw)
    );

    pragya_imm_generator imm_gen_inst (
        .imm_gen_in(instr_out),
        .imm_src   (imm_src_out),
        .imm_out   (imm_out)
    );

    pragya_imm_adder imm_adder_inst (
        .pc_in          (pc_out),
        .rs_1_in        (rs1_forward),
        .imm_in         (imm_out),
        .jalr_in        (jalr),
        .i_adder_src_in (i_adder_src_out),
        .i_adder_out    (i_adder_out)
    );

    pragya_branch_unit branch_inst (
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .opcode6_to_2_in (opcode_out[6:2]),
        .funct3_in       (funct3_out),
        .branch_taken_out(branch_taken_out)
    );

    assign rs1_forward = forward_a ? wb_mux_out : rs_1_out;
    assign rs2_forward = forward_b ? wb_mux_out : rs_2_out;

    pragya_alu_mux alu_mux_inst (
        .rs_2_in   (rs2_forward),
        .imm_in    (imm_out),
        .alu_src_in(alu_src_out),
        .op_2_out  (op_2_out)
    );

    pragya_alu alu_inst (
        .rs_1_in       (rs1_forward),
        .rs_2_in       (op_2_out),
        .alu_control   (alu_control_out),
        .alu_result_out(alu_result_out)
    );

    pragya_mdu mdu_inst (
        .clk_in          (pg_riscv32_mp_clk_in),
        .rst_in          (pg_riscv32_mp_rst_in),
        .mdu_valid_in    (is_mdu_de),
        .rs_1_in         (rs1_forward),
        .rs_2_in         (rs2_forward),
        .mdu_op_in       (mdu_op_out),
        .rd_in           (rd_addrs_out),
        .pc_in           (pc_out),
        .instr_in        (id_instr),
        .mdu_result_out  (mdu_result_out),
        .mdu_rd_out      (mdu_rd),
        .mdu_pc_out      (mdu_pc),
        .mdu_instr_out   (mdu_instr),
        .mdu_wb_valid_out(mdu_wb_valid),
        .mdu_stall_out   (mdu_stall)
    );

    // ============================================================
    // FIX: Suppress ALL MDU operations (Multiply & Divide) on Cycle 1!
    // They ONLY enter Pipeline 2 when mdu_wb_valid pulses high!
    // ============================================================
    wire        pipe2_valid_in = mdu_wb_valid ? 1'b1 : (id_valid && !is_mdu_de && !trap_detected_out && !mret_detected_out);
    wire [4:0]  pipe2_rd       = mdu_wb_valid ? mdu_rd    : rd_addrs_out;
    wire [31:0] pipe2_pc       = mdu_wb_valid ? mdu_pc    : pc_out;
    wire [31:0] pipe2_instr    = mdu_wb_valid ? mdu_instr : id_instr;
    wire [2:0]  pipe2_wb_sel   = mdu_wb_valid ? 3'b101    : wb_mux_sel_out;
    wire        pipe2_reg_wr   = mdu_wb_valid ? (mdu_rd != 5'd0) : (reg_write_out && !is_mdu_de);

    pragya_de_mw_pipeline pipeline2_inst (
        .clk_in            (pg_riscv32_mp_clk_in),
        .rst_in            (pg_riscv32_mp_rst_in),
        .valid_de          (pipe2_valid_in),
        .stall_mw          (wait_for_mem),
        .mem_req_in        (mdu_wb_valid ? 1'b0 : mem_req_out),
        .mem_write_in      (mdu_wb_valid ? 1'b0 : mem_write_out),
        .mdu_result_in     (mdu_result_out),
        .alu_result_in     (alu_result_out),
        .i_adder_in        (i_adder_out),
        .imm_in            (imm_out),
        .csr_wr_en_in      (mdu_wb_valid ? 1'b0 : csr_wr_en_out),
        .csr_addr_in       (csr_addr_out),
        .csr_op_in         (csr_op_out),
        .csr_data_in       (rs1_forward),
        .csr_imm_in        (rs_1_addrs_out),
        .pc_plus_4_in      (pc_plus_4_pipline1_out),
        .pc_in             (pipe2_pc),
        .instr_in          (pipe2_instr),
        .rs_2_in           (rs2_forward),
        .rd_addrs_in       (pipe2_rd),
        .funct3_in         (funct3_out),
        .wb_mux_sel_in     (pipe2_wb_sel),
        .reg_write_in      (pipe2_reg_wr),
        .rvalid            (pg_riscv32_mp_data_valid),
        .flush             (flush_de_mw),
        .mem_wb_valid      (mem_wb_valid),
        .mem_req_reg_out   (mem_req_reg_out),
        .mem_write_reg_out (mem_write_reg_out),
        .mdu_result_reg_out(mdu_result_reg_out),
        .alu_result_reg_out(alu_result_reg_out),
        .i_adder_reg_out   (i_adder_reg_out),
        .imm_reg_out       (imm_reg_out),
        .pc_plus_4_reg_out (pc_plus_4_reg_out),
        .pc_reg_out        (pc_reg_out),
        .csr_wr_en_reg_out (csr_wr_en_reg_out),
        .csr_addr_reg_out  (csr_addr_reg_out),
        .csr_op_reg_out    (csr_op_reg_out),
        .csr_data_reg_out  (csr_data_reg_out),
        .csr_imm_reg_out   (csr_imm_reg_out),
        .instr_reg_out     (instr_reg_out),
        .rs_2_reg_out      (rs_2_reg_out),
        .rd_addrs_reg_out  (rd_addrs_reg_out),
        .funct3_reg_out    (funct3_reg_out),
        .wb_mux_sel_reg_out(wb_mux_sel_reg_out),
        .reg_write_reg_out (reg_write_reg_out)
    );

    pragya_wb_mux wb_mux_inst (
        .alu_result_in (alu_result_reg_out),
        .load_data_in  (load_data_out),
        .pc_plus4_in   (pc_plus_4_reg_out),
        .imm_in        (imm_reg_out),
        .i_adder_in    (i_adder_reg_out),
        .mdu_result_in (mdu_result_reg_out),
        .csr_data_in   (csr_data_out),
        .wb_mux_sel_in (final_wb_sel),
        .wb_mux_out    (wb_mux_out)
    );

	// Clear request toward OBI bus once granted for the current instruction
    reg req_granted_q;
    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in)
            req_granted_q <= 1'b0;
        else if (!mem_req_reg_out || pg_riscv32_mp_data_valid)
            req_granted_q <= 1'b0;
        else if (pg_riscv32_mp_data_gnt)
            req_granted_q <= 1'b1;
    end
    wire core_dmreq = mem_req_reg_out && !req_granted_q;																		
					  
																			
    pragya_lsu lsu_inst (
        .clk_in                  (pg_riscv32_mp_clk_in),
        .rst_in                  (pg_riscv32_mp_rst_in),
        .mem_req_in              (mem_req_reg_out),
        .mem_write_in            (mem_write_reg_out),
        .funct3_in               (funct3_reg_out),
        .i_adder_in              (i_adder_reg_out),
        .rs_2_in                 (rs_2_reg_out),
        .dm_rvalid_in            (pg_riscv32_mp_data_valid),
        .dm_rdata_in             (pg_riscv32_mp_dmdata_in),
        .pg_riscv32_mp_dmreq_out (pg_riscv32_mp_dmreq_out),
        .pg_riscv32_mp_dmwen_out (pg_riscv32_mp_dmwen_out),
        .pg_riscv32_mp_dmbe_out  (pg_riscv32_mp_dmbe_out),
        .pg_riscv32_mp_dmaddr_out(pg_riscv32_mp_dmaddr_out),
        .pg_riscv32_mp_dmdata_out(pg_riscv32_mp_dmdata_out),
        .load_data_out           (load_data_out)
    );

    reg [31:0] commit_instr_reg;
    reg [31:0] commit_pc_reg;

    always @(posedge pg_riscv32_mp_clk_in or posedge pg_riscv32_mp_rst_in) begin
        if (pg_riscv32_mp_rst_in) begin
            commit_instr_reg <= 32'b0;
            commit_pc_reg    <= 32'b0;
        end else begin
            commit_instr_reg <= instr_reg_out;
            commit_pc_reg    <= pc_reg_out;
        end
    end

    // Commit Interface
    assign commit_valid       = final_reg_write && (final_rd_addrs != 5'd0);
    assign commit_pc          = load_wb_valid_reg ? commit_pc_reg : pc_reg_out;
    assign commit_instr       = load_wb_valid_reg ? commit_instr_reg : instr_reg_out;
    assign commit_rd          = final_rd_addrs;
    assign commit_data        = wb_mux_out;
    assign commit_instr_valid = mem_wb_valid;
    assign commit_rs1_data    = rs1_forward;
    assign commit_rs2_data    = rs2_forward;

    // Store Commit
    wire store_commit         = mem_wb_valid && mem_req_reg_out && mem_write_reg_out;
    assign commit_store       = store_commit;
    assign commit_store_addr  = i_adder_reg_out;
    assign commit_store_be    = pg_riscv32_mp_dmbe_out;

    reg [31:0] commit_store_data_arch;
    always @(*) begin
        case (funct3_reg_out)
            3'b000:  commit_store_data_arch = {24'b0, rs_2_reg_out[7:0]};
            3'b001:  commit_store_data_arch = {16'b0, rs_2_reg_out[15:0]};
            3'b010:  commit_store_data_arch = rs_2_reg_out;
            default: commit_store_data_arch = 32'b0;
        endcase
    end

    assign commit_store_data  = commit_store_data_arch;
    assign commit_store_pc    = pc_reg_out;
    assign commit_store_instr = instr_reg_out;

endmodule

