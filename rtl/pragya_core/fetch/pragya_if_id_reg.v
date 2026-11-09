`timescale 1ns / 1ps

module pragya_if_id_reg (
    input         clk_in,
    input         rst_in,

    input  [31:0] pc_mux_in,
    input  [31:0] pc_plus_4_pipline1_in,
    input  [31:0] if_instr,
    input         if_valid,

    input         stall_d,
    input         flush,

    output reg [31:0] pc_out,
    output reg [31:0] pc_plus_4_pipline1_out,
    output     [31:0] id_instr,
    output reg        id_valid
);

    reg drop_next_instr;
    reg was_stall;      

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            drop_next_instr <= 1'b0;
            was_stall       <= 1'b0;
        end else begin
            
            if (flush && !stall_d) begin
                drop_next_instr <= 1'b1;
            end else begin
                drop_next_instr <= 1'b0;
            end

            
            was_stall <= stall_d;
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in | flush) begin
            pc_out                 <= 32'h00000000;
            pc_plus_4_pipline1_out <= 32'h00000000;
            id_valid               <= 1'b0;
        end

        else if (!stall_d) begin
    if (if_valid) begin
        pc_out                 <= pc_mux_in;
        pc_plus_4_pipline1_out <= pc_plus_4_pipline1_in;
        id_valid               <= 1'b1;
    end
    else begin
        id_valid <= 1'b0;
    end
end
end
   
    assign id_instr = (drop_next_instr | was_stall) ? 32'h00000013 : if_instr;

endmodule
