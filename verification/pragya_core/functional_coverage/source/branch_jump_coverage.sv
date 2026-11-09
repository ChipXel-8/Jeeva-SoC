/******************************************************************************
* Project : Pragya RISC-V Core
* File    : branch_jump_coverage.sv
******************************************************************************/

import pragya_pkg::*;

class branch_jump_coverage;

    logic [31:0] pc;
    logic [31:0] target_pc;
    logic        taken;
    instr_name_e instr;

    covergroup cg_branch_jump;

        option.per_instance = 1;

        cp_instr : coverpoint instr
        {
            bins beq  = {BEQ};
            bins bne  = {BNE};
            bins blt  = {BLT};
            bins bge  = {BGE};
            bins bltu = {BLTU};
            bins bgeu = {BGEU};
            bins jal  = {JAL};
            bins jalr = {JALR};
        }

        cp_taken : coverpoint taken
        {
            bins taken_bin     = {1};
            bins not_taken_bin = {0};
        }

        cp_direction : coverpoint (target_pc > pc)
        {
            bins forward  = {1};
            bins backward = {0};
        }

        cp_alignment : coverpoint target_pc[1:0]
        {
            bins aligned   = {2'b00};
            bins unaligned = {[2'b01:2'b11]};
        }

cross_instr_taken : cross cp_instr, cp_taken
{
    ignore_bins jal_not_taken =
        binsof(cp_instr) intersect {JAL}
        &&
        binsof(cp_taken) intersect {0};

    ignore_bins jalr_not_taken =
        binsof(cp_instr) intersect {JALR}
        &&
        binsof(cp_taken) intersect {0};
}
        cross cp_instr, cp_direction;

    endgroup


    function new();
        cg_branch_jump = new();
    endfunction


    function automatic instr_name_e decode(input logic [31:0] instruction);

        case(instruction[6:0])

            OPC_BRANCH:
                case(instruction[14:12])
                    F3_BEQ  : return BEQ;
                    F3_BNE  : return BNE;
                    F3_BLT  : return BLT;
                    F3_BGE  : return BGE;
                    F3_BLTU : return BLTU;
                    F3_BGEU : return BGEU;
                endcase

            OPC_JAL:
                return JAL;

            OPC_JALR:
                return JALR;

        endcase

        return UNKNOWN;

    endfunction


    function void sample(

        input logic [31:0] sample_instr,
        input logic [31:0] sample_pc,
        input logic [31:0] sample_target,
        input logic sample_taken

    );

        instr     = decode(sample_instr);
pc        = sample_pc;
target_pc = sample_target;

// JAL and JALR are unconditional jumps
if (instr == JAL || instr == JALR)
    taken = 1'b1;
else
    taken = sample_taken;

cg_branch_jump.sample();

    endfunction


    function void report();

        $display("--------------------------------");
        $display("Branch/Jump Coverage = %0.2f%%",
                 cg_branch_jump.get_coverage());
        $display("--------------------------------");

    endfunction

endclass
