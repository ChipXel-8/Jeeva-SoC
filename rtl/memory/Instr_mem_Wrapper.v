module pragya_instr_mem_wrapper (
    input         pg_riscv32_mp_clk_in,
    input         pg_riscv32_mp_rst_in,

    input         instr_req_i,
    input         instr_we_i,
    input  [3:0]  instr_be_i,
    input  [31:0] instr_addr_i,
    input  [31:0] instr_wdata_i,

    output        instr_gnt_o,
    output        instr_rvalid_o,
    output [31:0] instr_rdata_o
);
    // IMPORTANT: only an accepted OBI write may modify IMEM.
    pragya_imem imem (
        .clk_in          (pg_riscv32_mp_clk_in),
        .we_in           (instr_req_i && instr_gnt_o && instr_we_i),
        .be_in           (instr_be_i),
        .wdata_in        (instr_wdata_i),
        .addr_in         (instr_addr_i),
        .instruction_out (instr_rdata_o)
    );

    obi_ctrl obi (
        .clk    (pg_riscv32_mp_clk_in),
        .rst    (pg_riscv32_mp_rst_in),
        .req    (instr_req_i),
        .gnt    (instr_gnt_o),
        .rvalid (instr_rvalid_o)
    );

 always @(posedge pg_riscv32_mp_clk_in) begin

    if (!pg_riscv32_mp_rst_in &&
        instr_req_i &&
        instr_gnt_o &&
        instr_we_i) begin

        $display(
            "[IMEM DEBUG] Time=%0t ns | Write Addr=0x%08h | Write Data=0x%08h",
            $time,
            instr_addr_i,
            instr_wdata_i
        );

    end

end

endmodule

