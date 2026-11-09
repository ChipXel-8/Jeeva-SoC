/******************************************************************************
* Project : Pragya RISC-V Core
* File    : rv32m_coverage.sv
*
* Functional Coverage for RV32M Extension
******************************************************************************/

import pragya_pkg::*;

class rv32m_coverage;

    //------------------------------------------------------------
    // Sampled Signals
    //------------------------------------------------------------

    logic valid;

    logic [31:0] instr;
    logic [31:0] pc;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] rd_data;

    

    md_op_e md_op;

    m_instr_e current_instr;

    //------------------------------------------------------------
    // Operand Pattern
    //------------------------------------------------------------

    typedef enum logic [2:0]
    {
        DATA_ZERO,
        DATA_ONE,
        DATA_NEG_ONE,
        DATA_MAX_POS,
        DATA_MAX_NEG,
        DATA_POWER2,
        DATA_NORMAL
    } data_pattern_e;

    data_pattern_e rs1_pattern;
    data_pattern_e rs2_pattern;

    logic div_by_zero;
    logic div_overflow;

    //------------------------------------------------------------
    // Power of Two Detector
    //------------------------------------------------------------

    function automatic bit is_power2(input logic [31:0] value);

        if(value==0)
            return 0;

        return ((value & (value-1))==0);

    endfunction

    //------------------------------------------------------------
    // Operand Classification
    //------------------------------------------------------------

    function automatic data_pattern_e classify_data
    (
        input logic [31:0] data
    );

        if(data==32'h00000000)
            return DATA_ZERO;

        else if(data==32'h00000001)
            return DATA_ONE;

        else if(data==32'hFFFFFFFF)
            return DATA_NEG_ONE;

        else if(data==32'h7FFFFFFF)
            return DATA_MAX_POS;

        else if(data==32'h80000000)
            return DATA_MAX_NEG;

        else if(is_power2(data))
            return DATA_POWER2;

        else
            return DATA_NORMAL;

    endfunction

    //------------------------------------------------------------
    // Decode RV32M Instruction
    //------------------------------------------------------------

    function automatic m_instr_e decode_instruction
    (
        input logic [31:0] i
    );

        logic [6:0] opc;
        logic [2:0] f3;
        logic [6:0] f7;

        opc = i[6:0];
        f3  = i[14:12];
        f7  = i[31:25];

        if(opc==OPC_OP && f7==7'b0000001)
        begin

            case(f3)

                3'b000 : return M_MUL;
                3'b001 : return M_MULH;
                3'b010 : return M_MULHSU;
                3'b011 : return M_MULHU;
                3'b100 : return M_DIV;
                3'b101 : return M_DIVU;
                3'b110 : return M_REM;
                3'b111 : return M_REMU;

                default : return M_UNKNOWN;

            endcase

        end

        return M_UNKNOWN;

    endfunction
    //------------------------------------------------------------
    // Covergroup
    //------------------------------------------------------------

    covergroup cg_rv32m;

        option.per_instance = 1;
        option.name = "RV32M_COVERAGE";

        //--------------------------------------------------------
        // Instruction Coverage
        //--------------------------------------------------------

        cp_instr : coverpoint current_instr
        {
            bins mul    = {M_MUL};
            bins mulh   = {M_MULH};
            bins mulhsu = {M_MULHSU};
            bins mulhu  = {M_MULHU};

            bins div    = {M_DIV};
            bins divu   = {M_DIVU};

            bins rem    = {M_REM};
            bins remu   = {M_REMU};

            illegal_bins unknown = {M_UNKNOWN};
        }

        //--------------------------------------------------------
        // MDU Operation
        //--------------------------------------------------------

        cp_md_op : coverpoint md_op
        {
            bins mul    = {MD_OP_MUL};
            bins mulh   = {MD_OP_MULH};
            bins mulhsu = {MD_OP_MULHSU};
            bins mulhu  = {MD_OP_MULHU};

            bins div    = {MD_OP_DIV};
            bins divu   = {MD_OP_DIVU};

            bins rem    = {MD_OP_REM};
            bins remu   = {MD_OP_REMU};
        }

        //--------------------------------------------------------
        // Registers
        //--------------------------------------------------------

        cp_rd : coverpoint rd
        {
            
            bins regs[] = {[1:31]};
        }

        cp_rs1 : coverpoint rs1
        {
            bins x0 = {0};
            bins regs[] = {[1:31]};
        }

        cp_rs2 : coverpoint rs2
        {
            bins x0 = {0};
            bins regs[] = {[1:31]};
        }

        //--------------------------------------------------------
        // Operand Pattern
        //--------------------------------------------------------

        cp_rs1_pattern : coverpoint rs1_pattern
        {
            bins zero     = {DATA_ZERO};
            bins one      = {DATA_ONE};
            bins neg_one  = {DATA_NEG_ONE};
            bins max_pos  = {DATA_MAX_POS};
            bins max_neg  = {DATA_MAX_NEG};
            bins power2   = {DATA_POWER2};
            bins normal   = {DATA_NORMAL};
        }

        cp_rs2_pattern : coverpoint rs2_pattern
        {
            bins zero     = {DATA_ZERO};
            bins one      = {DATA_ONE};
            bins neg_one  = {DATA_NEG_ONE};
            bins max_pos  = {DATA_MAX_POS};
            bins max_neg  = {DATA_MAX_NEG};
            bins power2   = {DATA_POWER2};
            bins normal   = {DATA_NORMAL};
        }

        //--------------------------------------------------------
        // Divide by Zero
        //--------------------------------------------------------

        cp_div_zero : coverpoint div_by_zero
        {
            bins no  = {0};
            bins yes = {1};
        }

        //--------------------------------------------------------
        // Overflow
        //--------------------------------------------------------

        cp_overflow : coverpoint div_overflow
        {
            bins no  = {0};
            bins yes = {1};
        }

          //--------------------------------------------------------
        // Result Sign
        //--------------------------------------------------------

        cp_result_sign : coverpoint rd_data[31]
        {
            bins positive = {0};
            bins negative = {1};
        }

        //--------------------------------------------------------
        // Cross Coverage
        //--------------------------------------------------------

        cross_instr_rd      : cross cp_instr, cp_rd;
        cross_instr_rs1     : cross cp_instr, cp_rs1;
        cross_instr_rs2     : cross cp_instr, cp_rs2;
        cross_operand       : cross cp_rs1_pattern, cp_rs2_pattern;
cross_div_zero : cross cp_instr, cp_div_zero
{
    // Divide-by-zero is meaningful only for DIV/DIVU/REM/REMU.
    ignore_bins mul_div_zero =
        binsof(cp_instr) intersect
        {M_MUL, M_MULH, M_MULHSU, M_MULHU}
        &&
        binsof(cp_div_zero.yes);
}
cross_overflow : cross cp_instr, cp_overflow
{
    // Overflow is currently defined only for signed DIV.
    ignore_bins non_div_overflow =
        binsof(cp_instr) intersect
        {M_MUL, M_MULH, M_MULHSU, M_MULHU,
         M_DIVU, M_REM, M_REMU}
        &&
        binsof(cp_overflow.yes);
}
        cross_result        : cross cp_instr, cp_result_sign;

    endgroup

    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------

    function new();

        cg_rv32m = new();

    endfunction


    //------------------------------------------------------------
    // Sample Function
    //------------------------------------------------------------

    function void sample(

        input logic [31:0] sample_instr,
        input logic [31:0] sample_pc,
        input logic        sample_valid,

        input logic [4:0]  sample_rs1,
        input logic [4:0]  sample_rs2,
        input logic [4:0]  sample_rd,

        input logic [31:0] sample_rs1_data,
        input logic [31:0] sample_rs2_data,
        input logic [31:0] sample_rd_data,
      

        input md_op_e      sample_md_op

    );

        instr    = sample_instr;
        pc       = sample_pc;
        valid    = sample_valid;

        rs1      = sample_rs1;
        rs2      = sample_rs2;
        rd       = sample_rd;

        rs1_data = sample_rs1_data;
        rs2_data = sample_rs2_data;

        rd_data  = sample_rd_data;
        md_op    = sample_md_op;

        current_instr = decode_instruction(sample_instr);

rs1_pattern = classify_data(sample_rs1_data);
rs2_pattern = classify_data(sample_rs2_data);

//------------------------------------------------------------
// Divide by Zero
//------------------------------------------------------------

div_by_zero = 1'b0;

if ((current_instr == M_DIV)  ||
    (current_instr == M_DIVU) ||
    (current_instr == M_REM)  ||
    (current_instr == M_REMU))
begin
    div_by_zero = (sample_rs2_data == 32'h00000000);
end

//------------------------------------------------------------
// Division Overflow
//------------------------------------------------------------

div_overflow = 1'b0;

if (current_instr == M_DIV)
begin
    div_overflow =
        (sample_rs1_data == 32'h80000000) &&
        (sample_rs2_data == 32'hFFFFFFFF);
end

//------------------------------------------------------------
// Sample coverage
//------------------------------------------------------------

if (sample_valid)
    cg_rv32m.sample();

    endfunction


    //------------------------------------------------------------
    // Coverage Report
    //------------------------------------------------------------

    function void report();

        $display("");
        $display("===========================================");
        $display("         RV32M COVERAGE REPORT");
        $display("===========================================");
        $display("Coverage = %0.2f %%", cg_rv32m.get_coverage());
        $display("===========================================");
        $display("");

    endfunction

endclass
