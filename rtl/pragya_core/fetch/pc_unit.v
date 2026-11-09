/*`timescale 1ns / 1ps

module pc_unit #(
    parameter RESET_PC = 32'h00000000)
    (input         clk,
    input         rst,
    input         stall,
    input         branch_taken_in,                // 0: PC+4, 1: Branch/Jump target
    input  [31:0] pc_target,         // Branch/Jump target address

// Machine-mode PC control
    input  [1:0]  pc_src_in,
    input  [31:0] epc_in,
    input  [31:0] trap_address_in,

    output reg [31:0] pc,                // Current PC
    output     [31:0] pc_plus4,          // PC + 4
    output            misaligned_instr_out
);

    //========================================================
    // PC source encoding
    // Same encoding as pragya_machine_control
    //========================================================
    localparam PC_BOOT = 2'b00;
    localparam PC_EPC  = 2'b01;
    localparam PC_TRAP = 2'b10;
    localparam PC_NEXT = 2'b11;

    // Internal next PC signal
    reg [31:0] pc_next;
    wire [31:0] normal_pc_next;

    // PC + 4
    assign pc_plus4 = pc + 32'd4;

    // Next PC selection
    //assign pc_next = (branch_taken_in) ? pc_target : pc_plus4;
    assign normal_pc_next = branch_taken_in ? pc_target : pc_plus4;

    //========================================================
    // Machine-mode PC MUX
    //========================================================
    always @(*) begin

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

            // Normal instruction execution
            PC_NEXT:
                pc_next = normal_pc_next;

            default:
                pc_next = normal_pc_next;

        endcase
    end


assign misaligned_instr_out = branch_taken_in && (pc_target[1:0] != 2'b00);

    // PC Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= RESET_PC;    // Boot address

        else if (pc_src_in == PC_TRAP)
        pc <= trap_address_in;       // Trap/exception → mtvec

        else if (pc_src_in == PC_EPC)
        pc <= epc_in;                // MRET → mepc

        else if (!stall)
            pc <= pc_next;
    end

endmodule*/




/*
`timescale 1ns / 1ps

module pc_unit #(
    parameter RESET_PC        = 32'h8000_0000,
    parameter DEBUG_BASE_ADDR = 32'h0000_1000
)
    (input         clk,
    input         rst,
    input         stall,
    input         branch_taken_in,                // 0: PC+4, 1: Branch/Jump target
    input  [31:0] pc_target,         // Branch/Jump target address

//========================================================
    // Debug control
    //========================================================
    input         debug_req_i,
    input         is_dret_inst,
    input  [31:0] dpc_in,

    //========================================================
    // Debug outputs to CSR / Debug module
    //========================================================
    output         debug_update_dpc_o,
    output  [31:0] debug_pc_save_o,
    output  [2:0]  debug_cause_o,

// Machine-mode PC control
    input  [1:0]  pc_src_in,
    input  [31:0] epc_in,
    input  [31:0] trap_address_in,

    output reg [31:0] pc,                // Current PC
    output     [31:0] pc_plus4,          // PC + 4
    output            misaligned_instr_out
);

    //========================================================
    // PC source encoding
    // Same encoding as pragya_machine_control
    //========================================================
    localparam PC_BOOT = 2'b00;
    localparam PC_EPC  = 2'b01;
    localparam PC_TRAP = 2'b10;
    localparam PC_NEXT = 2'b11;


    // Debug State

    reg debug_mode_q;

    // Internal next PC signal
    reg [31:0] pc_next;
    wire [31:0] normal_pc_next;

    // PC + 4
    assign pc_plus4 = pc + 32'd4;

    // Next PC selection
    //assign pc_next = (branch_taken_in) ? pc_target : pc_plus4;
    assign normal_pc_next = branch_taken_in ? pc_target : pc_plus4;

    //========================================================
    // Machine-mode PC MUX
    //========================================================
    always @(*) begin

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

            // Normal instruction execution
            PC_NEXT:
                pc_next = normal_pc_next;

            default:
                pc_next = normal_pc_next;

        endcase
    end


assign misaligned_instr_out = branch_taken_in && (pc_target[1:0] != 2'b00);

//========================================================
    // Debug DPC save value & Control Pulses
    // COMBINATIONAL
    //========================================================

    // Current application PC
    assign debug_pc_save_o = pc;

    // Request CSR to save current PC into DPC
    assign debug_update_dpc_o =
            (debug_req_i && !debug_mode_q);

    // Debug cause
    assign debug_cause_o =
            (debug_req_i && !debug_mode_q) ? 3'd3 : 3'd0;

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

            // 3. Trap/exception -> mtvec
            else if (pc_src_in == PC_TRAP) begin
                pc <= trap_address_in;
            end

            // 4. MRET -> mepc
            else if (pc_src_in == PC_EPC) begin
                pc <= epc_in;
            end

            // 5. Normal execution / branch
            else if (!stall) begin
                pc <= pc_next;
            end
        end
    end

endmodule*/



`timescale 1ns / 1ps

module pc_unit #(
    parameter RESET_PC        = 32'h8000_0000,
    parameter DEBUG_BASE_ADDR = 32'h0100_0000
)
    (input         clk,
    input         rst,
    input         stall,
    input         branch_taken_in,                // 0: PC+4, 1: Branch/Jump target
    input  [31:0] pc_target,         // Branch/Jump target address

//========================================================
    // Debug control
    //========================================================
    input         debug_req_i,
    input         is_dret_inst,
    input  [31:0] dpc_in,

    //========================================================
    // Debug outputs to CSR / Debug module
    //========================================================
    output         debug_update_dpc_o,
    output  [31:0] debug_pc_save_o,
    output  [2:0]  debug_cause_o,
    output         debug_mode_status_o,

// Machine-mode PC control
    input  [1:0]  pc_src_in,
    input  [31:0] epc_in,
    input  [31:0] trap_address_in,
    input         is_ebreak_inst,
    output reg [31:0] pc,                // Current PC
    output     [31:0] pc_plus4,          // PC + 4
    output            misaligned_instr_out
);

    //========================================================
    // PC source encoding
    // Same encoding as pragya_machine_control
    //========================================================
    localparam PC_BOOT = 2'b00;
    localparam PC_EPC  = 2'b01;
    localparam PC_TRAP = 2'b10;
    localparam PC_NEXT = 2'b11;


    // Debug State

    reg debug_mode_q;

    // Internal next PC signal
    reg [31:0] pc_next;
    wire [31:0] normal_pc_next;

    // PC + 4
    assign pc_plus4 = pc + 32'd4;

    // Next PC selection
    //assign pc_next = (branch_taken_in) ? pc_target : pc_plus4;
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

            // Normal instruction execution
            PC_NEXT:
                pc_next = normal_pc_next;

            default:
                pc_next = normal_pc_next;

        endcase
    end
    end

assign misaligned_instr_out = branch_taken_in && (pc_target[1:0] != 2'b00);

//========================================================
    // Debug DPC save value & Control Pulses
    // COMBINATIONAL
    //========================================================

    // Current application PC
    assign debug_pc_save_o = pc;

    // Request CSR to save current PC into DPC
    assign debug_update_dpc_o =
            (debug_req_i && !debug_mode_q);

    // Debug cause
    assign debug_cause_o =
            (debug_req_i && !debug_mode_q) ? 3'd3 : 3'd0;
    // NEW: Pass the debug state out to the rest of the core
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
            // NAYA CODE: EBREAK inside Debug Mode -> Return to Park Loop
            else if (is_ebreak_inst && debug_mode_q) begin
                pc <= DEBUG_BASE_ADDR; // PC wapas 0x0800 par chala jayega
                // debug_mode_q pehle se 1 hai, usko change karne ki zaroorat nahi
            end

            // 3. Trap/exception -> mtvec
            else if (pc_src_in == PC_TRAP && !debug_mode_q) begin
                pc <= trap_address_in;
            end

            // 4. MRET -> mepc
            else if (pc_src_in == PC_EPC && !debug_mode_q) begin
                pc <= epc_in;
            end

            // 5. Normal execution / branch
            else if (!stall) begin
                pc <= pc_next;
            end
        end
    end

endmodule
