
module pragya_data_mem_wrapper
(
    input         pg_riscv32_mp_clk_in,
    input         pg_riscv32_mp_rst_in,

    //========================================================
    // OBI Data Interface (from Core)
    //========================================================
    input         data_req_i,
    input         data_we_i,
    input  [3:0]  data_be_i,
    input  [31:0] data_addr_i,
    input  [31:0] data_wdata_i,

    output        data_gnt_o,
    output        data_rvalid_o,
    output [31:0] data_rdata_o
);

    //--------------------------------------------------------
    // Data Memory
    //--------------------------------------------------------
pragya_dmem dmem (
    .clk_in       (pg_riscv32_mp_clk_in),
    .dm_req_in    (data_req_i),
   // .dm_gnt_in    (data_gnt_o),
    .dm_wen_in    (data_we_i),
    .dm_be_in     (data_be_i),
    .dm_addr_in   (data_addr_i),
    .dm_wdata_in  (data_wdata_i),
    .dm_rdata_out (data_rdata_o)
);
 
    //--------------------------------------------------------
    // OBI Controller
    //--------------------------------------------------------

    obi_ctrl obi
    (
        .clk     (pg_riscv32_mp_clk_in),
        .rst     (pg_riscv32_mp_rst_in),
        .req     (data_req_i),

        .gnt    (data_gnt_o),
        .rvalid (data_rvalid_o)
    );

endmodule
