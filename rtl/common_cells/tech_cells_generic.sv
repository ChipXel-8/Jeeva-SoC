`timescale 1ns / 1ps

module tc_clk_inverter (
  input  logic clk_i,
  output logic clk_o
);
  assign clk_o = ~clk_i;
endmodule

module tc_clk_mux2 (
  input  logic clk0_i,
  input  logic clk1_i,
  input  logic clk_sel_i,
  output logic clk_o
);
  assign clk_o = clk_sel_i ? clk1_i : clk0_i;
endmodule

module tc_sync #(
  parameter int unsigned Stages = 2,
  parameter int unsigned STAGES = Stages
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic serial_i,
  output logic serial_o
);
  logic [Stages-1:0] reg_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_q <= '0;
    end else begin
      reg_q <= {reg_q[Stages-2:0], serial_i};
    end
  end

  assign serial_o = reg_q[Stages-1];
endmodule
