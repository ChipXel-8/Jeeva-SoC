// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

`include "common_cells/registers.svh"

/// Bootrom containing WFI trampoline, register init, trap handlers, and EOC.
/// After reset the core fetches from here:
/// 1. Enables MSIE, executes WFI, waits until woken by CLINT msip
/// 2. Clears msip, disables interrupts, clears registers x1/x3-x15
/// 3. Sets mtvec to bootrom trap handler
/// 4. Loads IMEM base address (0x1000), jumps there with jalr zero (ra = &_eoc)
/// 5. On main() return: _eoc packs retval, writes CORESTATUS, halts
module bootrom #(
    /// The OBI configuration for all ports.
    parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
    /// OBI request type
    parameter type obi_req_t = logic,
    /// OBI response type
    parameter type obi_rsp_t = logic
) (
    input  logic     clk_i,
    input  logic     rst_ni,
    input  obi_req_t obi_req_i,
    output obi_rsp_t obi_rsp_o
);

    //-----------------------------------------------------------------------------------
    // Bootrom divided into blocks per contiguous label
    //-----------------------------------------------------------------------------------
    // Contiguous block starting at 0x02000000: _start
    localparam int unsigned StartRomWords = 25;
localparam logic [31:0] StartRom [StartRomWords] = '{
        // 0x00: addi t0, x0, 8 (Enable MSIE in CSR mie)
        32'h00800293, 
        
        // --- THE FIX: PIPELINE HAZARD NOPs ---
        // Wait 2 cycles for t0 to reach the Writeback stage so csrs reads '8'
        32'h00000013, // 0x04: nop
        32'h00000013, // 0x08: nop

        // 0x0C: csrs mie, t0
        32'h3042A073, 

        // 0x10: lui  x9, 0x1       (x9 = 0x0000_1000)
        32'h000014B7, 
        
        // 0x14: nop (Safety buffer for lui)
        32'h00000013, 

        // 0x18: wfi  <-- Core enters STATE_WFI sleep!
        32'h10500073, 

        // WAKEUP ZONE
        32'h00000013, // 0x1C: nop
        32'h00000013, // 0x20: nop
        
        // 0x24: jalr x0, x9, 0  (Jump to IMEM)
        32'h00048067,
        
        // Pad the rest of the 25 words with NOPs
        32'h00000013, 32'h00000013, 32'h00000013, 32'h00000013, 32'h00000013,
        32'h00000013, 32'h00000013, 32'h00000013, 32'h00000013, 32'h00000013,
        32'h00000013, 32'h00000013, 32'h00000013, 32'h00000013, 32'h00000013
    };

    // Contiguous block starting at 0x02000100: _eoc
    localparam int unsigned EocRomWords = 5;
    localparam logic [31:0] EocRom [EocRomWords] = '{
        // <_eoc>
        32'h00151293, // 0x02000100: slli t0,a0,0x1
        32'h0012E293, // 0x02000104: ori t0,t0,1
        32'h03000337, // 0x02000108: lui t1,0x3000
        32'h00532423, // 0x0200010C: sw t0,8(t1) 
        32'h10500073  // 0x02000110: wfi
    };

    // Contiguous block starting at 0x02000200: _trap_handler_wrapper
    localparam int unsigned TrapHandlerRomWords = 22;
    localparam logic [31:0] TrapHandlerRom [TrapHandlerRomWords] = '{
        // <_trap_handler_wrapper>
        32'hFB010113, // 0x02000200: addi sp,sp,-80
        32'h04112423, // 0x02000204: sw ra,72(sp)
        32'h04512023, // 0x02000208: sw t0,64(sp)
        32'h02612C23, // 0x0200020C: sw t1,56(sp)
        32'h02712823, // 0x02000210: sw t2,48(sp)
        32'h02A12423, // 0x02000214: sw a0,40(sp)
        32'h02B12023, // 0x02000218: sw a1,32(sp)
        32'h00C12C23, // 0x0200021C: sw a2,24(sp)
        32'h00D12823, // 0x02000220: sw a3,16(sp)
        32'h00E12423, // 0x02000224: sw a4,8(sp)
        32'h00F12023, // 0x02000228: sw a5,0(sp)
        32'h100002B7, // 0x0200022C: lui t0,0x10000
        32'h34202573, // 0x02000230: csrr a0,mcause
        32'h00054863, // 0x02000234: bltz a0,2000244 <_handle_interrupt>
        32'h0042A303, // 0x02000238: lw t1,4(t0)
        32'h000300E7, // 0x0200023C: jalr t1
        32'h0C00006F, // 0x02000240: j 2000300 <_trap_exit>
        32'h00151513, // 0x02000244: slli a0,a0,0x1
        32'h00155513, // 0x02000248: srli a0,a0,0x1
        32'h0082A303, // 0x0200024C: lw t1,8(t0)
        32'h000300E7, // 0x02000250: jalr t1
        32'h0AC0006F  // 0x02000254: j 2000300 <_trap_exit>
    };

    // Contiguous block starting at 0x02000300: _trap_exit
    localparam int unsigned TrapExitRomWords = 12;
    localparam logic [31:0] TrapExitRom [TrapExitRomWords] = '{
        // <_trap_exit>
        32'h04812083, // 0x02000300: lw ra,72(sp)
        32'h04012283, // 0x02000304: lw t0,64(sp)
        32'h03812303, // 0x02000308: lw t1,56(sp)
        32'h03012383, // 0x0200030C: lw t2,48(sp)
        32'h02812503, // 0x02000310: lw a0,40(sp)
        32'h02012583, // 0x02000314: lw a1,32(sp)
        32'h01812603, // 0x02000318: lw a2,24(sp)
        32'h01012683, // 0x0200031C: lw a3,16(sp)
        32'h00812703, // 0x02000320: lw a4,8(sp)
        32'h00012783, // 0x02000324: lw a5,0(sp)
        32'h05010113, // 0x02000328: addi sp,sp,80
        32'h30200073  // 0x0200032C: mret
    };
// Contiguous block starting at 0x02000800: _debug_park_loop
    // Extracted and split from 64-bit debug_rom to 32-bit bootrom
localparam int unsigned ParkLoopRomWords = 40;
    localparam logic [31:0] ParkLoopRom [ParkLoopRomWords] = '{
        // Line 1: 64'h00000013_0180006f
        32'h0180006f, 32'h00000013, 
        
        // Line 2: 64'h00000013_0840006f
        32'h0840006f, 32'h00000013, 
        
        // Line 3: 64'h00000013_0500006f
        32'h0500006f, 32'h00000013, 
        
        // Line 4: 64'h7b241073_00000013
        32'h00000013, 32'h7b241073, 
        
        // Line 5: 64'h00000517_7b351073
        32'h7b351073, 32'h1a110537, 
        
        // Line 6: 64'h00c51513_00c55513
        32'h00c55513, 32'h00c51513, 
        
        // Line 7: 64'h10852023_f1402473
        32'hf1402473, 32'h10852023, 
        
        // Line 8: 64'h40044403_00a40433
        32'h00a40433, 32'h40044403, 
        
        // Line 9: 64'h02041c63_00147413
        32'h00147413, 32'h02041c63, 
        
        // Line 10: 64'h00a40433_f1402473
        32'hf1402473, 32'h00a40433, 
        
        // Line 11: 64'h00247413_40044403
        32'h40044403, 32'h00247413, 
        
        // Line 12: 64'hfd5ff06f_fa0418e3
        32'hfa0418e3, 32'hfd5ff06f, 
        
        // Line 13: 64'h00c55513_00000517
        32'h00000517, 32'h00c55513, 
        
        // Line 14: 64'h10052c23_00c51513
        32'h00c51513, 32'h10052c23, 
        
        // Line 15: 64'h7b202473_7b302573
        32'h7b302573, 32'h7b202473, 
        
        // Line 16: 64'h10052423_00100073
        32'h00100073, 32'h10052423, 
        
        // Line 17: 64'h7b202473_7b302573
        32'h7b302573, 32'h7b202473, 
        
        // Line 18: 64'hf1402473_a79ff06f
        32'ha79ff06f, 32'hf1402473, 
        
        // Line 19: 64'h7b302573_10852823
        32'h10852823, 32'h7b302573, 
        
        // Line 20: 64'h7b200073_7b202473
        32'h7b202473, 32'h7b200073
    };
    // --------------------------------------------------------------------------
    // Handle OBI requests
    // --------------------------------------------------------------------------
    localparam int unsigned WordAddressWidth = 10; // 12-bit byte address

    logic                        we_d, we_q;
    logic                        req_d, req_q;
    logic [ObiCfg.IdWidth-1:0]   id_d, id_q;
    logic [WordAddressWidth-1:0] word_addr_d, word_addr_q;

    assign req_d       = obi_req_i.req;
    assign we_d        = obi_req_i.a.we;
    assign id_d        = obi_req_i.a.aid;
    assign word_addr_d = obi_req_i.a.addr[WordAddressWidth+2-1:2];

    // Latch request for one-cycle response
    `FF(req_q, req_d, '0, clk_i, rst_ni)
    `FF(we_q, we_d, '0, clk_i, rst_ni)
    `FF(id_q, id_d, '0, clk_i, rst_ni)
    `FF(word_addr_q, word_addr_d, '0, clk_i, rst_ni)

    // --------------------------------------------------------------------------
    // Mask-based ROM decode:
    // - upper 4 bits of the *word address* select the ROM block
    // - lower 6 bits index the word within that block
    // --------------------------------------------------------------------------
    logic        rom_req;
    logic [ 3:0] rom_select;
    logic [ 5:0] rom_idx, rom_size;
    logic        rom_error;
    logic [31:0] rom_rdata;

    assign rom_req    = req_q && !we_q;
    assign rom_select = word_addr_q[WordAddressWidth-1 -: 4];
    assign rom_idx    = word_addr_q[5:0];

    always_comb begin
        rom_rdata = 32'h0000_0000;
        rom_error = 1'b1;

        case (rom_select)
            4'b0000: rom_size  = StartRomWords;
            4'b0001: rom_size  = EocRomWords;
            4'b0010: rom_size  = TrapHandlerRomWords;
            4'b0011: rom_size  = TrapExitRomWords;
            4'b1000: rom_size  = ParkLoopRomWords; // NEW: Maps to offset 0x0800
            default: rom_size = 6'h00;
        endcase

        rom_error = (rom_idx >= rom_size);

        if (!rom_error && rom_req) begin
            case (rom_select)
                4'b0000: rom_rdata = StartRom[rom_idx];
                4'b0001: rom_rdata = EocRom[rom_idx];
                4'b0010: rom_rdata = TrapHandlerRom[rom_idx];
                4'b0011: rom_rdata = TrapExitRom[rom_idx];
                4'b1000: rom_rdata = ParkLoopRom[rom_idx]; // NEW: Fetches Park Loop instructions
                default: rom_rdata = 32'h0000_0000;
            endcase
        end
    end

    always_comb begin
        obi_rsp_o         = '0;
        obi_rsp_o.gnt     = 1'b1; // always grant
        obi_rsp_o.rvalid  = req_q;
        obi_rsp_o.r.rid   = id_q;
        if (we_q) begin
            // write request
            obi_rsp_o.r.rdata = 32'hBADCAB1E;
            obi_rsp_o.r.err   = 1'b1;
        end else begin
            obi_rsp_o.r.rdata = rom_rdata;
            obi_rsp_o.r.err   = rom_error;
        end
    end

endmodule

