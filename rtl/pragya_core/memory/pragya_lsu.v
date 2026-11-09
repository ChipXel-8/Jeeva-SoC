`timescale 1ns / 1ps


module pragya_lsu (
    input wire          clk_in,
    input wire          rst_in,
    input wire          mem_req_in,
    input wire          mem_write_in,
    input wire [2:0]    funct3_in,
    input wire [31:0]   i_adder_in,
    input wire [31:0]   rs_2_in,

    input wire          dm_rvalid_in,
    input wire [31:0]   dm_rdata_in,

    output wire         pg_riscv32_mp_dmreq_out,
    output wire         pg_riscv32_mp_dmwen_out,
    output wire [3:0]   pg_riscv32_mp_dmbe_out,
    output wire [31:0]  pg_riscv32_mp_dmaddr_out,
    output wire [31:0]  pg_riscv32_mp_dmdata_out,

    output reg [31:0]   load_data_out // Changed back to reg to hold data for WB cycle
);

    // =========================================================================
    // 1. COMBINATIONAL MEMORY REQUEST (Cycle 1 - MEM Stage)
    // =========================================================================
    assign pg_riscv32_mp_dmreq_out  = mem_req_in;
    assign pg_riscv32_mp_dmwen_out  = mem_req_in && mem_write_in;
    assign pg_riscv32_mp_dmaddr_out = {i_adder_in[31:2], 2'b00};

    reg [31:0] store_data;
    reg [3:0]  be;

    always @(*) begin
        store_data = 32'b0;
        be         = 4'b0000;
        case (funct3_in)
            // SB 
            3'b000: begin
                case (i_adder_in[1:0])
                    2'b00: begin store_data = {24'b0, rs_2_in[7:0]};       be = 4'b0001; end
                    2'b01: begin store_data = {16'b0, rs_2_in[7:0], 8'b0}; be = 4'b0010; end
                    2'b10: begin store_data = {8'b0, rs_2_in[7:0], 16'b0}; be = 4'b0100; end
                    2'b11: begin store_data = {rs_2_in[7:0], 24'b0};       be = 4'b1000; end
                endcase
            end
            // SH 
            3'b001: begin
                if (i_adder_in[1]) begin
                    store_data = {rs_2_in[15:0], 16'b0}; be = 4'b1100;
                end else begin
                    store_data = {16'b0, rs_2_in[15:0]}; be = 4'b0011;
                end
            end
            // SW
            3'b010: begin
                store_data = rs_2_in; be = 4'b1111;
            end
            default: begin
                store_data = 32'b0; be = 4'b0000;
            end
        endcase

        if (!mem_write_in) be = 4'b0000;
    end

    assign pg_riscv32_mp_dmdata_out = (mem_write_in) ? store_data : 32'b0;
    assign pg_riscv32_mp_dmbe_out   = be;

    // =========================================================================
    // 2. COMBINATIONAL FORMATTING
    // =========================================================================
    // We remove the internal 'funct3_reg' and 'addr_offset_reg' because they 
    // caused an extra cycle of delay. We format combinationally using the inputs.
    
    wire [1:0]  addr_offset  = i_adder_in[1:0];
    wire [31:0] shifted_data = dm_rdata_in >> (8 * addr_offset);
    wire [7:0]  byte_data    = shifted_data[7:0];
    wire [15:0] half_data    = shifted_data[15:0];

    reg [31:0] formatted_load_data;
    
    always @(*) begin
        case (funct3_in)
            3'b000: formatted_load_data = {{24{byte_data[7]}}, byte_data};  // LB
            3'b001: formatted_load_data = {{16{half_data[15]}}, half_data}; // LH
            3'b010: formatted_load_data = dm_rdata_in;                      // LW
            3'b100: formatted_load_data = {24'b0, byte_data};               // LBU
            3'b101: formatted_load_data = {16'b0, half_data};               // LHU
            default: formatted_load_data = 32'b0;
        endcase
    end

    // =========================================================================
    // 3. PIPELINE REGISTER TO WRITEBACK STAGE
    // =========================================================================
    // Capture the correctly formatted data at the very end of the MEM cycle.
    // This holds the exact correct data steady while the core does the WB cycle.
    
    always @(posedge clk_in or posedge rst_in)
begin

if(rst_in)

load_data_out<=0;

else if(dm_rvalid_in)

load_data_out<=formatted_load_data;

end

endmodule
