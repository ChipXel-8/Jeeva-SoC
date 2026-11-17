`timescale 1ns / 1ps

module pragya_dmem (
    input  wire        clk_in,
    input  wire        dm_req_in,
    input  wire        dm_wen_in,
    input  wire [3:0]  dm_be_in,
    input  wire [31:0] dm_addr_in,
    input  wire [31:0] dm_wdata_in,
    output reg  [31:0] dm_rdata_out
);

    // 16384 words x 32 bits = 64 KB Word-Addressed Memory
    reg [31:0] memory [0:16383];

    // Word index: drops the lower 2 byte-offset bits (addr / 4)
    wire [13:0] word_addr = dm_addr_in[15:2];

    always @(posedge clk_in) begin
        // STORE (Byte-enabled write into a 32-bit word slot)
        if (dm_req_in && dm_wen_in) begin
            if (dm_be_in[0]) memory[word_addr][7:0]   <= dm_wdata_in[7:0];
            if (dm_be_in[1]) memory[word_addr][15:8]  <= dm_wdata_in[15:8];
            if (dm_be_in[2]) memory[word_addr][23:16] <= dm_wdata_in[23:16];
            if (dm_be_in[3]) memory[word_addr][31:24] <= dm_wdata_in[31:24];
        end

        // LOAD (Single 32-bit word read)
        dm_rdata_out <= memory[word_addr];
    end
always @(posedge clk_in) begin
    if (dm_req_in) begin
        if (dm_wen_in) begin
            $display(
                "[DMEM INTERNAL WRITE] time=%0t addr=%08h index=%0d BE=%b WDATA=%08h",
                $time, dm_addr_in, word_addr, dm_be_in, dm_wdata_in
            );
        end
        else begin
            $display(
                "[DMEM INTERNAL READ] time=%0t addr=%08h index=%0d MEM=%08h",
                $time, dm_addr_in, word_addr, memory[word_addr]
            );
        end
    end
end
endmodule  /*

`timescale 1ns / 1ps

module pragya_dmem (
    input  wire        clk_in,
    input  wire        dm_req_in,
    input  wire        dm_gnt_in,
    input  wire        dm_wen_in,
    input  wire [3:0]  dm_be_in,
    input  wire [31:0] dm_addr_in,
    input  wire [31:0] dm_wdata_in,
    output reg  [31:0] dm_rdata_out
);

    reg [31:0] memory [0:16383];

    wire [13:0] word_addr = dm_addr_in[15:2];

    always @(posedge clk_in) begin

        if (dm_req_in && dm_gnt_in) begin

            if (dm_wen_in) begin

                if (dm_be_in[0])
                    memory[word_addr][7:0] <= dm_wdata_in[7:0];

                if (dm_be_in[1])
                    memory[word_addr][15:8] <= dm_wdata_in[15:8];

                if (dm_be_in[2])
                    memory[word_addr][23:16] <= dm_wdata_in[23:16];

                if (dm_be_in[3])
                    memory[word_addr][31:24] <= dm_wdata_in[31:24];

            end
            else begin

                dm_rdata_out <= memory[word_addr];

            end

        end
    end
always @(posedge clk_in) begin
    if (dm_req_in) begin
        if (dm_wen_in) begin
            $display(
                "[DMEM INTERNAL WRITE] time=%0t addr=%08h index=%0d BE=%b WDATA=%08h",
                $time, dm_addr_in, word_addr, dm_be_in, dm_wdata_in
            );
        end
        else begin
            $display(
                "[DMEM INTERNAL READ] time=%0t addr=%08h index=%0d MEM=%08h",
                $time, dm_addr_in, word_addr, memory[word_addr]
            );
        end
    end
end
endmodule */

