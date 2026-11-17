`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_wb_mux
// Author     : chipXel team
// Description: Writeback Multiplexer for the pragya RISC-V processor.
//              Selects the appropriate data source to be written back into 
//              the Register File based on the instruction type. Sources include
//              the ALU, Data Memory (Load), PC+4 (for Jumps), Immediate (LUI),
//              Immediate Adder (AUIPC), MDU (Multiply/Divide), and CSRs.
// ============================================================================

module pragya_wb_mux (  
        // ========================================================
        // Data Inputs from Execution and Memory Units
        // ========================================================
        input   [31:0]      alu_result_in,      // Result from Arithmetic Logic Unit
        input   [31:0]      load_data_in,       // Formatted data read from Data Memory
        input   [31:0]      pc_plus4_in,        // Sequential PC (PC + 4) for JAL / JALR links
        input   [31:0]      imm_in,             // Sign-extended immediate for LUI
        input   [31:0]      i_adder_in,         // Result from Immediate Adder for AUIPC (PC + U-imm)
        input   [31:0]      mdu_result_in,      // Result from Multiply/Divide Unit
        input   [31:0]      csr_data_in,        // Data read from Control and Status Registers
        
        // ========================================================
        // Control Signal
        // ========================================================
        input   [2:0]       wb_mux_sel_in,      // Selection control signal from Decoder
        
        // ========================================================
        // Output to Register File
        // ========================================================
        output  [31:0]      wb_mux_out          // Selected data to write into the Register File
);

        // Internal register to hold the multiplexer output
        reg [31:0]      wb_out;

        // ========================================================================
        // Writeback Source Selection Logic
        // ========================================================================
        always @ (*) begin
                case (wb_mux_sel_in)
                    3'b000: wb_out = alu_result_in; // ALU operations (ADD, SUB, AND, OR, Shifts, etc.)
                    3'b001: wb_out = load_data_in;  // Memory Loads (LW, LH, LB, etc.)
                    3'b010: wb_out = pc_plus4_in;   // Jump instructions (JAL, JALR) saving return address
                    3'b011: wb_out = imm_in;        // Load Upper Immediate (LUI)
                    3'b100: wb_out = i_adder_in;    // Add Upper Immediate to PC (AUIPC)
                    3'b101: wb_out = mdu_result_in; // Multiply/Divide operations (MUL, DIV, REM, etc.)
                    3'b110: wb_out = csr_data_in;   // CSR Read operations (CSRRW, CSRRS, etc.)
                    default: wb_out = 32'b0;        // Default safe state (Zero)
                endcase
        end

        // Assign the internally resolved data to the output port
        assign wb_mux_out = wb_out;
        
endmodule
