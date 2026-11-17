`timescale 1ns / 1ps

// Passive monitor for the simple OBI-like interface used in this project.
// Samples request/grant at the rising edge, then checks registered rvalid
// one simulation time unit later (after the DUT's nonblocking assignments).
module obi_monitor #(
    parameter NAME = "OBI"
) (
    input wire        clk,
    input wire        rst,
    input wire        req,
    input wire        gnt,
    input wire        we,
    input wire [31:0] addr,
    input wire [3:0]  be,
    input wire [31:0] wdata,
    input wire        rvalid,
    input wire [31:0] rdata
);

    integer accepted_count;
    integer read_count;
    integer write_count;
    integer response_count;
    integer protocol_errors;

    reg accepted_this_edge;

    initial begin
        accepted_count  = 0;
        read_count      = 0;
        write_count     = 0;
        response_count  = 0;
        protocol_errors = 0;
        accepted_this_edge = 1'b0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accepted_this_edge = 1'b0;
        end else begin
            // Capture the handshake before the DUT updates registered outputs.
            accepted_this_edge = (req === 1'b1 && gnt === 1'b1);

            if (accepted_this_edge) begin
                accepted_count = accepted_count + 1;

                if (we === 1'b1) begin
                    write_count = write_count + 1;
                    $display("[%0s MONITOR] ACCEPT WRITE t=%0t addr=%08h be=%b wdata=%08h",
                             NAME, $time, addr, be, wdata);
                end else if (we === 1'b0) begin
                    read_count = read_count + 1;
                    $display("[%0s MONITOR] ACCEPT READ  t=%0t addr=%08h be=%b",
                             NAME, $time, addr, be);
                end else begin
                    protocol_errors = protocol_errors + 1;
                    $error("[%0s MONITOR] Unknown write-enable value at %0t",
                           NAME, $time);
                end
            end

            // The DUT's nonblocking assignments execute before this sample.
            // For the supplied controller, rvalid must now match this edge's
            // accepted request.
            #1;
            if (rvalid !== accepted_this_edge) begin
                protocol_errors = protocol_errors + 1;
                $error("[%0s MONITOR] rvalid mismatch at %0t: expected=%b actual=%b",
                       NAME, $time, accepted_this_edge, rvalid);
            end

            if (rvalid === 1'b1)
                response_count = response_count + 1;
        end
    end

endmodule
