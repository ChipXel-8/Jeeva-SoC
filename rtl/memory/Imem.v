`timescale 1ns / 1ps

module pragya_imem (
    input  wire        clk_in,
    input  wire        we_in,
    input  wire [3:0]  be_in,
    input  wire [31:0] wdata_in,
    input  wire [31:0] addr_in,
    output reg  [31:0] instruction_out
);

    // 8192 words x 32 bits = 32 KB IMEM
    reg [31:0] memory [0:8191];

    // Load instructions at FPGA startup
    initial begin
        $readmemh("program.mem", memory);
    end

    // Word address: bits [14:2]
    wire [12:0] word_addr = addr_in[14:2];

    always @(posedge clk_in) begin
        // Write path (for JTAG / SBA)
        if (we_in) begin
            if (be_in[0]) memory[word_addr][7:0]   <= wdata_in[7:0];
            if (be_in[1]) memory[word_addr][15:8]  <= wdata_in[15:8];
            if (be_in[2]) memory[word_addr][23:16] <= wdata_in[23:16];
            if (be_in[3]) memory[word_addr][31:24] <= wdata_in[31:24];
        end

        // Read path (for CPU instruction fetch)
        instruction_out <= memory[word_addr];
    end

endmodule
