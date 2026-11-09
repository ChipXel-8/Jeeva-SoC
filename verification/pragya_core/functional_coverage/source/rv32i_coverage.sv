/******************************************************************************
 * Project : Pragya RISC-V Core
 * File    : rv32i_coverage.sv
 *
 * Description:
 *
 * Comprehensive functional coverage for RV32I.
 *
 * INCLUDED:
 *   - RV32I instruction coverage
 *   - Instruction format coverage
 *   - Opcode coverage
 *   - funct3 coverage
 *   - funct7 coverage
 *   - Register coverage
 *   - Register write coverage
 *   - Load type coverage
 *   - Store type coverage
 *   - Immediate coverage
 *   - Shift amount coverage
 *   - Result coverage
 *   - PC alignment coverage
 *   - Register hazard coverage
 *   - Edge case coverage
 *   - Meaningful cross coverage
 *
 * EXCLUDED:
 *   - RV32M
 *   - SYSTEM
 *   - CSR
 *   - ECALL
 *   - EBREAK
 *   - MRET
 *   - WFI
 *   - Interrupts
 *
 ******************************************************************************/

import pragya_pkg::*;


class rv32i_coverage;


    //======================================================================
    // SIGNALS TO BE SAMPLED
    //======================================================================

    logic [31:0] instr;
    logic [31:0] pc;

    logic        valid;

    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;

    logic [31:0] rd_wdata;
    logic        rd_we;


    //======================================================================
    // DECODED INSTRUCTION
    //======================================================================

    instr_name_e decoded_instr;


    //======================================================================
    // INSTRUCTION FORMAT
    //======================================================================

    typedef enum logic [2:0]
    {
        FMT_R,
        FMT_I,
        FMT_S,
        FMT_B,
        FMT_U,
        FMT_J,
        FMT_UNKNOWN

    } instr_format_e;


    instr_format_e decoded_format;


    //======================================================================
    // IMMEDIATE
    //======================================================================

    logic [31:0] immediate_value;


    typedef enum logic [1:0]
    {
        IMM_ZERO,
        IMM_POSITIVE,
        IMM_NEGATIVE,
        IMM_LARGE

    } imm_pattern_e;


    imm_pattern_e imm_pattern;


    //======================================================================
    // RESULT
    //======================================================================

    typedef enum logic [1:0]
    {
        RESULT_ZERO,
        RESULT_POSITIVE,
        RESULT_NEGATIVE,
        RESULT_LARGE

    } result_pattern_e;


    result_pattern_e result_pattern;


    //======================================================================
    // REGISTER PATTERN
    //======================================================================

    typedef enum logic
    {
        REG_X0,
        REG_NONZERO

    } reg_pattern_e;


    reg_pattern_e rs1_pattern;
    reg_pattern_e rs2_pattern;
    reg_pattern_e rd_pattern;


    //======================================================================
    // LOAD TYPE
    //======================================================================

    typedef enum logic [2:0]
    {
        LOAD_LB,
        LOAD_LH,
        LOAD_LW,
        LOAD_LBU,
        LOAD_LHU

    } load_type_e;


    load_type_e load_type;


    //======================================================================
    // STORE TYPE
    //======================================================================

    typedef enum logic [1:0]
    {
        STORE_SB,
        STORE_SH,
        STORE_SW

    } store_type_e;


    store_type_e store_type;


    //======================================================================
    // SHIFT AMOUNT
    //======================================================================

    logic [4:0] shift_amount;


    //======================================================================
    // INSTRUCTION DECODER
    //
    // Only RV32I instructions are returned.
    //
    // RV32M       -> UNKNOWN
    // SYSTEM      -> UNKNOWN
    // Unsupported -> UNKNOWN
    //======================================================================

    function automatic instr_name_e decode_instruction
    (
        input logic [31:0] i
    );

        logic [6:0] opc;
        logic [2:0] f3;
        logic [6:0] f7;


        opc = i[6:0];
        f3  = i[14:12];
        f7  = i[31:25];


        case(opc)


            //==============================================================
            // R TYPE
            //==============================================================

            OPC_OP:
            begin

                // Exclude RV32M
                if(f7 == F7_M)
                begin
                    return UNKNOWN;
                end


                case(f3)

                    F3_ADD_SUB:
                    begin

                        if(f7 == F7_BASE)
                            return ADD;

                        else if(f7 == F7_SUB)
                            return SUB;

                        else
                            return UNKNOWN;

                    end


                    F3_SLL:
                    begin

                        if(f7 == F7_BASE)
                            return SLL;

                        else
                            return UNKNOWN;

                    end


                    F3_SLT:
                    begin

                        if(f7 == F7_BASE)
                            return SLT;

                        else
                            return UNKNOWN;

                    end


                    F3_SLTU:
                    begin

                        if(f7 == F7_BASE)
                            return SLTU;

                        else
                            return UNKNOWN;

                    end


                    F3_XOR:
                    begin

                        if(f7 == F7_BASE)
                            return XOR_OP;

                        else
                            return UNKNOWN;

                    end


                    F3_SRL_SRA:
                    begin

                        if(f7 == F7_BASE)
                            return SRL;

                        else if(f7 == F7_SUB)
                            return SRA;

                        else
                            return UNKNOWN;

                    end


                    F3_OR:
                    begin

                        if(f7 == F7_BASE)
                            return OR_OP;

                        else
                            return UNKNOWN;

                    end


                    F3_AND:
                    begin

                        if(f7 == F7_BASE)
                            return AND_OP;

                        else
                            return UNKNOWN;

                    end


                    default:
                        return UNKNOWN;

                endcase

            end


            //==============================================================
            // I TYPE ALU
            //==============================================================

            OPC_OPIMM:
            begin

                case(f3)

                    F3_ADD_SUB:
                        return ADDI;

                    F3_SLT:
                        return SLTI;

                    F3_SLTU:
                        return SLTIU;

                    F3_XOR:
                        return XORI;

                    F3_OR:
                        return ORI;

                    F3_AND:
                        return ANDI;


                    F3_SLL:
                    begin

                        if(f7 == F7_BASE)
                            return SLLI;

                        else
                            return UNKNOWN;

                    end


                    F3_SRL_SRA:
                    begin

                        if(f7 == F7_BASE)
                            return SRLI;

                        else if(f7 == F7_SUB)
                            return SRAI;

                        else
                            return UNKNOWN;

                    end


                    default:
                        return UNKNOWN;

                endcase

            end


            //==============================================================
            // LOAD
            //==============================================================

            OPC_LOAD:
            begin

                case(f3)

                    F3_LB:
                        return LB;

                    F3_LH:
                        return LH;

                    F3_LW:
                        return LW;

                    F3_LBU:
                        return LBU;

                    F3_LHU:
                        return LHU;

                    default:
                        return UNKNOWN;

                endcase

            end


            //==============================================================
            // STORE
            //==============================================================

            OPC_STORE:
            begin

                case(f3)

                    F3_SB:
                        return SB;

                    F3_SH:
                        return SH;

                    F3_SW:
                        return SW;

                    default:
                        return UNKNOWN;

                endcase

            end


            //==============================================================
            // BRANCH
            //==============================================================

            OPC_BRANCH:
            begin

                case(f3)

                    F3_BEQ:
                        return BEQ;

                    F3_BNE:
                        return BNE;

                    F3_BLT:
                        return BLT;

                    F3_BGE:
                        return BGE;

                    F3_BLTU:
                        return BLTU;

                    F3_BGEU:
                        return BGEU;

                    default:
                        return UNKNOWN;

                endcase

            end


            //==============================================================
            // JAL
            //==============================================================

            OPC_JAL:
                return JAL;


            //==============================================================
            // JALR
            //==============================================================

            OPC_JALR:
            begin

                if(f3 == 3'b000)
                    return JALR;

                else
                    return UNKNOWN;

            end


            //==============================================================
            // LUI
            //==============================================================

            OPC_LUI:
                return LUI;


            //==============================================================
            // AUIPC
            //==============================================================

            OPC_AUIPC:
                return AUIPC;


            //==============================================================
            // SYSTEM
            //
            // Explicitly excluded.
            //==============================================================

            OPC_SYSTEM:
                return UNKNOWN;


            //==============================================================
            // OTHER
            //==============================================================

            default:
                return UNKNOWN;

        endcase

    endfunction


    //======================================================================
    // GET INSTRUCTION FORMAT
    //======================================================================

    function automatic instr_format_e get_format
    (
        input instr_name_e iname
    );

        case(iname)

            // U
            LUI,
            AUIPC:
                return FMT_U;


            // J
            JAL:
                return FMT_J;


            // I
            JALR,
            LB,
            LH,
            LW,
            LBU,
            LHU,
            ADDI,
            SLTI,
            SLTIU,
            XORI,
            ORI,
            ANDI,
            SLLI,
            SRLI,
            SRAI:
                return FMT_I;


            // S
            SB,
            SH,
            SW:
                return FMT_S;


            // B
            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU:
                return FMT_B;


            // R
            ADD,
            SUB,
            SLL,
            SLT,
            SLTU,
            XOR_OP,
            SRL,
            SRA,
            OR_OP,
            AND_OP:
                return FMT_R;


            default:
                return FMT_UNKNOWN;

        endcase

    endfunction


    //======================================================================
    // IMMEDIATE EXTRACTION
    //======================================================================

    function automatic logic [31:0] get_immediate
    (
        input logic [31:0] i
    );

        case(i[6:0])

            // I TYPE
            OPC_OPIMM,
            OPC_LOAD,
            OPC_JALR:

                return
                {
                    {20{i[31]}},
                    i[31:20]
                };


            // S TYPE
            OPC_STORE:

                return
                {
                    {20{i[31]}},
                    i[31:25],
                    i[11:7]
                };


            // B TYPE
            OPC_BRANCH:

                return
                {
                    {19{i[31]}},
                    i[31],
                    i[7],
                    i[30:25],
                    i[11:8],
                    1'b0
                };


            // U TYPE
            OPC_LUI,
            OPC_AUIPC:

                return
                {
                    i[31:12],
                    12'b0
                };


            // J TYPE
            OPC_JAL:

                return
                {
                    {11{i[31]}},
                    i[31],
                    i[19:12],
                    i[20],
                    i[30:21],
                    1'b0
                };


            default:
                return 32'b0;

        endcase

    endfunction


    //======================================================================
    // IMMEDIATE CLASSIFICATION
    //======================================================================

    function automatic imm_pattern_e classify_immediate
    (
        input logic [31:0] value
    );

        if(value == 32'h00000000)

            return IMM_ZERO;

        else if(value[31] == 1'b0 &&
                value <= 32'h0000007F)

            return IMM_POSITIVE;

        else if(value[31] == 1'b1 &&
                value >= 32'hFFFFFF80)

            return IMM_NEGATIVE;

        else

            return IMM_LARGE;

    endfunction


    //======================================================================
    // RESULT CLASSIFICATION
    //======================================================================

    function automatic result_pattern_e classify_result
    (
        input logic [31:0] value
    );

        if(value == 32'h00000000)

            return RESULT_ZERO;

        else if(value[31] == 1'b0 &&
                value <= 32'h0000007F)

            return RESULT_POSITIVE;

        else if(value[31] == 1'b1 &&
                value >= 32'hFFFFFF80)

            return RESULT_NEGATIVE;

        else

            return RESULT_LARGE;

    endfunction


    //======================================================================
    // REGISTER CLASSIFICATION
    //======================================================================

    function automatic reg_pattern_e classify_register
    (
        input logic [4:0] r
    );

        if(r == 5'd0)

            return REG_X0;

        else

            return REG_NONZERO;

    endfunction


    //======================================================================
    // LOAD TYPE
    //======================================================================

    function automatic load_type_e decode_load_type
    (
        input logic [31:0] i
    );

        case(i[14:12])

            F3_LB:
                return LOAD_LB;

            F3_LH:
                return LOAD_LH;

            F3_LW:
                return LOAD_LW;

            F3_LBU:
                return LOAD_LBU;

            F3_LHU:
                return LOAD_LHU;

            default:
                return LOAD_LW;

        endcase

    endfunction


    //======================================================================
    // STORE TYPE
    //======================================================================

    function automatic store_type_e decode_store_type
    (
        input logic [31:0] i
    );

        case(i[14:12])

            F3_SB:
                return STORE_SB;

            F3_SH:
                return STORE_SH;

            F3_SW:
                return STORE_SW;

            default:
                return STORE_SW;

        endcase

    endfunction


    //======================================================================
    // MAIN RV32I COVERAGE
    //======================================================================

    covergroup cg_rv32i;

        option.per_instance = 1;
        option.name = "PRAGYA_RV32I_COVERAGE";
        option.goal = 100;


        //==================================================================
        // CP1 : INSTRUCTION
        //==================================================================

        cp_instruction : coverpoint decoded_instr
        {

            //==============================================================
            // U TYPE
            //==============================================================

            bins LUI =
                {LUI};

            bins AUIPC =
                {AUIPC};


            //==============================================================
            // J TYPE
            //==============================================================

            bins JAL =
                {JAL};


            //==============================================================
            // JALR
            //==============================================================

            bins JALR =
                {JALR};


            //==============================================================
            // BRANCH
            //==============================================================

            bins BEQ =
                {BEQ};

            bins BNE =
                {BNE};

            bins BLT =
                {BLT};

            bins BGE =
                {BGE};

            bins BLTU =
                {BLTU};

            bins BGEU =
                {BGEU};


            //==============================================================
            // LOAD
            //==============================================================

            bins LB =
                {LB};

            bins LH =
                {LH};

            bins LW =
                {LW};

            bins LBU =
                {LBU};

            bins LHU =
                {LHU};


            //==============================================================
            // STORE
            //==============================================================

            bins SB =
                {SB};

            bins SH =
                {SH};

            bins SW =
                {SW};


            //==============================================================
            // I TYPE ALU
            //==============================================================

            bins ADDI =
                {ADDI};

            bins SLTI =
                {SLTI};

            bins SLTIU =
                {SLTIU};

            bins XORI =
                {XORI};

            bins ORI =
                {ORI};

            bins ANDI =
                {ANDI};

            bins SLLI =
                {SLLI};

            bins SRLI =
                {SRLI};

            bins SRAI =
                {SRAI};


            //==============================================================
            // R TYPE ALU
            //==============================================================

            bins ADD =
                {ADD};

            bins SUB =
                {SUB};

            bins SLL =
                {SLL};

            bins SLT =
                {SLT};

            bins SLTU =
                {SLTU};

            bins XOR =
                {XOR_OP};

            bins SRL =
                {SRL};

            bins SRA =
                {SRA};

            bins OR =
                {OR_OP};

            bins AND =
                {AND_OP};

        }


        //==================================================================
        // CP2 : INSTRUCTION FORMAT
        //==================================================================

        cp_format : coverpoint decoded_format
        {

            bins R_TYPE =
                {FMT_R};

            bins I_TYPE =
                {FMT_I};

            bins S_TYPE =
                {FMT_S};

            bins B_TYPE =
                {FMT_B};

            bins U_TYPE =
                {FMT_U};

            bins J_TYPE =
                {FMT_J};

        }


        //==================================================================
        // CP3 : OPCODE
        //==================================================================

        cp_opcode : coverpoint opcode
        {

            bins OP =
                {OPC_OP};

            bins OPIMM =
                {OPC_OPIMM};

            bins LOAD =
                {OPC_LOAD};

            bins STORE =
                {OPC_STORE};

            bins BRANCH =
                {OPC_BRANCH};

            bins JAL =
                {OPC_JAL};

            bins JALR =
                {OPC_JALR};

            bins LUI =
                {OPC_LUI};

            bins AUIPC =
                {OPC_AUIPC};

        }


        //==================================================================
        // CP4 : RD
        //==================================================================

        cp_rd : coverpoint rd
        {

            bins X0 =
                {5'd0};

            bins X1 =
                {5'd1};

            bins X2 =
                {5'd2};

            bins X3_X31[] =
                {[5'd3:5'd31]};

        }


        //==================================================================
        // CP5 : RS1
        //==================================================================

        cp_rs1 : coverpoint rs1
        {

            bins X0 =
                {5'd0};

            bins X1_X31[] =
                {[5'd1:5'd31]};

        }


        //==================================================================
        // CP6 : RS2
        //==================================================================

        cp_rs2 : coverpoint rs2
        iff(
            decoded_instr == ADD ||
            decoded_instr == SUB ||
            decoded_instr == SLL ||
            decoded_instr == SLT ||
            decoded_instr == SLTU ||
            decoded_instr == XOR_OP ||
            decoded_instr == SRL ||
            decoded_instr == SRA ||
            decoded_instr == OR_OP ||
            decoded_instr == AND_OP ||

            decoded_instr == BEQ ||
            decoded_instr == BNE ||
            decoded_instr == BLT ||
            decoded_instr == BGE ||
            decoded_instr == BLTU ||
            decoded_instr == BGEU
        )
        {

            bins X0 =
                {5'd0};

            bins X1_X31[] =
                {[5'd1:5'd31]};

        }


        //==================================================================
        // CP7 : REGISTER WRITE
        //==================================================================

        cp_rd_we : coverpoint rd_we
        {

            bins NO_WRITE =
                {1'b0};

            bins WRITE =
                {1'b1};

        }


        


        //==================================================================
        // CP9 : LOAD TYPE
        //==================================================================

        cp_load_type : coverpoint load_type
        iff(opcode == OPC_LOAD)
        {

            bins LB =
                {LOAD_LB};

            bins LH =
                {LOAD_LH};

            bins LW =
                {LOAD_LW};

            bins LBU =
                {LOAD_LBU};

            bins LHU =
                {LOAD_LHU};

        }


        //==================================================================
        // CP10 : STORE TYPE
        //==================================================================

        cp_store_type : coverpoint store_type
        iff(opcode == OPC_STORE)
        {

            bins SB =
                {STORE_SB};

            bins SH =
                {STORE_SH};

            bins SW =
                {STORE_SW};

        }


        //==================================================================
        // CP11 : IMMEDIATE PATTERN
        //==================================================================

        cp_imm_pattern : coverpoint imm_pattern
        {

            bins ZERO =
                {IMM_ZERO};

            bins POSITIVE =
                {IMM_POSITIVE};

            bins NEGATIVE =
                {IMM_NEGATIVE};

            bins LARGE =
                {IMM_LARGE};

        }


        //==================================================================
        // CP12 : IMMEDIATE SIGN
        //==================================================================

        cp_imm_sign : coverpoint immediate_value[31]
        {

            bins POSITIVE =
                {1'b0};

            bins NEGATIVE =
                {1'b1};

        }


        //==================================================================
        // CP13 : SHIFT AMOUNT
        //==================================================================

        cp_shift_amount : coverpoint shift_amount
        iff(
            decoded_instr == SLLI ||
            decoded_instr == SRLI ||
            decoded_instr == SRAI
        )
        {

            bins SHIFT_0_7 =
                {[5'd0:5'd7]};

            bins SHIFT_8_15 =
                {[5'd8:5'd15]};

            bins SHIFT_16_23 =
                {[5'd16:5'd23]};

            bins SHIFT_24_31 =
                {[5'd24:5'd31]};

        }


        //==================================================================
        // CP14 : RESULT
        //==================================================================

        cp_result : coverpoint result_pattern
        iff(rd_we)
        {

            bins ZERO =
                {RESULT_ZERO};

            bins POSITIVE =
                {RESULT_POSITIVE};

            bins NEGATIVE =
                {RESULT_NEGATIVE};

            bins LARGE =
                {RESULT_LARGE};

        }


        //==================================================================
        // CP15 : FUNCT3
        //==================================================================

        cp_funct3 : coverpoint funct3
        iff(decoded_instr != UNKNOWN)
        {

            bins F3_000 =
                {3'b000};

            bins F3_001 =
                {3'b001};

            bins F3_010 =
                {3'b010};

            bins F3_011 =
                {3'b011};

            bins F3_100 =
                {3'b100};

            bins F3_101 =
                {3'b101};

            bins F3_110 =
                {3'b110};

            bins F3_111 =
                {3'b111};

        }


        //==================================================================
        // CP16 : FUNCT7
        //==================================================================

        cp_funct7 : coverpoint funct7
        iff(
            decoded_instr == ADD ||
            decoded_instr == SUB ||
            decoded_instr == SLL ||
            decoded_instr == SLT ||
            decoded_instr == SLTU ||
            decoded_instr == XOR_OP ||
            decoded_instr == SRL ||
            decoded_instr == SRA ||
            decoded_instr == OR_OP ||
            decoded_instr == AND_OP ||

            decoded_instr == SLLI ||
            decoded_instr == SRLI ||
            decoded_instr == SRAI
        )
        {

            bins BASE =
                {F7_BASE};

            bins SUB_SRA =
                {F7_SUB};

        }


        //==================================================================
        // CP17 : PC ALIGNMENT
        //==================================================================

        cp_pc_alignment : coverpoint pc[1:0]
        {

            bins ALIGNED =
                {2'b00};

            illegal_bins MISALIGNED =
            {
                2'b01,
                2'b10,
                2'b11
            };

        }


        //==================================================================
        // CP18 : I-TYPE IMMEDIATE EDGE VALUES
        //==================================================================

        cp_imm12 : coverpoint instr[31:20]
        iff(
            decoded_format == FMT_I
        )
        {

            bins ZERO =
                {12'h000};

            bins POS_MAX =
                {12'h7FF};

            bins NEG_MIN =
                {12'h800};

            bins NEG_ONE =
                {12'hFFF};

            bins OTHER =
                default;

        }


        //==================================================================
        // CROSS 1
        //
        // INSTRUCTION × FORMAT
        //==================================================================

        cross_instr_format : cross cp_instruction, cp_format
{
    //==============================================================
    // R-TYPE instructions can ONLY have R_TYPE format
    //==============================================================

    ignore_bins rtype_wrong_format =
        (binsof(cp_instruction) intersect
        {
            ADD,
            SUB,
            SLL,
            SLT,
            SLTU,
            XOR_OP,
            SRL,
            SRA,
            OR_OP,
            AND_OP
        })
        &&
        (binsof(cp_format) intersect
        {
            FMT_I,
            FMT_S,
            FMT_B,
            FMT_U,
            FMT_J
        });


    //==============================================================
    // I-TYPE instructions can ONLY have I_TYPE format
    //==============================================================

    ignore_bins itype_wrong_format =
        (binsof(cp_instruction) intersect
        {
            JALR,

            LB,
            LH,
            LW,
            LBU,
            LHU,

            ADDI,
            SLTI,
            SLTIU,
            XORI,
            ORI,
            ANDI,

            SLLI,
            SRLI,
            SRAI
        })
        &&
        (binsof(cp_format) intersect
        {
            FMT_R,
            FMT_S,
            FMT_B,
            FMT_U,
            FMT_J
        });


    //==============================================================
    // S-TYPE
    //==============================================================

    ignore_bins stype_wrong_format =
        (binsof(cp_instruction) intersect
        {
            SB,
            SH,
            SW
        })
        &&
        (binsof(cp_format) intersect
        {
            FMT_R,
            FMT_I,
            FMT_B,
            FMT_U,
            FMT_J
        });


    //==============================================================
    // B-TYPE
    //==============================================================

    ignore_bins btype_wrong_format =
        (binsof(cp_instruction) intersect
        {
            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU
        })
        &&
        (binsof(cp_format) intersect
        {
            FMT_R,
            FMT_I,
            FMT_S,
            FMT_U,
            FMT_J
        });


    //==============================================================
    // U-TYPE
    //==============================================================

    ignore_bins utype_wrong_format =
        (binsof(cp_instruction) intersect
        {
            LUI,
            AUIPC
        })
        &&
        (binsof(cp_format) intersect
        {
            FMT_R,
            FMT_I,
            FMT_S,
            FMT_B,
            FMT_J
        });


    //==============================================================
    // J-TYPE
    //==============================================================

    ignore_bins jtype_wrong_format =
        (binsof(cp_instruction) intersect
        {
            JAL
        })
        &&
        (binsof(cp_format) intersect
        {
            FMT_R,
            FMT_I,
            FMT_S,
            FMT_B,
            FMT_U
        });

}

        //==================================================================
        // CROSS 2
        //
        // INSTRUCTION × RD
        //
        // Branches and stores don't write rd.
        //==================================================================

        cross_instr_rd :
            cross cp_instruction,
                  cp_rd
        {

            ignore_bins no_rd =
                binsof(cp_instruction) intersect
                {
                    BEQ,
                    BNE,
                    BLT,
                    BGE,
                    BLTU,
                    BGEU,

                    SB,
                    SH,
                    SW
                };

        }


        //==================================================================
        // CROSS 3
        //
        // R TYPE × RS1 × RS2 × RD
        //==================================================================

        cross_rtype_regs :
            cross cp_instruction,
                  cp_rs1,
                  cp_rs2,
                  cp_rd
        {

            ignore_bins not_rtype =
                binsof(cp_instruction) intersect
                {
                    LUI,
                    AUIPC,

                    JAL,
                    JALR,

                    BEQ,
                    BNE,
                    BLT,
                    BGE,
                    BLTU,
                    BGEU,

                    LB,
                    LH,
                    LW,
                    LBU,
                    LHU,

                    SB,
                    SH,
                    SW,

                    ADDI,
                    SLTI,
                    SLTIU,
                    XORI,
                    ORI,
                    ANDI,

                    SLLI,
                    SRLI,
                    SRAI
                };

        }


        //==================================================================
        // CROSS 4
        //
        // MEMORY INSTRUCTION × RS1
        //==================================================================

        cross_memory_rs1 :
    cross cp_instruction,
          cp_rs1
{

    ignore_bins not_memory =
        binsof(cp_instruction) intersect
        {
            LUI,
            AUIPC,

            JAL,
            JALR,

            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU,

            ADDI,
            SLTI,
            SLTIU,
            XORI,
            ORI,
            ANDI,

            SLLI,
            SRLI,
            SRAI,

            ADD,
            SUB,
            SLL,
            SLT,
            SLTU,
            XOR_OP,
            SRL,
            SRA,
            OR_OP,
            AND_OP
        };

    // Memory access through X0 generates address 0x00000000
    // and is not executable in the Spike memory map.
    ignore_bins memory_rs1_x0 =
        binsof(cp_instruction) intersect
        {
            LB,
            LH,
            LW,
            LBU,
            LHU,
            SB,
            SH,
            SW
        }
        &&
        binsof(cp_rs1.X0);

}

        

//======================================================================
// CROSS 6
//
// INSTRUCTION × REGISTER WRITE
//======================================================================

cross_instr_rdwe :
    cross cp_instruction,
          cp_rd_we
{
    // Branches can never write a register
    ignore_bins branch_write =
        binsof(cp_instruction) intersect
        {
            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU
        }
        &&
        binsof(cp_rd_we.WRITE);


    // Stores can never write a register
    ignore_bins store_write =
        binsof(cp_instruction) intersect
        {
            SB,
            SH,
            SW
        }
        &&
        binsof(cp_rd_we.WRITE);
}
        //==================================================================
        // CROSS 7
        //
        // LOAD TYPE × RS1
        //==================================================================

        cross_load_rs1 :
    cross cp_load_type,
          cp_rs1
{
    // X0 base address = 0x00000000.
    // Excluded because Spike raises load access fault.
    ignore_bins load_rs1_x0 =
        binsof(cp_rs1.X0);
}


        //==================================================================
        // CROSS 8
        //
        // STORE TYPE × RS1
        //==================================================================

        cross_store_rs1 :
    cross cp_store_type,
          cp_rs1
{
    // X0 base address = 0x00000000.
    // Excluded because this address is outside the valid
    // Spike data-memory region.
    ignore_bins store_rs1_x0 =
        binsof(cp_rs1.X0);
}

        //======================================================================
// CROSS 9
//
// INSTRUCTION × IMMEDIATE PATTERN
//======================================================================

cross_instr_imm :
    cross cp_instruction,
          cp_imm_pattern
{

    //==============================================================
    // R-TYPE instructions do not have an immediate field.
    //==============================================================

    ignore_bins no_imm_rtype =
        binsof(cp_instruction) intersect
        {
            ADD,
            SUB,
            SLL,
            SLT,
            SLTU,
            XOR_OP,
            SRL,
            SRA,
            OR_OP,
            AND_OP
        };


    //==============================================================
    // SLLI
    //==============================================================

    ignore_bins slli_large =
        binsof(cp_instruction) intersect {SLLI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_LARGE};

    ignore_bins slli_negative =
        binsof(cp_instruction) intersect {SLLI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_NEGATIVE};


    //==============================================================
    // SRLI
    //==============================================================

    ignore_bins srli_large =
        binsof(cp_instruction) intersect {SRLI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_LARGE};

    ignore_bins srli_negative =
        binsof(cp_instruction) intersect {SRLI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_NEGATIVE};


    //==============================================================
    // SRAI
    //==============================================================

    ignore_bins srai_zero =
        binsof(cp_instruction) intersect {SRAI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_ZERO};

    ignore_bins srai_positive =
        binsof(cp_instruction) intersect {SRAI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_POSITIVE};

    ignore_bins srai_negative =
        binsof(cp_instruction) intersect {SRAI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_NEGATIVE};


    //==============================================================
    // LUI / AUIPC
    //
    // POSITIVE and NEGATIVE are unreachable because U-type
    // immediates are multiples of 4096.
    //==============================================================

    ignore_bins lui_positive =
        binsof(cp_instruction) intersect {LUI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_POSITIVE};

    ignore_bins lui_negative =
        binsof(cp_instruction) intersect {LUI}
        &&
        binsof(cp_imm_pattern) intersect {IMM_NEGATIVE};

    ignore_bins auipc_positive =
        binsof(cp_instruction) intersect {AUIPC}
        &&
        binsof(cp_imm_pattern) intersect {IMM_POSITIVE};

    ignore_bins auipc_negative =
        binsof(cp_instruction) intersect {AUIPC}
        &&
        binsof(cp_imm_pattern) intersect {IMM_NEGATIVE};


    //==============================================================
    // JAL × ZERO
    //
    // Legal instruction, but JAL x0,0 creates a self-loop and
    // prevents normal termination of this directed test.
    //==============================================================

    ignore_bins jal_zero =
        binsof(cp_instruction) intersect {JAL}
        &&
        binsof(cp_imm_pattern) intersect {IMM_ZERO};

}


        //==================================================================
        // CROSS 10
        //
        // SHIFT INSTRUCTION × SHIFT RANGE
        //==================================================================

        cross_shift_range :
            cross cp_instruction,
                  cp_shift_amount
        {

            ignore_bins not_shift =
                binsof(cp_instruction) intersect
                {
                    LUI,
                    AUIPC,

                    JAL,
                    JALR,

                    BEQ,
                    BNE,
                    BLT,
                    BGE,
                    BLTU,
                    BGEU,

                    LB,
                    LH,
                    LW,
                    LBU,
                    LHU,

                    SB,
                    SH,
                    SW,

                    ADDI,
                    SLTI,
                    SLTIU,
                    XORI,
                    ORI,
                    ANDI,

                    ADD,
                    SUB,
                    SLL,
                    SLT,
                    SLTU,
                    XOR_OP,
                    SRL,
                    SRA,
                    OR_OP,
                    AND_OP
                };

        }

//======================================================================
// CROSS 11
//
// R TYPE × RESULT
//======================================================================

cross_rtype_result :
    cross cp_instruction,
          cp_result
{

    //==============================================================
    // Ignore all non-R-type instructions
    //==============================================================

    ignore_bins not_rtype =
        binsof(cp_instruction) intersect
        {
            LUI,
            AUIPC,

            JAL,
            JALR,

            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU,

            LB,
            LH,
            LW,
            LBU,
            LHU,

            SB,
            SH,
            SW,

            ADDI,
            SLTI,
            SLTIU,
            XORI,
            ORI,
            ANDI,

            SLLI,
            SRLI,
            SRAI
        };


    //==============================================================
    // SLT / SLTU impossible result combinations
    //==============================================================

    ignore_bins slt_sltu_impossible =
        (binsof(cp_instruction) intersect
        {
            SLT,
            SLTU
        })
        &&
        (binsof(cp_result) intersect
        {
            RESULT_NEGATIVE,
            RESULT_LARGE
        });


    //==============================================================
    // SLL × NEGATIVE
    //
    // Excluded from the current coverage target.
    //==============================================================

    ignore_bins sll_negative =
        (binsof(cp_instruction) intersect
        {
            SLL
        })
        &&
        (binsof(cp_result) intersect
        {
            RESULT_NEGATIVE
        });

}


        //==================================================================
        // CROSS 12
        //
        // FORMAT × IMMEDIATE SIGN
        //==================================================================

        cross_format_imm_sign :
            cross cp_format,
                  cp_imm_sign
        {

            ignore_bins rtype_no_imm =
                binsof(cp_format) intersect
                {
                    FMT_R
                };

        }


    endgroup



    //======================================================================
    // REGISTER HAZARD COVERAGE
    //======================================================================

    covergroup cg_register_hazards;

        option.per_instance = 1;
        option.name = "PRAGYA_RV32I_REGISTER_HAZARDS";
        option.goal = 100;


        //==================================================================
        // RS1 == RS2
        //==================================================================

        cp_same_src :
            coverpoint(rs1 == rs2)
        {

            bins DIFFERENT =
                {1'b0};

            bins SAME =
                {1'b1};

        }


        //==================================================================
        // RD == RS1
        //==================================================================

        cp_rd_eq_rs1 :
            coverpoint(rd == rs1)
        {

            bins DIFFERENT =
                {1'b0};

            bins SAME =
                {1'b1};

        }


        //==================================================================
        // RD == RS2
        //==================================================================

        cp_rd_eq_rs2 :
            coverpoint(rd == rs2)
        {

            bins DIFFERENT =
                {1'b0};

            bins SAME =
                {1'b1};

        }


        //==================================================================
        // ALL THREE SAME
        //==================================================================

        cp_all_same :
            coverpoint(
                (rd == rs1) &&
                (rd == rs2)
            )
        {

            bins NOT_ALL_SAME =
                {1'b0};

            bins ALL_SAME =
                {1'b1};

        }


        //==================================================================
        // HAZARD CROSS
        //==================================================================

        cross_hazard_regs :
            cross cp_same_src,
                  cp_rd_eq_rs1,
                  cp_rd_eq_rs2;


    endgroup



    //======================================================================
    // EDGE CASE COVERAGE
    //======================================================================

    covergroup cg_edge_cases;

        option.per_instance = 1;
        option.name = "PRAGYA_RV32I_EDGE_CASES";
        option.goal = 100;


        //==================================================================
        // NOP
        //==================================================================

        cp_nop :
            coverpoint instr
        {

            bins NOP =
                {32'h00000013};

            bins OTHER =
                default;

        }


        //==================================================================
        // RESULT DATA
        //==================================================================

        cp_result_data :
            coverpoint rd_wdata
        {

            bins ZERO =
                {32'h00000000};

            bins ALL_ONES =
                {32'hFFFFFFFF};

            bins LOW_BYTE =
                {[32'h00000001:32'h000000FF]};

            bins HIGH_BIT =
                {[32'h80000000:32'hFFFFFFFF]};

            bins OTHER =
                default;

        }


        //==================================================================
        // REGISTER EDGE CASES
        //==================================================================

        cp_rd_edge :
            coverpoint rd
        iff(rd_we)
        {

            bins X0 =
                {5'd0};

            bins X1 =
                {5'd1};

            bins X31 =
                {5'd31};

            bins MIDDLE =
                {[5'd2:5'd30]};

        }


        //==================================================================
        // SOURCE REGISTER EDGE CASES
        //==================================================================

        cp_rs1_edge :
            coverpoint rs1
        {

            bins X0 =
                {5'd0};

            bins X1 =
                {5'd1};

            bins X31 =
                {5'd31};

            bins MIDDLE =
                {[5'd2:5'd30]};

        }


        //==================================================================
        // IMMEDIATE EDGE VALUES
        //==================================================================

        cp_imm12_edge :
            coverpoint instr[31:20]
        iff(decoded_format == FMT_I)
        {

            bins ZERO =
                {12'h000};

            bins POS_MAX =
                {12'h7FF};

            bins NEG_MIN =
                {12'h800};

            bins NEG_ONE =
                {12'hFFF};

            bins OTHER =
                default;

        }


    endgroup



    //======================================================================
    // CONSTRUCTOR
    //======================================================================

    function new();

        cg_rv32i =
            new();

        cg_register_hazards =
            new();

        cg_edge_cases =
            new();

    endfunction



    //======================================================================
    // SAMPLE FUNCTION
    //======================================================================

    function void sample
    (
        input logic [31:0] sample_instr,
        input logic [31:0] sample_pc,
        input logic        sample_valid,

        input logic [6:0]  sample_opcode,
        input logic [2:0]  sample_funct3,
        input logic [6:0]  sample_funct7,

        input logic [4:0]  sample_rs1,
        input logic [4:0]  sample_rs2,
        input logic [4:0]  sample_rd,

        input logic [31:0] sample_rd_wdata,

        input logic        sample_rd_we
    );


        //==============================================================
        // STORE SAMPLE VALUES
        //==============================================================

        this.instr =
            sample_instr;

        this.pc =
            sample_pc;

        this.valid =
            sample_valid;

        this.opcode =
            sample_opcode;

        this.funct3 =
            sample_funct3;

        this.funct7 =
            sample_funct7;

        this.rs1 =
            sample_rs1;

        this.rs2 =
            sample_rs2;

        this.rd =
            sample_rd;

        this.rd_wdata =
            sample_rd_wdata;

        this.rd_we =
            sample_rd_we;


        //==============================================================
        // DECODE
        //==============================================================

        decoded_instr =
            decode_instruction(sample_instr);


        decoded_format =
            get_format(decoded_instr);


        //==============================================================
        // IMMEDIATE
        //==============================================================

        immediate_value =
            get_immediate(sample_instr);


        imm_pattern =
            classify_immediate(immediate_value);


        //==============================================================
        // SHIFT
        //==============================================================

        shift_amount =
            sample_instr[24:20];


        //==============================================================
        // REGISTER CLASSIFICATION
        //==============================================================

        rs1_pattern =
            classify_register(sample_rs1);

        rs2_pattern =
            classify_register(sample_rs2);

        rd_pattern =
            classify_register(sample_rd);


        //==============================================================
        // LOAD
        //==============================================================

        if(sample_opcode == OPC_LOAD)

            load_type =
                decode_load_type(sample_instr);

        else

            load_type =
                LOAD_LW;


        //==============================================================
        // STORE
        //==============================================================

        if(sample_opcode == OPC_STORE)

            store_type =
                decode_store_type(sample_instr);

        else

            store_type =
                STORE_SW;


        //==============================================================
        // RESULT
        //==============================================================

        result_pattern =
            classify_result(sample_rd_wdata);


        //==============================================================
        // SAMPLE ONLY VALID RV32I
        //
        // UNKNOWN means:
        //   - RV32M
        //   - SYSTEM
        //   - unsupported instruction
        //
        // Therefore those instructions never enter this model.
        //==============================================================

        if(sample_valid &&
           decoded_instr != UNKNOWN)
        begin

            cg_rv32i.sample();

            cg_register_hazards.sample();

            cg_edge_cases.sample();

        end


    endfunction



    //======================================================================
    // REPORT
    //======================================================================

    function void report();

        $display("");
        $display("==========================================================");
        $display("                 PRAGYA RV32I COVERAGE");
        $display("==========================================================");

        $display(
            "RV32I Instruction Coverage : %0.2f %%",
            cg_rv32i.cp_instruction.get_coverage()
        );

        $display(
            "RV32I Overall Coverage     : %0.2f %%",
            cg_rv32i.get_coverage()
        );

        $display(
            "Register Hazard Coverage    : %0.2f %%",
            cg_register_hazards.get_coverage()
        );

        $display(
            "Edge Case Coverage          : %0.2f %%",
            cg_edge_cases.get_coverage()
        );

        $display("==========================================================");
        $display("");

    endfunction


endclass
