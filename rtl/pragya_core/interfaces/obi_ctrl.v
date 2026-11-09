`timescale 1ns / 1ps


module obi_ctrl(
    input wire clk,
    input wire rst,
    input wire req,  
    output wire gnt,
    output reg rvalid
);

    // We always grant the bus immediately
    assign gnt = 1'b1;

      always @(posedge clk or posedge rst)
    begin
        if (rst)
            rvalid <= 1'b0;
        else 
            rvalid <= req;
    end

endmodule
