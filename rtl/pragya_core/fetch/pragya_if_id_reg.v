`timescale 1ns / 1ps

// ============================================================================
// Module Name: pragya_if_id_reg
// Author     : chipXel team
// Description: Instruction Fetch to Instruction Decode (IF/ID) Pipeline Register.
//              Latches the fetched instruction, its PC, and PC+4 for the decode stage.
//              Handles pipeline stalls by holding the current values and pipeline
//              flushes by invalidating the output and injecting NOPs. It also
//              manages the timing of memory responses to ensure stale instructions
//              are dropped after a flush or stall condition.
// ============================================================================

module pragya_if_id_reg (
    input             clk_in,                 // System clock
    input             rst_in,                 // System reset (active high)

    // ========================================================
    // Inputs from Instruction Fetch (IF) Stage
    // ========================================================
    input      [31:0] pc_mux_in,              // Current Program Counter
    input      [31:0] pc_plus_4_pipline1_in,  // PC + 4 (sequential next address)
    input      [31:0] if_instr,               // Fetched instruction from memory
    input             if_valid,               // 1 = Fetched instruction is valid

    // ========================================================
    // Pipeline Control Inputs
    // ========================================================
    input             stall_d,                // 1 = Stall the IF/ID register
    input             flush,                  // 1 = Flush the IF/ID register (insert bubble)

    // ========================================================
    // Outputs to Instruction Decode (ID) Stage
    // ========================================================
    output reg [31:0] pc_out,                 // Registered Program Counter
    output reg [31:0] pc_plus_4_pipline1_out, // Registered PC + 4
    output     [31:0] id_instr,               // Instruction to decode (may be forced to NOP)
    output reg        id_valid                // 1 = Registered instruction is valid
);

    // ========================================================================
    // Instruction Dropping & Stall History Logic
    // ========================================================================
    // Due to memory latencies, a flush or stall might require the next
    // incoming instruction from memory to be dropped (replaced with NOP).
    reg drop_next_instr;
    reg was_stall;      

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            drop_next_instr <= 1'b0;
            was_stall       <= 1'b0;
        end else begin
            // If a flush occurs while not stalled, the next arriving instruction
            // from the memory interface belongs to the wrong execution path and
            // must be dropped.
            if (flush && !stall_d) begin
                drop_next_instr <= 1'b1;
            end else begin
                drop_next_instr <= 1'b0;
            end

            // Record if the pipeline was stalled in the previous cycle
            was_stall <= stall_d;
        end
    end

    // ========================================================================
    // Pipeline Register Update Logic
    // ========================================================================
    always @(posedge clk_in or posedge rst_in) begin
        // 1. Reset or Flush condition: Clear registers to insert a bubble
        if (rst_in | flush) begin
            pc_out                 <= 32'h00000000;
            pc_plus_4_pipline1_out <= 32'h00000000;
            id_valid               <= 1'b0;
        end
        // 2. Normal Operation: Update registers if IF/ID stage is not stalled
        else if (!stall_d) begin
            // 2A. Valid Instruction: Latch PC and PC+4
            if (if_valid) begin
                pc_out                 <= pc_mux_in;
                pc_plus_4_pipline1_out <= pc_plus_4_pipline1_in;
                id_valid               <= 1'b1;
            end
            // 2B. Invalid Instruction: Invalidate the decode stage
            else begin
                id_valid <= 1'b0;
            end
        end
        // If stall_d is high, registers hold their previous values implicitly
    end
   
    // ========================================================================
    // Instruction Mux (NOP Injection)
    // ========================================================================
    // If the instruction needs to be dropped (due to a previous flush) or 
    // if the pipeline was stalled (meaning the IF stage data might be stale),
    // force the output instruction to ADDI x0, x0, 0 (32'h00000013), which is a NOP.
    // Otherwise, pass the fetched instruction through.
    assign id_instr = (drop_next_instr | was_stall) ? 32'h00000013 : if_instr;

endmodule
