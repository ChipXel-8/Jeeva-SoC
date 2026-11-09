`timescale 1ns / 1ps

module pragya_instr_mem_wrapper
(
    input         pg_riscv32_mp_clk_in,
    input         pg_riscv32_mp_rst_in,

    //========================================================
    // OBI Instruction Interface (from Core)
    //========================================================
    input         instr_req_i,
    input  [31:0] instr_addr_i,

    output        instr_gnt_o,
    output        instr_rvalid_o,
    output [31:0] instr_rdata_o
);

    //--------------------------------------------------------
    // Instruction Memory
    //--------------------------------------------------------

    pragya_imem imem
    (
        .clk_in          (pg_riscv32_mp_clk_in), // <-- ?????????? ?????? ???? ????
        .addr_in         (instr_addr_i),
        .instruction_out (instr_rdata_o)
        
    );

    //--------------------------------------------------------
    // OBI Controller
    //--------------------------------------------------------

    obi_ctrl obi
    (
        .clk     (pg_riscv32_mp_clk_in),
        .rst     (pg_riscv32_mp_rst_in),
        .req     (instr_req_i),

        .gnt    (instr_gnt_o),
        .rvalid (instr_rvalid_o)
    );


endmodule
