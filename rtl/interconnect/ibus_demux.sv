`include "obi/typedef.svh"
`include "obi/assign.svh"
`include "common_cells/registers.svh"
`include "axi/typedef.svh"
`include "axi/assign.svh"

import obi_pkg::*;
import axi_pkg::*;
import clint_reg_pkg::*; 

module ibus_demux (
    input  logic        clk,
    input  logic        rst_n,

    // ---------------------------------------------------------
    // MASTER PORT (From RISC-V Core Instruction Bus)
    // ---------------------------------------------------------
    input  logic        core_req_i,
    input  logic [31:0] core_addr_i,
    output logic        core_gnt_o,
    output logic        core_rvalid_o,
    output logic [31:0] core_rdata_o,

    // ---------------------------------------------------------
    // SLAVE PORT 0: IMEM Wrapper
    // ---------------------------------------------------------
    output logic        imem_req_o,
    input  logic        imem_gnt_i,
    input  logic        imem_rvalid_i,
    input  logic [31:0] imem_rdata_i,

    // ---------------------------------------------------------
    // SLAVE PORT 1: BOOT ROM
    // ---------------------------------------------------------
    output logic        boot_req_o,
    input  logic        boot_gnt_i,
    input  logic        boot_rvalid_i,
    input  logic [31:0] boot_rdata_i,

    // ---------------------------------------------------------
    // SLAVE PORT 2: Debug ROM
    // ---------------------------------------------------------
    output logic        dbg_req_o,
    input  logic        dbg_gnt_i,
    input  logic        dbg_rvalid_i,
    input  logic [31:0] dbg_rdata_i
);

    // Address Map Parameters 
    parameter BOOT_BASE = 32'h0000_0000; 
    parameter BOOT_MASK = 32'h0000_0FFF;
    
    parameter DBG_BASE  = 32'h1A11_0800; 
    parameter DBG_MASK  = 32'hFFFF_F000; 
    
    // Internal selection signals
    logic [1:0] sel_d; 
    logic [1:0] sel_q; 

   // =========================================================
    // 1. ADDRESS DECODING (Address Phase)
    // =========================================================
    always_comb begin
        // Default to IMEM (Port 0)
        sel_d = 2'd0; 
        
        // INTERCEPT: Route 0x1A11XXXX OR the 0x300 Execution Jump to the Debug Module
        if (((core_addr_i & DBG_MASK) == (DBG_BASE & DBG_MASK)) ||
            (core_addr_i >= 32'h0000_0300 && core_addr_i < 32'h0000_0400)) begin
            sel_d = 2'd2; // Select Debug Module
        end 
        // Standard Boot ROM (Everything below 0x1000 except 0x300-0x3FF)
        else if (core_addr_i < 32'h0000_1000) begin
            sel_d = 2'd1; // Select BOOT ROM 
        end 
    end

    // =========================================================
    // 2. REQUEST & GRANT ROUTING (Address Phase)
    // =========================================================
    assign imem_req_o = (sel_d == 2'd0) ? core_req_i : 1'b0;
    assign boot_req_o = (sel_d == 2'd1) ? core_req_i : 1'b0;
    assign dbg_req_o  = (sel_d == 2'd2) ? core_req_i : 1'b0;

    always_comb begin
        case (sel_d)
            2'd0: core_gnt_o = (imem_gnt_i === 1'b1) ? 1'b1 : 1'b0;
            2'd1: core_gnt_o = (boot_gnt_i === 1'b1) ? 1'b1 : 1'b0;
            2'd2: core_gnt_o = (dbg_gnt_i === 1'b1) ? 1'b1 : 1'b0;
            default: core_gnt_o = 1'b0;
        endcase
    end

    
 // =========================================================
    // 3. PIPELINE REGISTER (Tracking active transaction)
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_q <= 2'd0;
        end else if (core_req_i && core_gnt_o) begin
            sel_q <= sel_d;
        end
    end
    
    // =========================================================
    // 4. RESPONSE ROUTING (Data Phase)
    // =========================================================
    always_comb begin
        case (sel_q)
            2'd0: begin
                core_rvalid_o = (imem_rvalid_i === 1'b1) ? 1'b1 : 1'b0;
                core_rdata_o  = imem_rdata_i;
            end
            2'd1: begin
                core_rvalid_o = (boot_rvalid_i === 1'b1) ? 1'b1 : 1'b0;
                core_rdata_o  = boot_rdata_i;
            end
            2'd2: begin
                core_rvalid_o = (dbg_rvalid_i === 1'b1) ? 1'b1 : 1'b0;
                core_rdata_o  = dbg_rdata_i;
            end
            default: begin
                core_rvalid_o = 1'b0;
                core_rdata_o  = 32'h0;
            end
        endcase
    end
  
endmodule
