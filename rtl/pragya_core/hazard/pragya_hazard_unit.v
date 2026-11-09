/*module pragya_hazard_unit
(
    input  [4:0] rs1_DE,
    input  [4:0] rs2_DE,
    input  [4:0] rd_DE,
    input  [2:0] wb_sel_DE,
    input        mem_req_DE,
    input        wait_for_mem,
    input        mdu_stall,      // <-- ADD THIS

    input  [31:0] instr_IF,
    input  [4:0]  rd_MW,
    input         reg_write_MW,
    input         branch_taken,

    output        forward_a,
    output        forward_b,
    output        stallD,
    output        flush_DE,
    output        flush_de_mw
);

    wire [4:0] rs1_IF = instr_IF[19:15];
    wire [4:0] rs2_IF = instr_IF[24:20];

    assign forward_a = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs1_DE);
    assign forward_b = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs2_DE);

    wire stall_mem_op = mem_req_DE;

    // Stall IF stage & PC when Memory or MDU is waiting
    assign stallD = stall_mem_op | wait_for_mem | mdu_stall; // <-- UPDATED

    assign flush_DE = branch_taken;
    assign flush_de_mw = 1'b0;

endmodule*/

module pragya_hazard_unit
(
    input  [4:0] rs1_DE,
    input  [4:0] rs2_DE,
    input  [4:0] rd_DE,
    input  [2:0] wb_sel_DE,
    input        mem_req_DE,
    input        wait_for_mem,
    input        mdu_stall,
    input        wfi_stall,     // <-- 1. YEH INPUT ADD KAREIN

    input  [31:0] instr_IF,
    input  [4:0]  rd_MW,
    input         reg_write_MW,
    input         branch_taken,

    output        forward_a,
    output        forward_b,
    output        stallD,
    output        flush_DE,
    output        flush_de_mw
);

    wire [4:0] rs1_IF = instr_IF[19:15];
    wire [4:0] rs2_IF = instr_IF[24:20];

    assign forward_a = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs1_DE);
    assign forward_b = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs2_DE);

    wire stall_mem_op = mem_req_DE;

    // IF stage & PC ko WFI me bhi freeze karein
    assign stallD = stall_mem_op | wait_for_mem | mdu_stall | wfi_stall; // <-- 2. YAHAN OR (|) KAREIN

    assign flush_DE = branch_taken;
    assign flush_de_mw = 1'b0;

endmodule

/*`timescale 1ns / 1ps
module pragya_hazard_unit
(
    input  [4:0] rs1_DE,
    input  [4:0] rs2_DE,
    input  [4:0] rd_DE,
    input  [2:0] wb_sel_DE,
    input        mem_req_DE,
    input        wait_for_mem,
    input        mdu_stall,
    input        wfi_stall,     // <-- 1. YEH INPUT ADD KAREIN
    input        data_gnt,

    input  [31:0] instr_IF,
    input  [4:0]  rd_MW,
    input         reg_write_MW,
    input         branch_taken,

    output        forward_a,
    output        forward_b,
    output        stallD,
    output        flush_DE,
    output        flush_de_mw
);

    wire [4:0] rs1_IF = instr_IF[19:15];
    wire [4:0] rs2_IF = instr_IF[24:20];

    assign forward_a = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs1_DE);
    assign forward_b = reg_write_MW && (rd_MW != 5'd0) && (rd_MW == rs2_DE);

    wire stall_mem_op = mem_req_DE;

// If memory requested but not granted yet, must stall pipeline 
   wire ungranted_mem = mem_req_DE && !data_gnt;

    // IF stage & PC ko WFI me bhi freeze karein
    assign stallD = stall_mem_op | wait_for_mem | mdu_stall | wfi_stall; // <-- 2. YAHAN OR (|) KAREIN

    assign flush_DE = branch_taken;
    assign flush_de_mw = 1'b0;

endmodule*/
