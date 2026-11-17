`timescale 1ns / 1ps

// ============================================================================
// Module Name: obi_ctrl
// Author     : chipXel team
// Description: Open Bus Interface (OBI) simple controller.
//              This module immediately grants bus access upon request and 
//              generates a registered valid signal (rvalid) based on the 
//              incoming request signal.
// ============================================================================

module obi_ctrl(
    input wire clk,      // System clock
    input wire rst,      // Active-high asynchronous reset
    input wire req,      // Request signal from the master
    output wire gnt,     // Grant signal to the master
    output reg rvalid    // Registered valid signal for read/write response
);

    // We always grant the bus immediately
    assign gnt = 1'b1;

    // Sequential logic block to register the request signal
    always @(posedge clk or posedge rst)
    begin
        if (rst)
            rvalid <= 1'b0; // Reset rvalid to 0 on reset
        else 
            rvalid <= req;  // Pass the request to rvalid on the next clock edge
    end

endmodule
