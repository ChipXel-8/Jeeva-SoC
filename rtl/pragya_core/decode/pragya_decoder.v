`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_decoder
// Author     : chipXel team
// Description: Instruction Decoder for the pragya processor.
//              Takes a 32-bit RISC-V instruction and decodes it into control 
//              signals for the ALU, MDU, Register File, LSU, CSR, and Branch 
//              units. Also performs legality checks to trap illegal instructions.
// ============================================================================

module pragya_decoder (

    input  [31:0]  instr_in,           // 32-bit instruction from memory
    output [4:0]   rs_1_addrs_out,     // Source Register 1 address to reg file
    output [4:0]   rs_2_addrs_out,     // Source Register 2 address to reg file
    output [4:0]   rd_addrs_out,       // Destination Register address to reg file
    output [24:0]  instr_out,          // Instruction payload [31:7] to immediate generator
    output [2:0]   funct3_out,         // funct3 to machine control, LSU, and branch unit
    output [6:0]   funct7_out,         // funct7 to machine control
    output [6:0]   opcode_out,         // Base opcode
    output [2:0]   mdu_op_out,         // Multiplier/Divider (MDU) operation type
    output [3:0]   alu_control_out,    // Arithmetic Logic Unit (ALU) control signal
    output         reg_write_out,      // Enable write to register file
    output [2:0]   imm_src_out,        // Immediate source selection to imm gen
    output         alu_src_out,        // ALU Operand 2 source select (0: RS2, 1: IMM)
    output         mem_write_out,      // Data memory write enable to LSU
    output         mem_req_out,        // Data memory request to LSU
    output [2:0]   wb_mux_sel_out,     // Writeback Mux selection signal
    output         i_adder_src_out,    // Immediate adder source select
    output         jalr_out,           // JALR instruction flag
    output [6:2]   opcode6_to_2_out,   // Opcode bits [6:2] for machine control
    output [11:0]  csr_addr_out,       // CSR address field to CSR unit
    output         csr_wr_en_out,      // CSR write enable
    output [2:0]   csr_op_out,         // CSR operation type
    output         illegal_instr_out,  // Illegal instruction trap flag
    output         is_dret_out,        // Debug Return instruction flag
    output         is_mret_out,        // Machine Return instruction flag
    output         is_ecall_out,       // Environment Call instruction flag
    output         is_ebreak_out       // Environment Break instruction flag
);
          
    // ========================================================================
    // Internal Instruction Type Flags
    // ========================================================================
    reg is_op;       // Register-Register ALU operation
    reg is_mul;      // MDU (Multiply/Divide) operation
    reg is_op_imm;   // Register-Immediate ALU operation
    reg is_load;     // Memory Load operation
    reg is_store;    // Memory Store operation
    reg is_branch;   // Conditional Branch operation
    reg is_jal;      // Unconditional Jump and Link
    reg is_jalr;     // Unconditional Jump and Link Register
    reg is_lui;      // Load Upper Immediate
    reg is_auipc;    // Add Upper Immediate to PC
    reg is_system;   // System instruction (CSR, EBREAK, ECALL, MRET, DRET)
    
    // Internal control registers
    reg [2:0] wb_mux_sel;
    reg [2:0] MDUOp;
    reg [3:0] ALUControl;
    
    // Legality flags
    wire is_csr;
    wire system_legal;
    wire csr_addr_valid;
    wire op_legal;
    wire op_imm_legal;
    wire load_legal;
    wire store_legal;
    wire branch_legal;
    wire jalr_legal;
    wire csr_op_legal;

    // ========================================================================
    // Field Extraction
    // ========================================================================
    assign rs_1_addrs_out   = instr_in[19:15];
    assign rs_2_addrs_out   = instr_in[24:20];
    assign rd_addrs_out     = instr_in[11:7];
    assign instr_out        = instr_in[31:7];
    assign csr_addr_out     = instr_in[31:20];
    assign funct3_out       = instr_in[14:12];
    assign funct7_out       = instr_in[31:25];
    assign opcode_out       = instr_in[6:0];
    assign opcode6_to_2_out = instr_in[6:2];
    
    // ========================================================================
    // Legality Checks: Verify combinations of opcode, funct3, and funct7
    // ========================================================================
    
    // Validate CSR addresses explicitly supported by the processor
    assign csr_addr_valid =
       (csr_addr_out == 12'hC00) || // CYCLE
       (csr_addr_out == 12'hC02) || // INSTRET
       (csr_addr_out == 12'hC80) || // CYCLEH
       (csr_addr_out == 12'hC82) || // INSTRETH
       (csr_addr_out == 12'h300) || // MSTATUS
       (csr_addr_out == 12'h301) || // MISA
       (csr_addr_out == 12'h304) || // MIE
       (csr_addr_out == 12'h305) || // MTVEC
       (csr_addr_out == 12'h340) || // MSCRATCH
       (csr_addr_out == 12'h341) || // MEPC
       (csr_addr_out == 12'h342) || // MCAUSE
       (csr_addr_out == 12'h343) || // MTVAL
       (csr_addr_out == 12'h344) || // MIP
       (csr_addr_out == 12'hB00) || // MCYCLE
       (csr_addr_out == 12'hB02) || // MINSTRET
       (csr_addr_out == 12'hB80) || // MCYCLEH
       (csr_addr_out == 12'hB82) || // MINSTRETH
       (csr_addr_out == 12'h3c0) || // PMPADDR16
       (csr_addr_out == 12'hF11) || // MVENDORID
       (csr_addr_out == 12'hF12) || // MARCHID
       (csr_addr_out == 12'hF13) || // MIMPID
       (csr_addr_out == 12'hF14) || // MHARTID
       (csr_addr_out == 12'h7B0) || // DCSR (Debug)
       (csr_addr_out == 12'h7B1) || // DPC (Debug)
       (csr_addr_out == 12'h7B2) || // DSCRATCH0 (Debug)
       (csr_addr_out == 12'h7B3);   // DSCRATCH1 (Debug)

    // Validate system instructions (ECALL, EBREAK, MRET, DRET)
    assign system_legal =
       (instr_in == 32'h00000073) ||  // ECALL
       (instr_in == 32'h00100073) ||  // EBREAK
       (instr_in == 32'h30200073) ||  // MRET
       (instr_in == 32'h7b200073);    // DRET

    // Validate Register-Immediate ALU operations (OP-IMM)
    assign op_imm_legal =
       (funct3_out == 3'b000) || // ADDI
       (funct3_out == 3'b010) || // SLTI
       (funct3_out == 3'b011) || // SLTIU
       (funct3_out == 3'b100) || // XORI
       (funct3_out == 3'b110) || // ORI
       (funct3_out == 3'b111) || // ANDI
       // SLLI requires funct7 to be 0000000
       ((funct3_out == 3'b001) && (funct7_out == 7'b0000000)) ||
       // SRLI/SRAI require specific funct7 values
       ((funct3_out == 3'b101) && ((funct7_out == 7'b0000000) || (funct7_out == 7'b0100000)));

    // Validate Register-Register ALU operations (OP)
    assign op_legal =
       ((funct3_out == 3'b000) && ((funct7_out == 7'b0000000) || (funct7_out == 7'b0100000))) || // ADD/SUB
       ((funct3_out == 3'b001) && (funct7_out == 7'b0000000)) || // SLL
       ((funct3_out == 3'b010) && (funct7_out == 7'b0000000)) || // SLT
       ((funct3_out == 3'b011) && (funct7_out == 7'b0000000)) || // SLTU
       ((funct3_out == 3'b100) && (funct7_out == 7'b0000000)) || // XOR
       ((funct3_out == 3'b101) && ((funct7_out == 7'b0000000) || (funct7_out == 7'b0100000))) || // SRL/SRA
       ((funct3_out == 3'b110) && (funct7_out == 7'b0000000)) || // OR
       ((funct3_out == 3'b111) && (funct7_out == 7'b0000000));   // AND

    // Validate Load operations
    assign load_legal =
       (funct3_out == 3'b000) || // LB
       (funct3_out == 3'b001) || // LH
       (funct3_out == 3'b010) || // LW
       (funct3_out == 3'b100) || // LBU
       (funct3_out == 3'b101);   // LHU

    // Validate Store operations
    assign store_legal =
       (funct3_out == 3'b000) || // SB
       (funct3_out == 3'b001) || // SH
       (funct3_out == 3'b010);   // SW

    // Validate Conditional Branch operations
    assign branch_legal =
       (funct3_out == 3'b000) || // BEQ
       (funct3_out == 3'b001) || // BNE
       (funct3_out == 3'b100) || // BLT
       (funct3_out == 3'b101) || // BGE
       (funct3_out == 3'b110) || // BLTU
       (funct3_out == 3'b111);   // BGEU

    // Validate JALR operation
    assign jalr_legal =
       (funct3_out == 3'b000);

    // Validate CSR operations
    assign csr_op_legal =
       (funct3_out == 3'b001) || // CSRRW
       (funct3_out == 3'b010) || // CSRRS
       (funct3_out == 3'b011) || // CSRRC
       (funct3_out == 3'b101) || // CSRRWI
       (funct3_out == 3'b110) || // CSRRSI
       (funct3_out == 3'b111);   // CSRRCI

    // ========================================================================
    // Primary Opcode Decoding
    // ========================================================================
    always @ (*) begin
        // Default assignments to prevent latches
        is_op       = 1'b0;
        is_mul      = 1'b0;
        is_op_imm   = 1'b0;  
        is_load     = 1'b0;
        is_store    = 1'b0;
        is_branch   = 1'b0;
        is_jal      = 1'b0;
        is_jalr     = 1'b0;
        is_lui      = 1'b0;
        is_auipc    = 1'b0;
        is_system   = 1'b0;  
                                            
        // Check if it's a valid standard 32-bit RISC-V instruction (ends in 2'b11)
        if (opcode_out[1:0] == 2'b11) begin
            case (opcode_out[6:2])
                5'b011_00: begin
                    // Distinguish between standard OP and M (Multiply/Divide) Extension
                    if (funct7_out == 7'b0000001)
                        is_mul = 1'b1;
                    else
                        is_op  = 1'b1;  
                end
                5'b001_00: is_op_imm = 1'b1; 
                5'b000_00: is_load   = 1'b1;
                5'b010_00: is_store  = 1'b1;
                5'b110_00: is_branch = 1'b1;
                5'b110_11: is_jal    = 1'b1;
                5'b110_01: is_jalr   = 1'b1;
                5'b011_01: is_lui    = 1'b1;
                5'b001_01: is_auipc  = 1'b1;
                5'b111_00: is_system = 1'b1;   
                default: ; // Retain defaults
            endcase
        end
    end

    // ========================================================================
    // Control Signal Generation
    // ========================================================================
    
    // Register Write Enable: Active for instructions that write to the Register File
    assign  reg_write_out    = is_op | is_op_imm | is_load | is_jal | is_jalr | is_lui | is_auipc | is_csr | is_mul;  

    // Immediate Source encoding
    // imm_src_out[0] active for I-type, J-type, B-type
    assign  imm_src_out [0]  = is_op_imm | is_load | is_jalr | is_branch | is_jal;
    // imm_src_out[1] active for S-type, B-type
    assign  imm_src_out [1]  = is_store | is_branch;
    // imm_src_out[2] active for U-type, J-type
    assign  imm_src_out [2]  = is_lui | is_auipc | is_jal;

    // Memory Access requests
    assign mem_req_out       = is_load | is_store;
    assign mem_write_out     = is_store;

    // ALU Operand 2 Mux Select: 0 = RS2, 1 = Immediate
    assign alu_src_out = (is_op | is_branch) ? 1'b0 : 1'b1; 

    // Writeback Mux Selection
    always @(*) begin
        if (is_load)
            wb_mux_sel = 3'b001; // Data Memory Load
        else if (is_jal | is_jalr)
            wb_mux_sel = 3'b010; // PC + 4
        else if (is_lui)
            wb_mux_sel = 3'b011; // Upper Immediate
        else if (is_auipc)
            wb_mux_sel = 3'b100; // AUIPC result
        else if (is_mul)
            wb_mux_sel = 3'b101; // MDU result
        else if (is_csr)
            wb_mux_sel = 3'b110; // CSR Read Data
        else
            wb_mux_sel = 3'b000; // ALU result
    end
    assign wb_mux_sel_out = wb_mux_sel;
        
    // Immediate Adder Source Select (0 = PC, 1 = RS1)
    assign i_adder_src_out = (is_load | is_store | is_jalr) ? 1'b1 : 1'b0;
    
    // Identify CSR operations based on opcode and valid operation type
    assign is_csr          = (opcode_out == 7'b1110011) && csr_op_legal;

    // Enable writes to the CSR module
    assign csr_wr_en_out =
        is_csr &&
        csr_addr_valid &&
        (
            (csr_op_out == 3'b001) || // CSRRW
            (csr_op_out == 3'b101) || // CSRRWI
            ((csr_op_out == 3'b010) && (rs_1_addrs_out != 5'd0)) || // CSRRS  (No write if rs1=x0)
            ((csr_op_out == 3'b011) && (rs_1_addrs_out != 5'd0)) || // CSRRC  (No write if rs1=x0)
            ((csr_op_out == 3'b110) && (rs_1_addrs_out != 5'd0)) || // CSRRSI (No write if imm=0)
            ((csr_op_out == 3'b111) && (rs_1_addrs_out != 5'd0))    // CSRRCI (No write if imm=0)
        );
        
    assign csr_op_out      = funct3_out;

    // ========================================================================
    // Illegal Instruction Trap Generation
    // Combines unrecognised opcodes and illegal field combinations
    // ========================================================================
    assign illegal_instr_out =
        // Trap if no recognized primary opcode matched
       ~(
          is_op      |
          is_op_imm  |
          is_load    |
          is_store   |
          is_branch  |
          is_jal     |
          is_jalr    |
          is_lui     |
          is_auipc   |
          is_system  |
          is_mul
        )
       | // Or trap if specific legality checks fail
       (is_op      && !op_legal)
       |
       (is_op_imm  && !op_imm_legal)
       |
       (is_load    && !load_legal)
       |
       (is_store   && !store_legal)
       |
       (is_branch  && !branch_legal)
       |
       (is_jalr    && !jalr_legal)
       |
       (is_csr     && !csr_addr_valid)
       |
       (is_system  && !is_csr && !system_legal);

    // ========================================================================
    // MDU (Multiply/Divide Unit) Control Mapping
    // ========================================================================
    always @(*) begin
        if (is_mul) begin
            case (funct3_out)
                3'b000: MDUOp = 3'b000; // MUL
                3'b001: MDUOp = 3'b001; // MULH
                3'b010: MDUOp = 3'b010; // MULHSU
                3'b011: MDUOp = 3'b011; // MULHU
                3'b100: MDUOp = 3'b100; // DIV
                3'b101: MDUOp = 3'b101; // DIVU
                3'b110: MDUOp = 3'b110; // REM
                3'b111: MDUOp = 3'b111; // REMU
                default: MDUOp = 3'b000;
            endcase
        end
        else begin
            MDUOp = 3'b000;
        end
    end
  
    // ========================================================================
    // ALU Control Generation
    // Decodes instructions into 4-bit ALU operation codes
    // ========================================================================
    always @(*)begin
        if (is_load | is_store | is_jalr | is_auipc)
                ALUControl = 4'b0000; // ADD (Used for address calculation)

        else if(is_branch)
                ALUControl = 4'b0001; // SUB (Used for comparison)

        else if (is_op | is_op_imm) begin
                case (funct3_out)
                    3'b000: begin
                        // Distinguish between ADD/ADDI and SUB
                        // SUB is only valid for OP type (not OP-IMM) and has funct7 bit 5 high
                        if (opcode_out[5] && funct7_out[5])
                            ALUControl = 4'b0001; // SUB
                        else
                            ALUControl = 4'b0000; // ADD / ADDI
                    end
                    3'b111: ALUControl = 4'b0010; // AND / ANDI
                    3'b110: ALUControl = 4'b0011; // OR / ORI
                    3'b100: ALUControl = 4'b0100; // XOR / XORI
                    3'b001: ALUControl = 4'b0101; // SLL / SLLI
                    3'b010: ALUControl = 4'b1000; // SLT / SLTI
                    3'b011: ALUControl = 4'b1001; // SLTU/ SLTIU
                    3'b101: 
                    begin
                        // Distinguish between Logical and Arithmetic Right Shift
                        if (funct7_out[5])
                            ALUControl = 4'b0111; // SRA / SRAI
                        else
                            ALUControl = 4'b0110; // SRL / SRLI
                    end
                    default: ALUControl = 4'b0000;
                endcase
        end
        else
            ALUControl = 4'b0000; // Default ALU state
    end
      
    // Output Assignments for sub-unit controls
    assign  mdu_op_out       = MDUOp;
    assign  alu_control_out  = ALUControl;
    assign  jalr_out         = is_jalr;

    // =========================================================================
    // SYSTEM Instruction Decoding (Environment Calls and Returns)
    // SYSTEM opcode = 7'b1110011. funct3 = 3'b000.
    // The top 12 bits (funct12/csr_addr_out) determine the exact operation.
    // =========================================================================
    
    // Privileged system instructions (excludes CSR instructions)
    wire is_system_priv = is_system & (funct3_out == 3'b000);

    assign is_ecall_out  = is_system_priv & (csr_addr_out == 12'h000);
    assign is_ebreak_out = is_system_priv & (csr_addr_out == 12'h001);
    assign is_mret_out   = is_system_priv & (csr_addr_out == 12'h302);
    
    // Debug Return (Exits the Debugger Sandbox and restores execution)
    assign is_dret_out   = is_system_priv & (csr_addr_out == 12'h7B2);

endmodule
