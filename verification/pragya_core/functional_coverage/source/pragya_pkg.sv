package pragya_pkg;

    //============================================================
    // RV32I OPCODES
    //============================================================

    localparam logic [6:0] OPC_LOAD    = 7'b0000011;
    localparam logic [6:0] OPC_STORE   = 7'b0100011;
    localparam logic [6:0] OPC_BRANCH  = 7'b1100011;
    localparam logic [6:0] OPC_JALR    = 7'b1100111;
    localparam logic [6:0] OPC_JAL     = 7'b1101111;
    localparam logic [6:0] OPC_LUI     = 7'b0110111;
    localparam logic [6:0] OPC_AUIPC   = 7'b0010111;
    localparam logic [6:0] OPC_OPIMM   = 7'b0010011;
    localparam logic [6:0] OPC_OP      = 7'b0110011;
    localparam logic [6:0] OPC_SYSTEM  = 7'b1110011;


    //============================================================
    // RV32I BRANCH FUNCT3
    //============================================================

    localparam logic [2:0] F3_BEQ  = 3'b000;
    localparam logic [2:0] F3_BNE  = 3'b001;
    localparam logic [2:0] F3_BLT  = 3'b100;
    localparam logic [2:0] F3_BGE  = 3'b101;
    localparam logic [2:0] F3_BLTU = 3'b110;
    localparam logic [2:0] F3_BGEU = 3'b111;


    //============================================================
    // RV32I LOAD FUNCT3
    //============================================================

    localparam logic [2:0] F3_LB   = 3'b000;
    localparam logic [2:0] F3_LH   = 3'b001;
    localparam logic [2:0] F3_LW   = 3'b010;
    localparam logic [2:0] F3_LBU  = 3'b100;
    localparam logic [2:0] F3_LHU  = 3'b101;


    //============================================================
    // RV32I STORE FUNCT3
    //============================================================

    localparam logic [2:0] F3_SB   = 3'b000;
    localparam logic [2:0] F3_SH   = 3'b001;
    localparam logic [2:0] F3_SW   = 3'b010;


    //============================================================
    // RV32I ALU IMMEDIATE / REGISTER FUNCT3
    //============================================================

    localparam logic [2:0] F3_ADD_SUB = 3'b000;
    localparam logic [2:0] F3_SLL     = 3'b001;
    localparam logic [2:0] F3_SLT     = 3'b010;
    localparam logic [2:0] F3_SLTU    = 3'b011;
    localparam logic [2:0] F3_XOR     = 3'b100;
    localparam logic [2:0] F3_SRL_SRA = 3'b101;
    localparam logic [2:0] F3_OR      = 3'b110;
    localparam logic [2:0] F3_AND     = 3'b111;


    //============================================================
    // RV32I FUNCT7
    //============================================================

    localparam logic [6:0] F7_BASE = 7'b0000000;
    localparam logic [6:0] F7_SUB  = 7'b0100000;

    // RV32M uses this funct7
    localparam logic [6:0] F7_M    = 7'b0000001;


    //============================================================
    // RV32I INSTRUCTION NAMES
    //============================================================

    typedef enum int {

        ADD,
        SUB,
        ADDI,

        AND_OP,
        OR_OP,
        XOR_OP,

        ANDI,
        ORI,
        XORI,

        SLL,
        SRL,
        SRA,

        SLLI,
        SRLI,
        SRAI,

        SLT,
        SLTU,
        SLTI,
        SLTIU,

        LB,
        LH,
        LW,
        LBU,
        LHU,

        SB,
        SH,
        SW,

        BEQ,
        BNE,
        BLT,
        BGE,
        BLTU,
        BGEU,

        JAL,
        JALR,

        LUI,
        AUIPC,

        ECALL,
        EBREAK,

        UNKNOWN

    } instr_name_e;


    //============================================================
    // RV32M OPERATION
    //============================================================

    typedef enum logic [2:0] {

        MD_OP_MUL    = 3'b000,
        MD_OP_MULH   = 3'b001,
        MD_OP_MULHSU = 3'b010,
        MD_OP_MULHU  = 3'b011,
        MD_OP_DIV    = 3'b100,
        MD_OP_DIVU   = 3'b101,
        MD_OP_REM    = 3'b110,
        MD_OP_REMU   = 3'b111

    } md_op_e;


    //============================================================
    // RV32M INSTRUCTION NAMES
    //============================================================

    typedef enum int {

        M_MUL,
        M_MULH,
        M_MULHSU,
        M_MULHU,
        M_DIV,
        M_DIVU,
        M_REM,
        M_REMU,
        M_UNKNOWN

    } m_instr_e;


    //============================================================
    // CSR OPERATION TYPE
    //
    // Matches pragya_csr.csr_op_in exactly
    //============================================================

    typedef enum logic [2:0] {

        CSR_OP_RW  = 3'b001,       // CSRRW
        CSR_OP_RS  = 3'b010,       // CSRRS
        CSR_OP_RC  = 3'b011,       // CSRRC

        CSR_OP_RWI = 3'b101,       // CSRRWI
        CSR_OP_RSI = 3'b110,       // CSRRSI
        CSR_OP_RCI = 3'b111        // CSRRCI

    } csr_op_e;


    //============================================================
    // CSR ADDRESSES
    //
    // Matches pragya_csr.v
    //============================================================

    // -----------------------------------------------------------
    // Performance / User Counter CSRs
    // -----------------------------------------------------------

    localparam logic [11:0] CSR_CYCLE     = 12'hC00;
    localparam logic [11:0] CSR_INSTRET   = 12'hC02;
    localparam logic [11:0] CSR_CYCLEH    = 12'hC80;
    localparam logic [11:0] CSR_INSTRETH  = 12'hC82;


    // -----------------------------------------------------------
    // Machine Trap Setup
    // -----------------------------------------------------------

    localparam logic [11:0] CSR_MSTATUS   = 12'h300;
    localparam logic [11:0] CSR_MISA      = 12'h301;
    localparam logic [11:0] CSR_MIE       = 12'h304;
    localparam logic [11:0] CSR_MTVEC     = 12'h305;


    // -----------------------------------------------------------
    // Machine Identification
    // -----------------------------------------------------------

    localparam logic [11:0] CSR_MVENDORID = 12'hF11;
    localparam logic [11:0] CSR_MARCHID   = 12'hF12;
    localparam logic [11:0] CSR_MIMPID    = 12'hF13;
    localparam logic [11:0] CSR_MHARTID   = 12'hF14;


    // -----------------------------------------------------------
    // Machine Trap Handling
    // -----------------------------------------------------------

    localparam logic [11:0] CSR_MSCRATCH  = 12'h340;
    localparam logic [11:0] CSR_MEPC      = 12'h341;
    localparam logic [11:0] CSR_MCAUSE    = 12'h342;
    localparam logic [11:0] CSR_MTVAL     = 12'h343;
    localparam logic [11:0] CSR_MIP       = 12'h344;


    // -----------------------------------------------------------
    // Machine Counters
    // -----------------------------------------------------------

    localparam logic [11:0] CSR_MCYCLE    = 12'hB00;
    localparam logic [11:0] CSR_MINSTRET  = 12'hB02;
    localparam logic [11:0] CSR_MCYCLEH   = 12'hB80;
    localparam logic [11:0] CSR_MINSTRETH = 12'hB82;


    //============================================================
    // CSR BIT DEFINITIONS
    //============================================================

    // -----------------------------------------------------------
    // MSTATUS
    // -----------------------------------------------------------

    localparam integer MSTATUS_MIE_BIT  = 3;
    localparam integer MSTATUS_MPIE_BIT = 7;

    localparam logic [1:0] MSTATUS_MPP_MACHINE = 2'b11;


    // -----------------------------------------------------------
    // MIE
    // -----------------------------------------------------------

    localparam integer MIE_MSIE_BIT = 3;
    localparam integer MIE_MTIE_BIT = 7;
    localparam integer MIE_MEIE_BIT = 11;


    // -----------------------------------------------------------
    // MIP
    // -----------------------------------------------------------

    localparam integer MIP_MSIP_BIT = 3;
    localparam integer MIP_MTIP_BIT = 7;
    localparam integer MIP_MEIP_BIT = 11;


    // -----------------------------------------------------------
    // MTVEC
    // -----------------------------------------------------------

    localparam logic [1:0] MTVEC_MODE_DIRECT   = 2'b00;
    localparam logic [1:0] MTVEC_MODE_VECTORED = 2'b01;


    //============================================================
    // MACHINE-MODE EXCEPTION CAUSES
    //
    // These are the causes actually generated by your
    // pragya_machine_control.
    //============================================================

    // Instruction address misaligned
    localparam logic [31:0] CAUSE_INSTR_MISALIGNED =
                            32'h00000000;

    // Illegal instruction
    localparam logic [31:0] CAUSE_ILLEGAL_INSTR =
                            32'h00000002;

    // Breakpoint
    localparam logic [31:0] CAUSE_BREAKPOINT =
                            32'h00000003;

    // Environment call from M-mode
    localparam logic [31:0] CAUSE_ECALL_MMODE =
                            32'h0000000B;


    //============================================================
    // MACHINE-MODE INTERRUPT CAUSES
    //
    // Your machine_control generates:
    //
    // External = 4'b1011
    // Software = 4'b0011
    // Timer    = 4'b0111
    //
    // mcause[31] = 1 for interrupts.
    //============================================================

    // Machine software interrupt
    localparam logic [31:0] CAUSE_IRQ_SOFTWARE =
                            32'h80000003;

    // Machine timer interrupt
    localparam logic [31:0] CAUSE_IRQ_TIMER =
                            32'h80000007;

    // Machine external interrupt
    localparam logic [31:0] CAUSE_IRQ_EXTERNAL =
                            32'h8000000B;


    //============================================================
    // SHORT 4-BIT CAUSE VALUES
    //
    // These directly match cause_out from
    // pragya_machine_control.
    //============================================================

    localparam logic [3:0] CAUSE4_INSTR_MISALIGNED = 4'b0000;
    localparam logic [3:0] CAUSE4_ILLEGAL_INSTR    = 4'b0010;
    localparam logic [3:0] CAUSE4_BREAKPOINT       = 4'b0011;

    localparam logic [3:0] CAUSE4_IRQ_SOFTWARE     = 4'b0011;
    localparam logic [3:0] CAUSE4_IRQ_TIMER        = 4'b0111;
    localparam logic [3:0] CAUSE4_IRQ_EXTERNAL     = 4'b1011;

    localparam logic [3:0] CAUSE4_ECALL_MMODE      = 4'b1011;


    //============================================================
    // MACHINE CONTROL STATES
    //
    // Matches pragya_machine_control.v
    //============================================================

    localparam logic [3:0] STATE_RESET =
                            4'b0001;

    localparam logic [3:0] STATE_OPERATING =
                            4'b0010;

    localparam logic [3:0] STATE_TRAP_TAKEN =
                            4'b0100;

    localparam logic [3:0] STATE_TRAP_RETURN =
                            4'b1000;


    //============================================================
    // PC SOURCE SELECT
    //
    // Matches pragya_machine_control.v
    //============================================================

    localparam logic [1:0] PC_BOOT =
                            2'b00;

    localparam logic [1:0] PC_EPC =
                            2'b01;

    localparam logic [1:0] PC_TRAP =
                            2'b10;

    localparam logic [1:0] PC_NEXT =
                            2'b11;


    //============================================================
    // SYSTEM INSTRUCTION ENCODINGS
    //============================================================

    // ECALL
    localparam logic [31:0] INSTR_ECALL =
                            32'h00000073;

    // EBREAK
    localparam logic [31:0] INSTR_EBREAK =
                            32'h00100073;

    // MRET
    localparam logic [31:0] INSTR_MRET =
                            32'h30200073;

    // WFI
    localparam logic [31:0] INSTR_WFI =
                            32'h10500073;


    //============================================================
    // SYSTEM INSTRUCTION FUNCT7
    //============================================================

    localparam logic [6:0] FUNCT7_SYSTEM_ZERO =
                            7'b0000000;

    localparam logic [6:0] FUNCT7_WFI =
                            7'b0001000;

    localparam logic [6:0] FUNCT7_MRET =
                            7'b0011000;


    //============================================================
    // SYSTEM INSTRUCTION RS2 VALUES
    //============================================================

    localparam logic [4:0] SYSTEM_RS2_ZERO =
                            5'b00000;

    localparam logic [4:0] SYSTEM_RS2_EBREAK =
                            5'b00001;

    localparam logic [4:0] SYSTEM_RS2_MRET =
                            5'b00010;

    localparam logic [4:0] SYSTEM_RS2_WFI =
                            5'b00101;


    //============================================================
    // SYSTEM INSTRUCTION RD / RS1
    //============================================================

    localparam logic [4:0] SYSTEM_RD_ZERO =
                            5'b00000;

    localparam logic [4:0] SYSTEM_RS1_ZERO =
                            5'b00000;


    //============================================================
    // INTERRUPT SOURCE IDENTIFIERS
    //============================================================

    localparam logic [1:0] IRQ_NONE =
                            2'b00;

    localparam logic [1:0] IRQ_SOFTWARE =
                            2'b01;

    localparam logic [1:0] IRQ_TIMER =
                            2'b10;

    localparam logic [1:0] IRQ_EXTERNAL =
                            2'b11;


    //============================================================
    // CSR ACCESS TYPE
    //============================================================

    localparam logic CSR_READ  = 1'b0;
    localparam logic CSR_WRITE = 1'b1;


    //============================================================
    // MCAUSE INTERRUPT BIT
    //============================================================

    localparam integer MCAUSE_INTERRUPT_BIT = 31;


    //============================================================
    // MCAUSE EXCEPTION / INTERRUPT TYPE
    //============================================================

    localparam logic MCAUSE_EXCEPTION = 1'b0;
    localparam logic MCAUSE_INTERRUPT = 1'b1;


    //============================================================
    // END PACKAGE
    //============================================================

endpackage
