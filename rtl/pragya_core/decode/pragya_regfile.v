`timescale 1ns / 1ps

module pragya_regfile(

    input wire clk_in,
    input wire rst_in,
    input wire reg_write_in,                 // from decoder

    input wire [4:0] rs_1_addrs_in,          // from decoder
    input wire [4:0] rs_2_addrs_in,          // from decoder
    input wire [4:0] rd_addrs_in,           // from decoder

    input wire [31:0] wb_mux_in,          // from wb_mux

    output reg  [31:0] rs_1_out,        // to alu, to mdu
    output reg [31:0] rs_2_out         // to alu, to mdu
    );

    reg [31:0] regfile [0:31];     // // 32 registers of 32 bits each

    integer i;

    //========================================================
    // Reset logic
    //========================================================
    always @(posedge clk_in or posedge rst_in)
        begin
            if (rst_in)
                begin
                    for (i = 0; i < 32; i = i + 1)
                        regfile[i] <= 32'b0;
                end

     //====================================================
     // Write operation
     //====================================================
            else if (reg_write_in && (rd_addrs_in != 5'b00000))
                begin
                        regfile[rd_addrs_in] <= wb_mux_in;
                end
        end

//=====================================================
// Read operation
//=====================================================
always @(*) begin
    if (rs_1_addrs_in == 5'd0)
        rs_1_out = 32'b0;
    else
        rs_1_out = regfile[rs_1_addrs_in];

    if (rs_2_addrs_in == 5'd0)
        rs_2_out = 32'b0;
    else
        rs_2_out = regfile[rs_2_addrs_in];
end


endmodule
