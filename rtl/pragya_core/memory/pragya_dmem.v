`timescale 1ns / 1ps
module pragya_dmem #(
    parameter [31:0] DMEM_BASE = 32'h00008000
)(
    input         clk_in,
    input         dm_req_in,
    input         dm_wen_in,
    input  [3:0]  dm_be_in,
    input  [31:0] dm_addr_in,
    input  [31:0] dm_wdata_in,
    output reg [31:0] dm_rdata_out
);
    // 64 KB data memory, word-addressed (16384 words x 32 bits)
    reg [31:0] memory [0:16383];

    wire [13:0] word_addr;
    assign word_addr = (dm_addr_in - DMEM_BASE) >> 2;

    initial begin
        $readmemh("data.mem", memory);
    end

    always @(posedge clk_in) begin
        if (dm_req_in && dm_wen_in) begin
            if (dm_be_in[0]) memory[word_addr][7:0]   <= dm_wdata_in[7:0];
            if (dm_be_in[1]) memory[word_addr][15:8]  <= dm_wdata_in[15:8];
            if (dm_be_in[2]) memory[word_addr][23:16] <= dm_wdata_in[23:16];
            if (dm_be_in[3]) memory[word_addr][31:24] <= dm_wdata_in[31:24];
        end
        dm_rdata_out <= memory[word_addr];
    end
endmodule
