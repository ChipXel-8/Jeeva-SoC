`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_mdu
// Author     : chipXel team
// Description: Multiplier and Divider Unit (MDU) for the pragya processor.
//              Implements RV32M extension instructions. Uses a multi-cycle
//              state machine to perform division (32 cycles) and pipelined
//              multiplication (4 cycles). It stalls the main pipeline while
//              computing and asserts a valid signal upon completion.
// ============================================================================

module pragya_mdu (
    input             clk_in,
    input             rst_in,
    input             mdu_valid_in,     // Active when current DE is MDU op
    input      [31:0] rs_1_in,
    input      [31:0] rs_2_in,
    input      [2:0]  mdu_op_in,
    input      [4:0]  rd_in,
    input      [31:0] pc_in,
    input      [31:0] instr_in,

    output reg [31:0] mdu_result_out,
    output reg [4:0]  mdu_rd_out,
    output reg [31:0] mdu_pc_out,
    output reg [31:0] mdu_instr_out,
    output            mdu_wb_valid_out, // Pulses 1 ONLY when operation completes
    output            mdu_stall_out     // Holds stall until operation completes
);

    // ========================================================================
    // Internal Signals & State Definitions
    // ========================================================================
    wire is_div_op = mdu_op_in[2]; // 3'b100..3'b111 are DIV/REM operations

    // State machine encoding
    localparam S_IDLE = 2'b00;
    localparam S_CALC = 2'b01; // Divider calculation state
    localparam S_MUL  = 2'b10; // Multiplier calculation state
    localparam S_DONE = 2'b11; // Completion state

    reg [1:0]  state;
    reg [5:0]  count; // Cycle counter (up to 32 for division)
    
    // Iterative Division registers (Restoring Division Algorithm)
    reg [31:0] reg_q; // Quotient
    reg [31:0] reg_r; // Remainder
    reg [31:0] reg_b; // Divisor

    // Latched metadata (Breaks the timing critical path and survives pipeline stalls)
    reg        sign_a_r;
    reg        sign_b_r;
    reg [31:0] op1_r;
    reg [31:0] op2_r;
    reg [2:0]  op_r;
    reg [4:0]  latched_rd;
    reg [31:0] latched_pc;
    reg [31:0] latched_instr;

    // Pipelined Multiplier Register
    reg [31:0] mul_res_r;

    // ========================================================================
    // Combinational Setup Logic
    // ========================================================================
    // Determine sign for division/remainder operations
    wire is_signed_div = (mdu_op_in == 3'b100 || mdu_op_in == 3'b110);
    wire sign_a = is_signed_div & rs_1_in[31];
    wire sign_b = is_signed_div & rs_2_in[31];

    // Absolute values for unsigned division algorithm
    wire [31:0] abs_a = sign_a ? (-rs_1_in) : rs_1_in;
    wire [31:0] abs_b = sign_b ? (-rs_2_in) : rs_2_in;

    // Division step logic
    wire [32:0] rem_shifted = {reg_r[31:0], reg_q[31]};
    wire [32:0] sub_res     = rem_shifted - {1'b0, reg_b};

    // Multiplier logic executes combinationally between latched registers
    wire signed [31:0] s_mul_a = op1_r;
    wire signed [31:0] s_mul_b = op2_r;

    // Hardware multipliers based on signed/unsigned combinations
    wire signed [63:0] mul_ss = s_mul_a * s_mul_b;
    wire signed [63:0] mul_su = s_mul_a * $signed({1'b0, op2_r});
    wire        [63:0] mul_uu = op1_r * op2_r;

    // ========================================================================
    // MDU State Machine
    // ========================================================================
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            state         <= S_IDLE;
            count         <= 6'd0;
            reg_q         <= 32'd0;
            reg_r         <= 32'd0;
            reg_b         <= 32'd0;
            sign_a_r      <= 1'b0;
            sign_b_r      <= 1'b0;
            op1_r         <= 32'd0;
            op2_r         <= 32'd0;
            op_r          <= 3'd0;
            latched_rd    <= 5'd0;
            latched_pc    <= 32'd0;
            latched_instr <= 32'd0;
            mul_res_r     <= 32'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (mdu_valid_in) begin
                        // Latch all inputs immediately to survive external pipeline stalls
                        op1_r         <= rs_1_in;
                        op2_r         <= rs_2_in;
                        op_r          <= mdu_op_in;
                        latched_rd    <= rd_in;
                        latched_pc    <= pc_in;
                        latched_instr <= instr_in;

                        if (is_div_op) begin
                            state    <= S_CALC;
                            count    <= 6'd32; // 32 cycles for 32-bit division
                            reg_q    <= abs_a;
                            reg_r    <= 32'd0;
                            reg_b    <= abs_b;
                            sign_a_r <= sign_a;
                            sign_b_r <= sign_b;
                        end else begin
                            state    <= S_MUL;
                            count    <= 6'd4; // 4-cycle artificial delay for multiplication
                        end
                    end
                end

                S_CALC: begin
                    // Iterative restoring division step
                    if (sub_res[32]) begin
                        reg_r <= rem_shifted[31:0];
                        reg_q <= {reg_q[30:0], 1'b0};
                    end else begin
                        reg_r <= sub_res[31:0];
                        reg_q <= {reg_q[30:0], 1'b1};
                    end

                    count <= count - 1'b1;
                    if (count == 6'd1) begin
                        state <= S_DONE;
                    end
                end

                S_MUL: begin
                    // Latch the multiplication result exactly on cycle 2
                    // This breaks the critical path for synthesis/timing closure
                    if (count == 6'd2) begin
                        case (op_r[1:0])
                            2'b00:   mul_res_r <= mul_ss[31:0];  // MUL
                            2'b01:   mul_res_r <= mul_ss[63:32]; // MULH
                            2'b10:   mul_res_r <= mul_su[63:32]; // MULHSU
                            2'b11:   mul_res_r <= mul_uu[63:32]; // MULHU
                            default: mul_res_r <= 32'h0;
                        endcase
                    end

                    count <= count - 1'b1;
                    if (count == 6'd1) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    state <= S_IDLE; // Provide result for 1 cycle, then return to idle
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ========================================================================
    // Division Result Resolution & Correction
    // ========================================================================
    wire [31:0] quot_raw  = reg_q;
    wire [31:0] rem_raw   = reg_r;
    
    // Apply sign correction to quotient and remainder
    wire [31:0] quot_corr = (sign_a_r ^ sign_b_r) ? (-quot_raw) : quot_raw;
    wire [31:0] rem_corr  = sign_a_r ? (-rem_raw) : rem_raw;

    reg [31:0] div_res;
    always @(*) begin
        case (op_r)
            // DIV: Handle divide by zero and signed overflow
            3'b100: div_res = (op2_r == 32'd0) ? 32'hFFFFFFFF : 
                              ((op1_r == 32'h80000000 && op2_r == 32'hFFFFFFFF) ? 32'h80000000 : quot_corr);
            // DIVU: Handle divide by zero
            3'b101: div_res = (op2_r == 32'd0) ? 32'hFFFFFFFF : quot_raw;
            // REM: Handle divide by zero and signed overflow
            3'b110: div_res = (op2_r == 32'd0) ? op1_r : 
                              ((op1_r == 32'h80000000 && op2_r == 32'hFFFFFFFF) ? 32'h00000000 : rem_corr);
            // REMU: Handle divide by zero
            3'b111: div_res = (op2_r == 32'd0) ? op1_r : rem_raw;
            default: div_res = 32'h0;
        endcase
    end

    // ========================================================================
    // Pipeline Control & Output Assignments
    // ========================================================================
    
    // Hold the main pipeline stall until calculation finishes.
    assign mdu_stall_out    = (state == S_CALC) || (state == S_MUL) || (state == S_IDLE && mdu_valid_in);
    
    // Pulse exactly once when leaving S_DONE to trigger the MW pipeline stage
    assign mdu_wb_valid_out = (state == S_DONE);

    // Multiplex final output based on current state and operation type
    always @(*) begin
        if (state == S_DONE) begin
            mdu_result_out = op_r[2] ? div_res : mul_res_r;
            mdu_rd_out     = latched_rd;
            mdu_pc_out     = latched_pc;
            mdu_instr_out  = latched_instr;
        end else begin
            mdu_result_out = 32'h0;
            mdu_rd_out     = 5'd0;
            mdu_pc_out     = 32'h0;
            mdu_instr_out  = 32'h0;
        end
    end

endmodule
