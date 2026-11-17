`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_machine_control
// Author     : chipXel team
// Description: Core state machine and control unit for the pragya processor.
//              Manages core execution states including Boot, Normal Operation,
//              Trap Generation, Trap Return (MRET), Wait For Interrupt (WFI),
//              and Hardware Debug modes. Decodes system instructions and 
//              coordinates CSR updates and PC redirection during exceptions.
// ============================================================================

module pragya_machine_control ( 
    input         clk_in,
    input         rst_in,

    // ========================================================
    // Debug & Status Inputs
    // ========================================================
    input         debug_req_in,         // From Debug Module (Pulse/Request)
    input         debug_mode_status_in, // Absolute state from pc_unit (Debug Mode is active)
    input [31:0]  pc_in,                // Current Program Counter
    input         id_valid_in,          // Instruction decode valid flag
    input [31:0]  mem_addr_in,          // Target memory address (for misaligned traps)
    input         retire_valid_in,      // Valid instruction retirement flag
    input [31:0]  instr_in,             // Current instruction payload

    // ========================================================
    // Trap/Exception Inputs from Decode & Pipeline
    // ========================================================
    input         illegal_instr_in,     // Illegal instruction detected in Decode
    input         misaligned_instr_in,  // Misaligned instruction fetch detected

    // ========================================================
    // Instruction Fields (from Decoder)
    // ========================================================
    input [6:2]   opcode_6_to_2_in,
    input [2:0]   funct3_in,
    input [6:0]   funct7_in,
    input [4:0]   rs1_addr_in,
    input [4:0]   rs2_addr_in,
    input [4:0]   rd_addr_in,

    // ========================================================
    // Interrupt Controller (CLINT/PLIC) Inputs
    // ========================================================
    input         e_irq_in,             // External Interrupt request
    input         t_irq_in,             // Timer Interrupt request
    input         s_irq_in,             // Software Interrupt request
    input         mie_in,               // Machine Interrupt Enable global flag
    input         meie_in, mtie_in, msie_in, // Individual interrupt enable flags
    input         meip_in, mtip_in, msip_in, // Individual interrupt pending flags

    // ========================================================
    // Outputs to CSR File
    // ========================================================
    output reg        i_or_e_out,       // 1 = Interrupt, 0 = Exception
    output reg        set_epc_out,      // Flag to save current PC to MEPC
    output reg        set_cause_out,    // Flag to update MCAUSE
    output reg [3:0]  cause_out,        // Exception/Interrupt cause code
    output reg        instret_inc_out,  // Increment instructions retired counter
    output reg        mie_clear_out,    // Clear global interrupt enable
    output reg        mie_set_out,      // Restore global interrupt enable
    output [31:0]     trap_value_out,   // Trap value (e.g., faulting address)

    // ========================================================
    // Outputs to PC Mux & Pipeline
    // ========================================================
    output reg [1:0]  pc_src_out,        // PC source selection control
    output reg [31:0] trap_pc_out,       // PC at which the trap occurred
    output            trap_detected_out, // Trap condition met
    output            mret_detected_out, // MRET instruction detected
    output            wfi_stall_out      // Pipeline stall due to WFI
);
   
    // ========================================================================
    // State Machine Definitions (One-Hot Encoding)
    // ========================================================================
    reg [4:0] curr_state;
    reg [4:0] next_state;
    reg [31:0] trap_value_reg;
   
    parameter STATE_RESET       = 5'b00001;
    parameter STATE_OPERATING   = 5'b00010;
    parameter STATE_TRAP_TAKEN  = 5'b00100;  
    parameter STATE_TRAP_RETURN = 5'b01000;
    parameter STATE_WFI         = 5'b10000; // Sleep State
    parameter STATE_DEBUG       = 5'b10001; // Hardware Debug Mode
   
    // PC Source Mux Control Encodings
    parameter PC_BOOT = 2'b00,
              PC_EPC  = 2'b01,
              PC_TRAP = 2'b10,
              PC_NEXT = 2'b11;

    // ========================================================================
    // Internal Decoding Wires
    // ========================================================================
    wire exception;
    wire ip; // Global Interrupt Pending
    wire eip; // External Interrupt Pending
    wire tip; // Timer Interrupt Pending
    wire sip; // Software Interrupt Pending
    
    // Instruction decode flags
    wire is_system;
    wire rs1_addr_zero;
    wire rs2_addr_zero;
    wire rd_zero;
    wire rs2_addr_mret;
    wire rs2_addr_ebreak;
    wire FUNCT3_zero;
    wire FUNCT7_zero;
    wire FUNCT7_mret;
    wire FUNCT7_wfi;
    wire rs2_addr_wfi;
    
    // System instructions
    wire mret;
    wire ecall;
    wire ebreak;
    wire wfi;
    
    // Trap evaluation
    wire trap_condition;
   
    // ========================================================================
    // Combinational Decoding Logic
    // ========================================================================
    
    // Interrupt Pending calculations (combining external pins and CSR flags)
    assign eip = meie_in & (e_irq_in | meip_in);
    assign tip = mtie_in & (t_irq_in | mtip_in);
    assign sip = msie_in & (s_irq_in | msip_in);
    assign ip  = eip | tip | sip;
    
    assign exception = id_valid_in && (illegal_instr_in | misaligned_instr_in);

    // Trap evaluation: Hardware interrupts or software exceptions
    assign trap_condition = (mie_in & ip) | exception | (id_valid_in && ecall) | (id_valid_in && ebreak);
    
    // Suppress traps if core is currently entering or in debug mode
    assign trap_detected_out = trap_condition & ~(debug_req_in | debug_mode_status_in);
    
    // System instruction opcode matching
    assign is_system   =  opcode_6_to_2_in[6] & opcode_6_to_2_in[5] & opcode_6_to_2_in[4]
                          & ~opcode_6_to_2_in[3] & ~opcode_6_to_2_in[2];
                          
    // Field validation for specific system instructions
    assign FUNCT3_zero = ~(funct3_in[2] | funct3_in[1] | funct3_in[0]);
    assign FUNCT7_zero = ~(funct7_in[6] | funct7_in[5] | funct7_in[4] | funct7_in[3]
                          | funct7_in[2] | funct7_in[1] | funct7_in[0]);
                          
    assign FUNCT7_wfi  = ~funct7_in[6] & ~funct7_in[5] & ~funct7_in[4] & funct7_in[3] &
                          ~funct7_in[2] & ~funct7_in[1] & ~funct7_in[0];
                          
    assign FUNCT7_mret = ~funct7_in[6] & ~funct7_in[5] & funct7_in[4] &
                          funct7_in[3] & ~funct7_in[2] & ~funct7_in[1] & ~funct7_in[0];
                          
    assign rs1_addr_zero = ~(rs1_addr_in[4] | rs1_addr_in[3] | rs1_addr_in[2] | rs1_addr_in[1] | rs1_addr_in[0]);
    assign rs2_addr_zero = ~(rs2_addr_in[4] | rs2_addr_in[3] | rs2_addr_in[2] | rs2_addr_in[1] | rs2_addr_in[0]);
    assign rd_zero       = ~(rd_addr_in[4] | rd_addr_in[3] | rd_addr_in[2] | rd_addr_in[1] | rd_addr_in[0]);
    
    assign rs2_addr_wfi  = ~rs2_addr_in[4] & ~rs2_addr_in[3] & rs2_addr_in[2] &
                           ~rs2_addr_in[1] & rs2_addr_in[0];
                           
    assign rs2_addr_mret = ~rs2_addr_in[4] & ~rs2_addr_in[3] & ~rs2_addr_in[2] &
                            rs2_addr_in[1] & ~rs2_addr_in[0];
                            
    assign rs2_addr_ebreak = ~rs2_addr_in[4] & ~rs2_addr_in[3] & ~rs2_addr_in[2] &
                             ~rs2_addr_in[1] & rs2_addr_in[0];
                             
    assign mret_detected_out = mret;
   
    // Final instruction decodes
    assign mret   = id_valid_in && is_system && FUNCT7_mret && rs2_addr_mret && rs1_addr_zero && FUNCT3_zero && rd_zero;
    assign ecall  = is_system & FUNCT7_zero & rs2_addr_zero & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign ebreak = is_system & FUNCT7_zero & rs2_addr_ebreak & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign wfi    = id_valid_in && is_system && FUNCT7_wfi && rs2_addr_wfi && rs1_addr_zero && FUNCT3_zero && rd_zero;
   
    // WFI Stall Flag (used to freeze the pipeline)
    assign wfi_stall_out = (curr_state == STATE_WFI);

    // ========================================================================
    // State Machine Next-State Logic
    // ========================================================================
    always @(*) begin
        case(curr_state)
            STATE_RESET:
                next_state = STATE_OPERATING;

            STATE_OPERATING: begin
                if (debug_req_in || debug_mode_status_in)
                    next_state = STATE_DEBUG; // Enter debug mode immediately
                else if ((mie_in & ip) || (id_valid_in && (exception | ecall | ebreak)))
                    next_state = STATE_TRAP_TAKEN;
                else if (id_valid_in && mret)
                    next_state = STATE_TRAP_RETURN;
                else if (wfi)
                    next_state = STATE_WFI;
                else
                    next_state = STATE_OPERATING;
            end

            STATE_WFI: begin
                // Wake up from WFI on debug request or pending interrupt
                if (debug_req_in || debug_mode_status_in)
                    next_state = STATE_DEBUG;
                else if (ip)
                    // If interrupts are globally enabled, take the trap.
                    // If disabled, just wake up and resume execution.
                    next_state = (mie_in) ? STATE_TRAP_TAKEN : STATE_OPERATING;
                else
                    next_state = STATE_WFI;
            end
            
            STATE_DEBUG: begin
                // Stay in debug mode until debug mode status drops (via DRET / resume)
                if (!debug_mode_status_in && !debug_req_in)
                    next_state = STATE_OPERATING;
                else
                    next_state = STATE_DEBUG;
            end

            STATE_TRAP_TAKEN:
                next_state = STATE_OPERATING;

            STATE_TRAP_RETURN:
                next_state = STATE_OPERATING;

            default:
                next_state = STATE_OPERATING;
        endcase
    end
   
    // ========================================================================
    // State Machine Output Logic (Combinational)
    // ========================================================================
    always @(*) begin
        case(curr_state)
            STATE_RESET: begin
                pc_src_out      = PC_BOOT;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end

            STATE_OPERATING: begin
                pc_src_out      = PC_NEXT;
                instret_inc_out = retire_valid_in;
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end

            STATE_WFI: begin
                pc_src_out      = PC_NEXT;
                instret_inc_out = 1'b0; // Suspend instruction counting during sleep
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end
            
            STATE_DEBUG: begin
                pc_src_out      = PC_NEXT;
                instret_inc_out = 1'b0; // Suspend instruction counting during debug
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end
            
            STATE_TRAP_TAKEN: begin
                pc_src_out      = PC_TRAP;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b1; // Trigger MEPC save
                set_cause_out   = 1'b1; // Trigger MCAUSE save
                mie_clear_out   = 1'b1; // Disable global interrupts
                mie_set_out     = 1'b0;
            end

            STATE_TRAP_RETURN: begin
                pc_src_out      = PC_EPC;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b1; // Restore global interrupts from MPIE
            end

            default: begin
                pc_src_out      = PC_NEXT;
                instret_inc_out = 1'b1;
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end
        endcase
    end

    // ========================================================================
    // Sequential Logic Updates
    // ========================================================================

    // Update Current State
    always @(posedge clk_in or posedge rst_in) begin
        if(rst_in)
            curr_state <= STATE_RESET;
        else
            curr_state <= next_state;
    end   
    
    // Latch PC for Trap (MEPC saving)
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            trap_pc_out <= 32'b0;
        end
        else if ((curr_state == STATE_OPERATING ||
                  curr_state == STATE_WFI) &&
                 trap_condition &&
                 ~(debug_req_in | debug_mode_status_in)) begin
            trap_pc_out <= pc_in;
        end
    end

    // Latch Trap Value (MTVAL saving)
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            trap_value_reg <= 32'h00000000;
        end
        else if (curr_state == STATE_OPERATING && ~(debug_req_in | debug_mode_status_in)) begin
            if (id_valid_in && illegal_instr_in)
                trap_value_reg <= instr_in;        // Save faulting instruction
            else if (id_valid_in && misaligned_instr_in)
                trap_value_reg <= mem_addr_in;     // Save faulting address
            else if (id_valid_in && ebreak)
                trap_value_reg <= pc_in;           // Save EBREAK PC
            else if (id_valid_in && ecall)
                trap_value_reg <= 32'h00000000;    // Clear MTVAL for ECALL
            else
                trap_value_reg <= 32'h00000000;
        end
    end

    assign trap_value_out = trap_value_reg;
   
    // Evaluate and latch Exception/Interrupt Cause (MCAUSE)
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            cause_out  <= 4'b0;
            i_or_e_out <= 1'b0;
        end
        else if ((curr_state == STATE_OPERATING ||
                  curr_state == STATE_WFI) &&
                 ~(debug_req_in | debug_mode_status_in)) begin

            // Priority evaluation for pending traps
            if (mie_in & eip) begin
                cause_out  <= 4'b1011; // Machine External Interrupt
                i_or_e_out <= 1'b1;
            end
            else if (mie_in & sip) begin
                cause_out  <= 4'b0011; // Machine Software Interrupt
                i_or_e_out <= 1'b1;
            end
            else if (mie_in & tip) begin
                cause_out  <= 4'b0111; // Machine Timer Interrupt
                i_or_e_out <= 1'b1;
            end
            else if (id_valid_in && illegal_instr_in) begin
                cause_out  <= 4'b0010; // Illegal Instruction Exception
                i_or_e_out <= 1'b0;
            end
            else if (id_valid_in && misaligned_instr_in) begin
                cause_out  <= 4'b0000; // Instruction Address Misaligned
                i_or_e_out <= 1'b0;
            end
            else if (id_valid_in && ecall) begin
                cause_out  <= 4'b1011; // Environment Call from M-mode
                i_or_e_out <= 1'b0;
            end
            else if (id_valid_in && ebreak) begin
                cause_out  <= 4'b0011; // Breakpoint Exception
                i_or_e_out <= 1'b0;
            end
        end
    end

endmodule
