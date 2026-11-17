`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_csr
// Author     : chipXel team
// Description: Control and Status Registers (CSR) for the pragya processor.
//              Handles machine-mode CSRs (MSTATUS, MIE, MTVEC, MEPC, MCAUSE),
//              performance counters (MCYCLE, MINSTRET), and debug mode CSRs 
//              (DCSR, DPC, DSCRATCH). Supports CSR read/write operations and
//              trap generation state updates.
// ============================================================================

module pragya_csr ( 
    input          clk_in,
    input          rst_in,

    // ========================================================
    // Hardware Debug Inputs
    // ========================================================
    input wire         debug_update_dpc_in,   // High when entering debug mode to save PC
    input wire  [31:0] debug_pc_save_in,      // The PC value to save into dpc
    input wire  [2:0]  debug_cause_in,        // Halt cause

    // ========================================================
    // CSR Instruction Interface (from Decoder & Execute)
    // ========================================================
    input          csr_wr_en_in, // Write enable from decoder
    input [11:0]   csr_addr_in,  // CSR address from decoder
    input [2:0]    csr_op_in,    // CSR operation type from decoder
    input [4:0]    csr_imm_in,   // Immediate value for CSR operations
    input [31:0]   csr_data_in,  // Data from register file

    // ========================================================
    // Trap Control Inputs
    // ========================================================
    input [31:0]   pc_in,        // Current Program Counter
    input          set_epc_in,   // Set Exception Program Counter flag
    input          set_cause_in, // Set exception cause flag
    input          i_or_e_in,    // Interrupt (1) or Exception (0) indicator
    input [3:0]    cause_in,     // Exception/Interrupt cause code
    input          mie_clear_in, // Clear Machine Interrupt Enable
    input          mie_set_in,   // Set Machine Interrupt Enable
    input [31:0]   trap_value_in,// Additional trap information (e.g., faulting address)

    // ========================================================
    // Counter Inputs
    // ========================================================
    input          instret_inc_in,  // Increment instructions retired counter
    
    // ========================================================
    // Outputs
    // ========================================================
    output reg [31:0] csr_data_out,     // Data read from CSR, sent to writeback mux
    output     [31:0] epc_out,          // Exception Program Counter output to PC unit
    output     [31:0] trap_address_out, // Trap vector address output to PC unit
    output reg        mie_out,          // Machine Interrupt Enable state
    output     [31:0] dpc_out,          // Debug Program Counter output
    output            meie_out,         // Machine External Interrupt Enable
    output            mtie_out,         // Machine Timer Interrupt Enable
    output            msie_out          // Machine Software Interrupt Enable
);

    // ========================================================
    // CSR Registers (Machine Mode)
    // ========================================================
    reg [31:0] mie;       // Machine Interrupt Enable Register
    reg [31:0] misa;      // Machine ISA Register
    reg [31:0] mepc;      // Machine Exception Program Counter
    reg [31:0] mcause;    // Machine Cause Register
    reg [31:0] mtval;     // Machine Trap Value Register
    reg [31:0] mscratch;  // Machine Scratch Register
    reg [31:0] mip;       // Machine Interrupt Pending Register
    reg [63:0] mcycle;    // Machine Cycle Counter
    reg [63:0] minstret;  // Machine Instructions Retired Counter
    reg [31:0] pmpaddr16; // Physical Memory Protection Address Register 16
        
    // ========================================================
    // CSR Registers (Debug Mode)
    // ========================================================
    reg [31:0] dcsr;      // Debug Control and Status Register
    reg [31:0] dpc;       // Debug Program Counter
    reg [31:0] dscratch0; // Debug Scratch Register 0
    reg [31:0] dscratch1; // Debug Scratch Register 1

    // Internal signals for CSR updates
    reg [31:0]   csr_wdata; // Data to be written to the selected CSR
    reg          mpie_out;  // Machine Previous Interrupt Enable
    wire [31:0]  mstatus_out;
    wire [31:0]  mtvec_out;
    wire [31:0]  misa_out;
    
    // Machine Trap Vector (MTVEC) components
    reg  [1:0 ] mtvec_mode; // 00 = Direct, 01 = Vectored
    reg  [29:0] mtvec_base; // Base address for traps
   
    // Trap address resolution wires
    wire [31:0] trap_mux_out;
    wire [31:0] vec_mux_out;
    wire [31:0] base_offset;

    // Default values for MISA (RV32IM architecture)
    localparam [31:0] MISA_RESET          = 32'h40001100; // Sets RV32, I, and M extensions
    localparam [31:0] MISA_SUPPORTED_MASK = 32'h40001100;

    // ========================================================
    // CSR Write Validation Logic
    // ========================================================
    // Determines if a valid CSR write operation is requested
    wire csr_do_write;
    assign csr_do_write =
        csr_wr_en_in &&
        (
            (csr_op_in == 3'b001) ||                                 // CSRRW (Write)
            (csr_op_in == 3'b101) ||                                 // CSRRWI (Write Immediate)
            ((csr_op_in == 3'b010) && (csr_data_in != 32'b0)) ||     // CSRRS (Set - only if data != 0)
            ((csr_op_in == 3'b011) && (csr_data_in != 32'b0)) ||     // CSRRC (Clear - only if data != 0)
            ((csr_op_in == 3'b110) && (csr_imm_in != 5'b0)) ||       // CSRRSI (Set Immediate - only if imm != 0)
            ((csr_op_in == 3'b111) && (csr_imm_in != 5'b0))          // CSRRCI (Clear Immediate - only if imm != 0)
        );
    
    // ========================================================
    // CSR Address Definitions (Standard RISC-V Map)
    // ========================================================
    // Performance Counters (Read Only versions for user space)
    parameter CYCLE     = 12'hC00;
    parameter INSTRET   = 12'hC02;
    parameter CYCLEH    = 12'hC80;
    parameter INSTRETH  = 12'hC82;
   
    // Machine Trap Setup
    parameter MSTATUS   = 12'h300;
    parameter MIE       = 12'h304;
    parameter MISA      = 12'h301;
    parameter MTVEC     = 12'h305;
    parameter MVENDORID = 12'hF11;
    parameter MARCHID   = 12'hF12;
    parameter MIMPID    = 12'hF13;
    parameter MHARTID   = 12'hF14;
   
    // Machine Trap Handling
    parameter MSCRATCH  = 12'h340;
    parameter MEPC      = 12'h341;
    parameter MCAUSE    = 12'h342;
    parameter MTVAL     = 12'h343;
    parameter MIP       = 12'h344;  
    parameter PMPADDR16 = 12'h3C0;

    // Machine Counter / Timers
    parameter MCYCLE    = 12'hB00;
    parameter MINSTRET  = 12'hB02;
    parameter MCYCLEH   = 12'hB80;
    parameter MINSTRETH = 12'hB82;

    // Debug CSR Addresses
    parameter DCSR      = 12'h7B0;
    parameter DPC       = 12'h7B1;
    parameter DSCRATCH0 = 12'h7B2;
    parameter DSCRATCH1 = 12'h7B3;
   
    // ========================================================
    // Combinational Output Assignments
    // ========================================================
    
    // Trap Vector Address Calculation
    assign base_offset      = cause_in << 2; // Word-aligned offset based on cause
    assign mtvec_out        = {mtvec_base, mtvec_mode};
    
    // Select base address or vectored address based on mode and interrupt/exception type
    assign vec_mux_out      = mtvec_out[0] ? {mtvec_base, 2'b00} + base_offset : {mtvec_base, 2'b00};
    assign trap_mux_out     = i_or_e_in ? vec_mux_out : {mtvec_base, 2'b00}; // Exceptions always use base
    assign trap_address_out = trap_mux_out;
    
    // Interrupt enable signals mapping from MIE register
    assign meie_out         = mie[11];
    assign mtie_out         = mie[7];
    assign msie_out         = mie[3];
    
    // Assemble MSTATUS register (Simplified: only MIE and MPIE fields are active)
    assign mstatus_out      = {19'b0, 2'b11, 3'b0, mpie_out, 3'b0 , mie_out, 3'b0};
    
    // Assign program counters and architecture information
    assign epc_out          = mepc;
    assign misa_out         = misa;
    assign dpc_out          = dpc;

    // ========================================================
    // CSR Read Logic (Combinational)
    // ========================================================
    always @(*) begin
        case (csr_addr_in)
            CYCLE:      csr_data_out = mcycle[31:0];
            CYCLEH:     csr_data_out = mcycle[63:32];
            INSTRET:    csr_data_out = minstret[31:0];
            INSTRETH:   csr_data_out = minstret[63:32];
            MSTATUS:    csr_data_out = mstatus_out;
            MISA:       csr_data_out = misa_out;
            MIE:        csr_data_out = mie;
            MTVEC:      csr_data_out = mtvec_out;
            MSCRATCH:   csr_data_out = mscratch;
            MEPC:       csr_data_out = mepc;
            MCAUSE:     csr_data_out = mcause;
            MTVAL:      csr_data_out = mtval;
            MIP:        csr_data_out = mip;
            MCYCLE:     csr_data_out = mcycle[31:0];
            MCYCLEH:    csr_data_out = mcycle[63:32];
            MINSTRET:   csr_data_out = minstret[31:0];
            MINSTRETH:  csr_data_out = minstret[63:32];
            
            // Hardcoded Architecture IDs
            MVENDORID:  csr_data_out = 32'h00000000; // Non-commercial
            MARCHID:    csr_data_out = 32'h00000005; // ID assigned to this core
            MIMPID:     csr_data_out = 32'h00000000;
            MHARTID:    csr_data_out = 32'h00000000; // Single hart
            
            PMPADDR16:  csr_data_out = pmpaddr16;
            DCSR:       csr_data_out = dcsr;
            DPC:        csr_data_out = dpc;
            DSCRATCH0:  csr_data_out = dscratch0;
            DSCRATCH1:  csr_data_out = dscratch1;
            default:    csr_data_out = 32'b0; // Default zero for unimplemented CSRs
        endcase
    end

    // ========================================================
    // CSR Write Data Selection Logic (Combinational)
    // Determines the final value to write based on the CSR operation
    // ========================================================
    always @(*) begin
        case (csr_op_in)
            3'b001:  csr_wdata = csr_data_in;                          // CSRRW  (Write data)
            3'b010:  csr_wdata = csr_data_out | csr_data_in;           // CSRRS  (Set bits in rs1)
            3'b011:  csr_wdata = csr_data_out & ~csr_data_in;          // CSRRC  (Clear bits in rs1)
            3'b101:  csr_wdata = {27'b0, csr_imm_in};                  // CSRRWI (Write immediate)
            3'b110:  csr_wdata = csr_data_out | {27'b0, csr_imm_in};   // CSRRSI (Set immediate bits)
            3'b111:  csr_wdata = csr_data_out & ~{27'b0, csr_imm_in};  // CSRRCI (Clear immediate bits)
            default: csr_wdata = csr_data_out;                         // Default no change
        endcase
    end

    // ========================================================
    // Sequential State Update Logic
    // Handles resets, performance counters, hardware traps, and software CSR writes
    // ========================================================
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            // Reset all CSRs and state signals to their initial values
            mie_out    <= 1'b0;
            mpie_out   <= 1'b0;
            mie        <= 32'b0;
            mtvec_mode <= 2'b00;
            mtvec_base <= 30'b0;
            mepc       <= 32'b0;
            mcause     <= 32'b0;
            misa       <= MISA_RESET;
            mtval      <= 32'b0;
            mscratch   <= 32'b0;
            mip        <= 32'b0;
            mcycle     <= 64'b0;
            minstret   <= 64'b0;
            pmpaddr16  <= 32'b0;
            dcsr       <= 32'h4a030003; // Debug config: xdebugver=4, prv=Machine (3)
            dpc        <= 32'b0;
            dscratch0  <= 32'b0;
            dscratch1  <= 32'b0;
        end else begin
            
            // --------------------------------------------------------
            // 1. Performance Counters Update
            // --------------------------------------------------------
            mcycle <= mcycle + 64'd1; // Increment cycle counter every clock
            
            if (instret_inc_in)       // Increment instructions retired counter when signaled
                minstret <= minstret + 64'd1;

            // --------------------------------------------------------
            // 2. Hardware Trap State Updates
            // --------------------------------------------------------
            if (set_epc_in)
                mepc <= {pc_in[31:2], 2'b00}; // Save faulting instruction PC (word-aligned)

            if (set_cause_in) begin
                mcause <= {i_or_e_in, 27'b0, cause_in}; // Record interrupt/exception flag and cause code
                mtval  <= trap_value_in;                // Record faulting address or instruction
            end

            // Manage global interrupt enable during trap entry (clear) and MRET (restore)
            if (mie_clear_in == 1'b1) begin
                mpie_out <= mie_out; // Backup current MIE state to MPIE
                mie_out  <= 1'b0;    // Disable interrupts globally
            end else if (mie_set_in == 1'b1) begin
                mie_out  <= mpie_out; // Restore MIE from MPIE (during MRET)
                mpie_out <= 1'b1;     // Default MPIE to 1
            end

            // --------------------------------------------------------
            // 3. Hardware Debug State Updates
            // --------------------------------------------------------
            if (debug_update_dpc_in) begin
                dpc  <= {debug_pc_save_in[31:2], 2'b00};                // Save interrupted PC before jumping to debug ROM
                dcsr <= {dcsr[31:9], debug_cause_in, dcsr[5:2], 2'b11}; // Update halt cause in DCSR
            end

            // --------------------------------------------------------
            // 4. Software CSR Writes (Instruction execution)
            // --------------------------------------------------------
            // Only process software writes if a hardware trap is NOT updating state simultaneously
            if (!set_cause_in && csr_do_write) begin
                case (csr_addr_in)
                    MSTATUS: begin
                        mie_out  <= csr_wdata[3];
                        mpie_out <= csr_wdata[7];
                    end
                    MIE:       mie        <= csr_wdata & 32'h00000888; // Mask out unsupported interrupts (only MSIE, MTIE, MEIE)
                    MTVEC: begin
                        mtvec_mode <= csr_wdata[1:0];
                        mtvec_base <= csr_wdata[31:2];
                    end
                    MISA: begin
                        misa        <= csr_wdata & MISA_SUPPORTED_MASK;
                        misa[31:30] <= 2'b01;             // Force Base ISA (RV32)
                        misa[8]     <= 1'b1;              // Force I extension enabled
                        misa[12]    <= csr_wdata[12];     // Allow toggling M extension
                    end
                    MSCRATCH:  mscratch   <= csr_wdata;
                    MEPC:      mepc       <= {csr_wdata[31:2], 2'b00}; // Ensure PC is word-aligned
                    MCAUSE:    mcause     <= csr_wdata;
                    MTVAL:     mtval      <= csr_wdata;
                    MIP:       mip        <= csr_wdata;
                    
                    // Allow software writes to counters
                    MCYCLE:    mcycle[31:0]    <= csr_wdata;
                    MCYCLEH:   mcycle[63:32]   <= csr_wdata;
                    MINSTRET:  minstret[31:0]  <= csr_wdata;
                    MINSTRETH: minstret[63:32] <= csr_wdata;
                    
                    PMPADDR16: pmpaddr16       <= csr_wdata;
                    
                    // Debug CSR writes
                    DCSR:      dcsr       <= {csr_wdata[31:9], dcsr[8:6], csr_wdata[5:0]}; // Preserve specific read-only fields
                    DPC:       dpc        <= csr_wdata;
                    DSCRATCH0: dscratch0  <= csr_wdata;
                    DSCRATCH1: dscratch1  <= csr_wdata;
                    
                    default: ; // Ignore writes to invalid or unimplemented CSR addresses
                endcase
            end
        end
    end

endmodule
