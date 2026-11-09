/*`timescale 1ns / 1ps


module pragya_machine_control( 
   input  clk_in, rst_in,
   input [31:0] pc_in,
   input        id_valid_in,
   input [31:0] mem_addr_in,
   input        retire_valid_in,
   input [31:0] instr_in,
   // from decoder
   input  illegal_instr_in,
   // from pipeline stage 1
   input  misaligned_instr_in, // wire from core

   // from instruction
   input  [6:2] opcode_6_to_2_in,
   input  [2:0] funct3_in,
   input  [6:0] funct7_in,
   input  [4:0] rs1_addr_in,
   input  [4:0] rs2_addr_in,
   input  [4:0] rd_addr_in,
   // from interrupt controller
   input  e_irq_in,t_irq_in, s_irq_in, // from core 
   input mie_in, // from csr
   input meie_in,mtie_in, msie_in, meip_in,mtip_in,msip_in, //from core wire       
   // to CSR file
   output reg i_or_e_out, set_epc_out, set_cause_out,
   output reg [3:0] cause_out,
   output reg instret_inc_out, mie_clear_out, mie_set_out,
   output [31:0] trap_value_out,
   // to PC MUX
   output reg [1:0] pc_src_out,
   output reg [31:0] trap_pc_out,
   output trap_detected_out,
   output mret_detected_out             
   );
   
    // state registers
    reg [3:0] curr_state;
    reg [3:0] next_state;
    reg [31:0] trap_value_reg;
   
    // machine states
    parameter STATE_RESET         = 4'b0001;
    parameter STATE_OPERATING     = 4'b0010;
    parameter STATE_TRAP_TAKEN    = 4'b0100;    
    parameter STATE_TRAP_RETURN   = 4'b1000;
   
    parameter PC_BOOT =2'b00,
              PC_EPC=  2'b01,
              PC_TRAP= 2'b10,
              PC_NEXT= 2'b11;
    // internal control signals
    wire exception;
    wire ip;
    wire eip;
    wire tip;
    wire sip;
    wire is_system;
    wire rs1_addr_zero;
    wire rs2_addr_zero;
    wire rd_zero;
    wire rs2_addr_mret;
    wire rs2_addr_ebreak;
    wire FUNCT3_zero;
    wire FUNCT7_zero;
    wire FUNCT7_mret;
    
    wire mret;
    wire ecall;
    wire ebreak;
    wire FUNCT7_wfi;
    wire rs2_addr_wfi;
    
   
    // COMBINATIONAL LOGIC
    assign trap_detected_out = (mie_in & ip) | exception | (id_valid_in && ecall) | (id_valid_in && ebreak);
    assign is_system   =  opcode_6_to_2_in[6] & opcode_6_to_2_in[5] & opcode_6_to_2_in[4]
                          & ~opcode_6_to_2_in[3] & ~opcode_6_to_2_in[2];
    assign FUNCT3_zero =  ~(funct3_in[2] | funct3_in[1] | funct3_in[0]);
    assign FUNCT7_zero =  ~(funct7_in[6] | funct7_in[5] | funct7_in[4] | funct7_in[3]
                          | funct7_in[2] | funct7_in[1] | funct7_in[0]);
    assign FUNCT7_wfi  =  ~funct7_in[6] & ~funct7_in[5] & ~funct7_in[4] & funct7_in[3] &
                          ~funct7_in[2] & ~funct7_in[1] & ~funct7_in[0];
    assign FUNCT7_mret  = ~funct7_in[6] & ~funct7_in[5] & funct7_in[4] &
                          funct7_in[3] & ~funct7_in[2] & ~funct7_in[1] & ~funct7_in[0];
    assign rs1_addr_zero =~(rs1_addr_in[4] | rs1_addr_in[3] | rs1_addr_in[2] | rs1_addr_in[1] |
                          rs1_addr_in[0]);
    assign rs2_addr_zero =~(rs2_addr_in[4] | rs2_addr_in[3] | rs2_addr_in[2] | rs2_addr_in[1] |
                          rs2_addr_in[0]);
    assign rd_zero =      ~(rd_addr_in[4] | rd_addr_in[3] | rd_addr_in[2] | rd_addr_in[1] | rd_addr_in[0]);
    assign rs2_addr_wfi = ~rs2_addr_in[4] & ~rs2_addr_in[3] & rs2_addr_in[2] &
                          ~rs2_addr_in[1] & rs2_addr_in[0];
    assign rs2_addr_mret = ~rs2_addr_in[4] & ~rs2_addr_in[3] & ~rs2_addr_in[2] &
                           rs2_addr_in[1] & ~rs2_addr_in[0];
    assign rs2_addr_ebreak = ~rs2_addr_in[4] & ~rs2_addr_in[3] & ~rs2_addr_in[2] &
                             ~rs2_addr_in[1] & rs2_addr_in[0];
    assign mret_detected_out = mret;
    assign mret =  id_valid_in && is_system && FUNCT7_mret && rs2_addr_mret && rs1_addr_zero && FUNCT3_zero && rd_zero;
    assign ecall = is_system & FUNCT7_zero & rs2_addr_zero & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign ebreak = is_system & FUNCT7_zero & rs2_addr_ebreak & rs1_addr_zero & FUNCT3_zero & rd_zero;
   
    assign eip = meie_in & (e_irq_in | meip_in);
    assign tip = mtie_in & (t_irq_in | mtip_in);
    assign sip = msie_in & (s_irq_in | msip_in);
    assign ip = eip | tip | sip;
    assign exception = id_valid_in && (illegal_instr_in | misaligned_instr_in);
   
  
    

    // Next State Logic
    always @(*)
    begin
       case(curr_state)
          STATE_RESET:
             next_state = STATE_OPERATING;
          STATE_OPERATING:
begin
    if ((mie_in & ip) ||
        (id_valid_in && (exception | ecall | ebreak)))
        next_state = STATE_TRAP_TAKEN;

    else if (id_valid_in && mret)
        next_state = STATE_TRAP_RETURN;

    else
        next_state = STATE_OPERATING;
end
          STATE_TRAP_TAKEN:
             next_state = STATE_OPERATING;
          STATE_TRAP_RETURN:
             next_state = STATE_OPERATING;
          default:
             next_state = STATE_OPERATING;
        endcase
    end
   
    //Combinational  output logic
    always @(*)
    begin
       case(curr_state)
          STATE_RESET:
          begin
             pc_src_out = PC_BOOT;
            
             instret_inc_out = 1'b0;
             set_epc_out = 1'b0;
             set_cause_out = 1'b0;
             mie_clear_out = 1'b0;
             mie_set_out = 1'b0;
           end
           STATE_OPERATING:
              begin
              pc_src_out = PC_NEXT;
              
              instret_inc_out = retire_valid_in;
              set_epc_out = 1'b0;
              set_cause_out = 1'b0;
              mie_clear_out = 1'b0;
              mie_set_out = 1'b0;
           end
           STATE_TRAP_TAKEN:
           begin
              pc_src_out = PC_TRAP;
             
              instret_inc_out = 1'b0;
              set_epc_out = 1'b1;
              set_cause_out = 1'b1;
              mie_clear_out = 1'b1;
              mie_set_out = 1'b0;
           end
           STATE_TRAP_RETURN:
           begin
              pc_src_out = PC_EPC;
              
              instret_inc_out = 1'b0;
              set_epc_out = 1'b0;
              set_cause_out = 1'b0;
              mie_clear_out = 1'b0;
              mie_set_out = 1'b1;
           end
           default:
           begin
              pc_src_out = PC_NEXT;
           
              instret_inc_out = 1'b1;
              set_epc_out = 1'b0;
              set_cause_out = 1'b0;
              mie_clear_out = 1'b0;
              mie_set_out = 1'b0;
           end
        endcase
       
    end
    
    always @(posedge clk_in or posedge rst_in)
begin
    if (rst_in) begin
        trap_pc_out <= 32'b0;
    end

    else if (curr_state == STATE_OPERATING) begin
    if ((mie_in & ip) ||
        (id_valid_in && (exception | ecall | ebreak)))
        trap_pc_out <= pc_in;
end
end

always @(posedge clk_in or posedge rst_in)
begin
    if (rst_in) begin
        trap_value_reg <= 32'h00000000;
    end
    else if (curr_state == STATE_OPERATING) begin

        if (id_valid_in && illegal_instr_in)
            trap_value_reg <= instr_in;

        else if (id_valid_in && misaligned_instr_in)
            trap_value_reg <= mem_addr_in;

        else if (id_valid_in && ebreak)
            trap_value_reg <= pc_in;

        else if (id_valid_in && ecall)
            trap_value_reg <= 32'h00000000;

        else
            trap_value_reg <= 32'h00000000;

    end
end

assign trap_value_out = trap_value_reg;
   
    // Sequential Output Logic
   
    always @(posedge clk_in or posedge rst_in)
    begin
       if(rst_in)
          curr_state <= STATE_RESET;
       else
          curr_state <= next_state;
    end    
   

   
    always @(posedge clk_in or posedge rst_in)
    begin
       if(rst_in)
       begin
          cause_out <= 4'b0;
          i_or_e_out <= 1'b0;
       end
       else if(curr_state == STATE_OPERATING)
       begin
          if(mie_in & eip)
          begin
             cause_out <= 4'b1011; // M-mode external interrupt
             i_or_e_out <= 1'b1;
             end
       else if(mie_in & sip)
       begin
          cause_out <= 4'b0011; // M-mode software interrupt
          i_or_e_out <= 1'b1;
       end
       else if(mie_in & tip)
       begin
          cause_out <= 4'b0111; // M-mode timer interrupt
          i_or_e_out <= 1'b1;
       end
       else if(id_valid_in && illegal_instr_in)
       begin
          cause_out <= 4'b0010; // Illegal instruction
          i_or_e_out <= 1'b0;
       end
       else if(id_valid_in && misaligned_instr_in)
       begin
          cause_out <= 4'b0000; // Instruction address misaligned
          i_or_e_out <= 1'b0;
       end
       else if(id_valid_in && ecall)
       begin
          cause_out <= 4'b1011; // Environment call from M-mode
          i_or_e_out <= 1'b0;
       end
       else if(id_valid_in && ebreak)
       begin
          cause_out <= 4'b0011; // Breakpoint
          i_or_e_out <= 1'b0;
       end
       
       
     
end
end   

endmodule*/

/*
`timescale 1ns / 1ps

module pragya_machine_control( 
   input         clk_in, rst_in,
   input [31:0]  pc_in,
   input         id_valid_in,
   input [31:0]  mem_addr_in,
   input         retire_valid_in,
   input [31:0]  instr_in,
   // from decoder
   input         illegal_instr_in,
   // from pipeline stage 1
   input         misaligned_instr_in,

   // from instruction
   input  [6:2]  opcode_6_to_2_in,
   input  [2:0]  funct3_in,
   input  [6:0]  funct7_in,
   input  [4:0]  rs1_addr_in,
   input  [4:0]  rs2_addr_in,
   input  [4:0]  rd_addr_in,
   // from interrupt controller
   input         e_irq_in, t_irq_in, s_irq_in,
   input         mie_in,
   input         meie_in, mtie_in, msie_in, meip_in, mtip_in, msip_in,
   // to CSR file
   output reg    i_or_e_out, set_epc_out, set_cause_out,
   output reg [3:0] cause_out,
   output reg    instret_inc_out, mie_clear_out, mie_set_out,
   output [31:0] trap_value_out,
   // to PC MUX
   output reg [1:0]  pc_src_out,
   output reg [31:0] trap_pc_out,
   output        trap_detected_out,
   output        mret_detected_out,
   // to Hazard unit & IMEM
   output        wfi_stall_out              
);
   
    // 5-bit States
    reg [4:0] curr_state;
    reg [4:0] next_state;
    reg [31:0] trap_value_reg;
   
    parameter STATE_RESET        = 5'b00001;
    parameter STATE_OPERATING    = 5'b00010;
    parameter STATE_TRAP_TAKEN   = 5'b00100;    
    parameter STATE_TRAP_RETURN  = 5'b01000;
    parameter STATE_WFI          = 5'b10000; // Nayi Sleep State
   
    parameter PC_BOOT = 2'b00,
              PC_EPC  = 2'b01,
              PC_TRAP = 2'b10,
              PC_NEXT = 2'b11;

    wire exception;
    wire ip;
    wire eip;
    wire tip;
    wire sip;
    wire is_system;
    wire rs1_addr_zero;
    wire rs2_addr_zero;
    wire rd_zero;
    wire rs2_addr_mret;
    wire rs2_addr_ebreak;
    wire FUNCT3_zero;
    wire FUNCT7_zero;
    wire FUNCT7_mret;
    
    wire mret;
    wire ecall;
    wire ebreak;
    wire wfi;
    wire FUNCT7_wfi;
    wire rs2_addr_wfi;
    
    // COMBINATIONAL LOGIC
    assign trap_detected_out = (mie_in & ip) | exception | (id_valid_in && ecall) | (id_valid_in && ebreak);
    assign is_system   =  opcode_6_to_2_in[6] & opcode_6_to_2_in[5] & opcode_6_to_2_in[4]
                          & ~opcode_6_to_2_in[3] & ~opcode_6_to_2_in[2];
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
    
    // Decoded Instructions
    assign mret   = id_valid_in && is_system && FUNCT7_mret && rs2_addr_mret && rs1_addr_zero && FUNCT3_zero && rd_zero;
    assign ecall  = is_system & FUNCT7_zero & rs2_addr_zero & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign ebreak = is_system & FUNCT7_zero & rs2_addr_ebreak & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign wfi    = id_valid_in && is_system && FUNCT7_wfi && rs2_addr_wfi && rs1_addr_zero && FUNCT3_zero && rd_zero;
   
    // Interrupts logic (PLIC / CLINT)
    assign eip = meie_in & (e_irq_in | meip_in);
    assign tip = mtie_in & (t_irq_in | mtip_in);
    assign sip = msie_in & (s_irq_in | msip_in);
    assign ip  = eip | tip | sip;
    assign exception = id_valid_in && (illegal_instr_in | misaligned_instr_in);

    // WFI Stall Flag
    assign wfi_stall_out = (curr_state == STATE_WFI);

    // Next State Logic
    always @(*) begin
        case(curr_state)
            STATE_RESET:
                next_state = STATE_OPERATING;

            STATE_OPERATING: begin
                if ((mie_in & ip) || (id_valid_in && (exception | ecall | ebreak)))
                    next_state = STATE_TRAP_TAKEN;
                else if (id_valid_in && mret)
                    next_state = STATE_TRAP_RETURN;
                else if (wfi)
                    next_state = STATE_WFI; // WFI decode hone par STATE_WFI
                else
                    next_state = STATE_OPERATING;
            end

            STATE_WFI: begin
                if (ip) // CLINT ya PLIC se interrupt aate hi core jag jayega
                    next_state = STATE_OPERATING;
                else
                    next_state = STATE_WFI; // Tab tak sleep me rahega
            end

            STATE_TRAP_TAKEN:
                next_state = STATE_OPERATING;

            STATE_TRAP_RETURN:
                next_state = STATE_OPERATING;

            default:
                next_state = STATE_OPERATING;
        endcase
    end
   
    // Combinational output logic
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
                instret_inc_out = 1'b0; // Sleep state me instret count nahi hoga
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end

            STATE_TRAP_TAKEN: begin
                pc_src_out      = PC_TRAP;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b1;
                set_cause_out   = 1'b1;
                mie_clear_out   = 1'b1;
                mie_set_out     = 1'b0;
            end

            STATE_TRAP_RETURN: begin
                pc_src_out      = PC_EPC;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b1;
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
    
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            trap_pc_out <= 32'b0;
        end
        else if (curr_state == STATE_OPERATING) begin
            if ((mie_in & ip) || (id_valid_in && (exception | ecall | ebreak)))
                trap_pc_out <= pc_in;
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            trap_value_reg <= 32'h00000000;
        end
        else if (curr_state == STATE_OPERATING) begin
            if (id_valid_in && illegal_instr_in)
                trap_value_reg <= instr_in;
            else if (id_valid_in && misaligned_instr_in)
                trap_value_reg <= mem_addr_in;
            else if (id_valid_in && ebreak)
                trap_value_reg <= pc_in;
            else if (id_valid_in && ecall)
                trap_value_reg <= 32'h00000000;
            else
                trap_value_reg <= 32'h00000000;
        end
    end

    assign trap_value_out = trap_value_reg;
   
    always @(posedge clk_in or posedge rst_in) begin
        if(rst_in)
            curr_state <= STATE_RESET;
        else
            curr_state <= next_state;
    end    

    always @(posedge clk_in or posedge rst_in) begin
        if(rst_in) begin
            cause_out  <= 4'b0;
            i_or_e_out <= 1'b0;
        end
        else if(curr_state == STATE_OPERATING) begin
            if(mie_in & eip) begin
                cause_out  <= 4'b1011; // External interrupt
                i_or_e_out <= 1'b1;
            end
            else if(mie_in & sip) begin
                cause_out  <= 4'b0011; // Software interrupt
                i_or_e_out <= 1'b1;
            end
            else if(mie_in & tip) begin
                cause_out  <= 4'b0111; // Timer interrupt
                i_or_e_out <= 1'b1;
            end
            else if(id_valid_in && illegal_instr_in) begin
                cause_out  <= 4'b0010;
                i_or_e_out <= 1'b0;
            end
            else if(id_valid_in && misaligned_instr_in) begin
                cause_out  <= 4'b0000;
                i_or_e_out <= 1'b0;
            end
            else if(id_valid_in && ecall) begin
                cause_out  <= 4'b1011;
                i_or_e_out <= 1'b0;
            end
            else if(id_valid_in && ebreak) begin
                cause_out  <= 4'b0011;
                i_or_e_out <= 1'b0;
            end
        end
    end   

endmodule*/


`timescale 1ns / 1ps

module pragya_machine_control( 
   input         clk_in, rst_in,
   input  debug_req_in,             // From Debug Module (Pulse/Request)
   input  debug_mode_status_in,     //  Absolute state from pc_unit (Debug Mode is active)
   input [31:0]  pc_in,
   input         id_valid_in,
   input [31:0]  mem_addr_in,
   input         retire_valid_in,
   input [31:0]  instr_in,
   // from decoder
   input         illegal_instr_in,
   // from pipeline stage 1
   input         misaligned_instr_in,

   // from instruction
   input  [6:2]  opcode_6_to_2_in,
   input  [2:0]  funct3_in,
   input  [6:0]  funct7_in,
   input  [4:0]  rs1_addr_in,
   input  [4:0]  rs2_addr_in,
   input  [4:0]  rd_addr_in,
   // from interrupt controller
   input         e_irq_in, t_irq_in, s_irq_in,
   input         mie_in,
   input         meie_in, mtie_in, msie_in, meip_in, mtip_in, msip_in,
   // to CSR file
   output reg    i_or_e_out, set_epc_out, set_cause_out,
   output reg [3:0] cause_out,
   output reg    instret_inc_out, mie_clear_out, mie_set_out,
   output [31:0] trap_value_out,
   // to PC MUX
   output reg [1:0]  pc_src_out,
   output reg [31:0] trap_pc_out,
   output        trap_detected_out,
   output        mret_detected_out,
   // to Hazard unit & IMEM
   output        wfi_stall_out              
);
   
    // 5-bit States
    reg [4:0] curr_state;
    reg [4:0] next_state;
    reg [31:0] trap_value_reg;
   
    parameter STATE_RESET        = 5'b00001;
    parameter STATE_OPERATING    = 5'b00010;
    parameter STATE_TRAP_TAKEN   = 5'b00100;    
    parameter STATE_TRAP_RETURN  = 5'b01000;
    parameter STATE_WFI          = 5'b10000; // Nayi Sleep State
    parameter STATE_DEBUG        = 5'b10001;
   
    parameter PC_BOOT = 2'b00,
              PC_EPC  = 2'b01,
              PC_TRAP = 2'b10,
              PC_NEXT = 2'b11;

    wire exception;
    wire ip;
    wire eip;
    wire tip;
    wire sip;
    wire is_system;
    wire rs1_addr_zero;
    wire rs2_addr_zero;
    wire rd_zero;
    wire rs2_addr_mret;
    wire rs2_addr_ebreak;
    wire FUNCT3_zero;
    wire FUNCT7_zero;
    wire FUNCT7_mret;
    
    wire mret;
    wire ecall;
    wire ebreak;
    wire wfi;
    wire FUNCT7_wfi;
    wire rs2_addr_wfi;
    wire trap_condition;
    
    // COMBINATIONAL LOGIC
    assign trap_condition = (mie_in & ip) | exception | (id_valid_in && ecall) | (id_valid_in && ebreak);
    assign trap_detected_out = trap_condition & ~(debug_req_in | debug_mode_status_in);
    assign is_system   =  opcode_6_to_2_in[6] & opcode_6_to_2_in[5] & opcode_6_to_2_in[4]
                          & ~opcode_6_to_2_in[3] & ~opcode_6_to_2_in[2];
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
    
    // Decoded Instructions
    assign mret   = id_valid_in && is_system && FUNCT7_mret && rs2_addr_mret && rs1_addr_zero && FUNCT3_zero && rd_zero;
    assign ecall  = is_system & FUNCT7_zero & rs2_addr_zero & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign ebreak = is_system & FUNCT7_zero & rs2_addr_ebreak & rs1_addr_zero & FUNCT3_zero & rd_zero;
    assign wfi    = id_valid_in && is_system && FUNCT7_wfi && rs2_addr_wfi && rs1_addr_zero && FUNCT3_zero && rd_zero;
   
    // Interrupts logic (PLIC / CLINT)
    assign eip = meie_in & (e_irq_in | meip_in);
    assign tip = mtie_in & (t_irq_in | mtip_in);
    assign sip = msie_in & (s_irq_in | msip_in);
    assign ip  = eip | tip | sip;
    assign exception = id_valid_in && (illegal_instr_in | misaligned_instr_in);

    // WFI Stall Flag
    assign wfi_stall_out = (curr_state == STATE_WFI);

    // Next State Logic
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
            if (debug_req_in || debug_mode_status_in)
                next_state = STATE_DEBUG; // Wake from WFI directly to Debug Mode if requested
            else if (ip)
                next_state = STATE_OPERATING;
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
   
    // Combinational output logic
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
                instret_inc_out = 1'b0; // Sleep state me instret count nahi hoga
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b0;
            end
STATE_DEBUG: begin
    pc_src_out      = PC_NEXT;
    instret_inc_out = 1'b0; // Don't increment instruction retirement count in debug mode
    set_epc_out     = 1'b0;
    set_cause_out   = 1'b0;
    mie_clear_out   = 1'b0;
    mie_set_out     = 1'b0;
end
            STATE_TRAP_TAKEN: begin
                pc_src_out      = PC_TRAP;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b1;
                set_cause_out   = 1'b1;
                mie_clear_out   = 1'b1;
                mie_set_out     = 1'b0;
            end

            STATE_TRAP_RETURN: begin
                pc_src_out      = PC_EPC;
                instret_inc_out = 1'b0;
                set_epc_out     = 1'b0;
                set_cause_out   = 1'b0;
                mie_clear_out   = 1'b0;
                mie_set_out     = 1'b1;
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
    
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            trap_pc_out <= 32'b0;
        end
        else if (curr_state == STATE_OPERATING) begin
            if (trap_condition && ~(debug_req_in | debug_mode_status_in))
                trap_pc_out <= pc_in;
        end
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            trap_value_reg <= 32'h00000000;
        end
        else if (curr_state == STATE_OPERATING && ~(debug_req_in | debug_mode_status_in)) begin
            if (id_valid_in && illegal_instr_in)
                trap_value_reg <= instr_in;
            else if (id_valid_in && misaligned_instr_in)
                trap_value_reg <= mem_addr_in;
            else if (id_valid_in && ebreak)
                trap_value_reg <= pc_in;
            else if (id_valid_in && ecall)
                trap_value_reg <= 32'h00000000;
            else
                trap_value_reg <= 32'h00000000;
        end
    end

    assign trap_value_out = trap_value_reg;
   
    always @(posedge clk_in or posedge rst_in) begin
        if(rst_in)
            curr_state <= STATE_RESET;
        else
            curr_state <= next_state;
    end    

    always @(posedge clk_in or posedge rst_in) begin
        if(rst_in) begin
            cause_out  <= 4'b0;
            i_or_e_out <= 1'b0;
        end
        else if(curr_state == STATE_OPERATING && ~(debug_req_in | debug_mode_status_in)) begin
            if(mie_in & eip) begin
                cause_out  <= 4'b1011; // External interrupt
                i_or_e_out <= 1'b1;
            end
            else if(mie_in & sip) begin
                cause_out  <= 4'b0011; // Software interrupt
                i_or_e_out <= 1'b1;
            end
            else if(mie_in & tip) begin
                cause_out  <= 4'b0111; // Timer interrupt
                i_or_e_out <= 1'b1;
            end
            else if(id_valid_in && illegal_instr_in) begin
                cause_out  <= 4'b0010;
                i_or_e_out <= 1'b0;
            end
            else if(id_valid_in && misaligned_instr_in) begin
                cause_out  <= 4'b0000;
                i_or_e_out <= 1'b0;
            end
            else if(id_valid_in && ecall) begin
                cause_out  <= 4'b1011;
                i_or_e_out <= 1'b0;
            end
            else if(id_valid_in && ebreak) begin
                cause_out  <= 4'b0011;
                i_or_e_out <= 1'b0;
            end
        end
    end   

endmodule
