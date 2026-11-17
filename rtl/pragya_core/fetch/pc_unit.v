`timescale 1ns / 1ps

// ============================================================================
// Module Name: pc_unit
// Author     : chipXel team
// Description: Program Counter (PC) Unit for a RISC-V processor.
//              Handles PC updates, branching, exceptions, interrupts, and
//              hardware debug mode transitions (enter/exit debug, save DPC).
// ============================================================================

module pc_unit #(
    parameter RESET_PC        = 32'h8000_0000, // Boot address upon reset
    parameter DEBUG_BASE_ADDR = 32'h0100_0000  // Base address for Debug ROM
)
    (input         clk,
    input         rst,
    input         stall,
    input         branch_taken_in,                // 0: PC+4, 1: Branch/Jump target
    input  [31:0] pc_target,         // Branch/Jump target address

//========================================================
    // Debug control
    //========================================================
    input         debug_req_i,       // External debug request
    input         is_dret_inst,      // Indicates DRET instruction execution
    input  [31:0] dpc_in,            // DPC value from CSR to restore on DRET

    //========================================================
    // Debug outputs to CSR / Debug module
    //========================================================
    output         debug_update_dpc_o,  // Signal to CSR to save PC to DPC
    output  [31:0] debug_pc_save_o,     // PC value to be saved
    output  [2:0]  debug_cause_o,       // Cause of debug entry (e.g., halt request)
    output         debug_mode_status_o, // Indicates core is in debug mode

//========================================================
// Machine-mode PC control
//========================================================
    input  [1:0]  pc_src_in,         // Source selector for next PC
    input  [31:0] epc_in,            // EPC value for MRET
    input  [31:0] trap_address_in,   // Trap vector address (mtvec)
    input         is_ebreak_inst,    // Indicates EBREAK instruction execution
    output reg [31:0] pc,                // Current Program Counter
    output     [31:0] pc_plus4,          // PC + 4 (next sequential instruction)
    output            misaligned_instr_out // Instruction fetch alignment exception
);

    //========================================================
    // PC source encoding
    // Same encoding as pragya_machine_control
    //========================================================
    localparam PC_BOOT = 2'b00; // Boot/Reset
    localparam PC_EPC  = 2'b01; // Return from Machine exception (MRET)
    localparam PC_TRAP = 2'b10; // Trap/Exception entry
    localparam PC_NEXT = 2'b11; // Sequential or Branch


    // Debug State Register
    reg debug_mode_q;

    // Internal next PC signals
    reg [31:0] pc_next;
    wire [31:0] normal_pc_next;

    // Calculate PC + 4
    assign pc_plus4 = pc + 32'd4;

    // Determine next sequential or branch/jump target
    assign normal_pc_next = branch_taken_in ? pc_target : pc_plus4;
    
    //========================================================
    // Machine-mode PC MUX
    //========================================================
    always @(*) begin
             if (debug_mode_q) begin 
                   pc_next = normal_pc_next; // while running in debug mode, ignore traps/mret continue sequntial
        end
         else begin
          case (pc_src_in)

            // Reset / boot
            PC_BOOT:
                pc_next = RESET_PC;

            // MRET
            PC_EPC:
                pc_next = epc_in;

            // Exception / interrupt
            PC_TRAP:
                pc_next = trap_address_in;

            // Normal instruction execution (including branches)
            PC_NEXT:
                pc_next = normal_pc_next;

            default:
                pc_next = normal_pc_next;

        endcase
    end
    end

// Detect misaligned instruction fetch on branch/jump
assign misaligned_instr_out = branch_taken_in && (pc_target[1:0] != 2'b00);

//========================================================
    // Debug DPC save value & Control Pulses
    // COMBINATIONAL
    //========================================================

    // Provide current PC to be saved into DPC CSR
    assign debug_pc_save_o = pc;

    // Request CSR to save current PC into DPC when entering debug mode
    assign debug_update_dpc_o =
            (debug_req_i && !debug_mode_q);

    // Debug cause (3 = halt request, 0 = none)
    assign debug_cause_o =
            (debug_req_i && !debug_mode_q) ? 3'd3 : 3'd0;
            
    // Pass the debug state out to the rest of the core
    assign debug_mode_status_o = debug_mode_q;
    
//========================================================
    // PC Register & Priority Resolution
    //========================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc           <= RESET_PC;
            debug_mode_q <= 1'b0;
        end
        else begin
            // 1. Enter Debug Mode (Halts normal pipeline and vectors to Debug ROM)
            if (debug_req_i && !debug_mode_q) begin
                pc           <= DEBUG_BASE_ADDR;
                debug_mode_q <= 1'b1;
            end

            // 2. Exit Debug Mode using DRET
            else if (is_dret_inst && debug_mode_q) begin
                pc           <= dpc_in;
                debug_mode_q <= 1'b0;
            end
            
            // 3. EBREAK inside Debug Mode -> Return to Park Loop base
            else if (is_ebreak_inst && debug_mode_q) begin
                pc <= DEBUG_BASE_ADDR; 
                // debug_mode_q remains 1
            end

            // 4. Trap/exception -> mtvec
            else if (pc_src_in == PC_TRAP && !debug_mode_q) begin
                pc <= trap_address_in;
            end

            // 5. MRET -> mepc
            else if (pc_src_in == PC_EPC && !debug_mode_q) begin
                pc <= epc_in;
            end

            // 6. Normal execution / branch (only if not stalled)
            else if (!stall) begin
                pc <= pc_next;
            end
        end
    end

endmodule
