/*`timescale 1ns / 1ps

module pragya_csr( 
    input         clk_in,
    input         rst_in,

    //CSR Instruction Interface
    input         csr_wr_en_in, //from decoder
    input [11:0]  csr_addr_in,  //from decoder
    input [2:0]   csr_op_in,    //from decodr
    input [4:0]   csr_imm_in,   //from immediate generator
    input [31:0]  csr_data_in,  //from register file


    ///Trap Inputs
    input [31:0]  pc_in,        //from pc
    
    input         set_epc_in,   //from machine contrl
    input         set_cause_in, //from machine contrl
    input         i_or_e_in,    //from machine contrl
    input [3:0]   cause_in,     //from machine contrl
    input         mie_clear_in, mie_set_in,  //from machine contrl
    input [31:0]  trap_value_in,

    // Counter Input
    input         instret_inc_in,  //from machine contrl
    
    //Outputs
    output reg [31:0] csr_data_out, //to wb_mux
    output     [31:0] epc_out,      //to pc
    output     [31:0] trap_address_out, //to pc
    output reg        mie_out,        //to machine control
    output meie_out,
    output mtie_out,
    output msie_out
    
   );

    
    reg [31:0] mie;
    reg [31:0] misa;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mtval;
    reg [31:0] mscratch;
    reg [31:0] mip;
    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg [31:0] pmpaddr16;
        
    reg [31:0]   csr_wdata;
    reg          mpie_out;
    wire [31:0]  mstatus_out;
    wire [31:0]  mtvec_out;
    wire [31:0]  misa_out;
    
    reg  [1:0 ] mtvec_mode; // machine trap mode
    reg  [29:0] mtvec_base; // machine trap base address
   
    wire [31:0] trap_mux_out;
    wire [31:0] vec_mux_out;
    wire [31:0] base_offset;

   
    localparam [31:0] MISA_RESET = 32'h40001100;
    localparam [31:0] MISA_SUPPORTED_MASK = 32'h40001100;
 wire csr_do_write;

assign csr_do_write =
       csr_wr_en_in &&
       (
           (csr_op_in == 3'b001) ||                         // CSRRW
           (csr_op_in == 3'b101) ||                         // CSRRWI

           ((csr_op_in == 3'b010) && (csr_data_in != 32'b0)) || // CSRRS
           ((csr_op_in == 3'b011) && (csr_data_in != 32'b0)) || // CSRRC

           ((csr_op_in == 3'b110) && (csr_imm_in != 5'b0)) ||   // CSRRSI
           ((csr_op_in == 3'b111) && (csr_imm_in != 5'b0))      // CSRRCI
       );
    
   // CSR ADDRESSES ----------------------------
   
   // Performance Counters
    parameter CYCLE     =         12'hC00;
    parameter INSTRET   =         12'hC02;
    parameter CYCLEH    =         12'hC80;
    parameter INSTRETH  =         12'hC82;
   
   // Machine Trap Setup
    parameter MSTATUS   =         12'h300;
    parameter MIE       =         12'h304;
    parameter MISA      =         12'h301;
    parameter MTVEC     =         12'h305;
    parameter MVENDORID = 12'hF11;
    parameter MARCHID   = 12'hF12;
    parameter MIMPID    = 12'hF13;
    parameter MHARTID   = 12'hF14;
   
   // Machine Trap Handling
    parameter MSCRATCH  =         12'h340;
    parameter MEPC      =         12'h341;
    parameter MCAUSE    =         12'h342;
    parameter MTVAL     =         12'h343;
    parameter MIP       =         12'h344;  
    parameter PMPADDR16 =         12'h3c0;
   // Machine Counter / Timers
    parameter MCYCLE    =         12'hB00;
    parameter MINSTRET  =         12'hB02;
    parameter MCYCLEH   =         12'hB80;
    parameter MINSTRETH =         12'hB82;
   
   
    assign base_offset = cause_in << 2;
    assign mtvec_out = {mtvec_base, mtvec_mode};
    assign trap_mux_out = i_or_e_in ? vec_mux_out : {mtvec_base, 2'b00};
    assign vec_mux_out = mtvec_out[0] ? {mtvec_base, 2'b00} + base_offset : {mtvec_base, 2'b00};
    assign trap_address_out = trap_mux_out;
    assign meie_out = mie[11];
    assign mtie_out = mie[7];
    assign msie_out = mie[3];
    assign mstatus_out = {19'b0, 2'b11, 3'b0, mpie_out, 3'b0 , mie_out, 3'b0};
    assign epc_out          = mepc;
    assign misa_out =     misa;
   
  

  
    always @*
        begin
            case(csr_addr_in)
                CYCLE:         csr_data_out = mcycle[31:0];
                CYCLEH:        csr_data_out = mcycle[63:32];
                INSTRET:       csr_data_out = minstret[31:0];
                INSTRETH:      csr_data_out = minstret[63:32];
                MSTATUS:       csr_data_out = mstatus_out;
                MISA:          csr_data_out = misa_out;
                MIE:           csr_data_out = mie;
                MTVEC:         csr_data_out = mtvec_out;
                MSCRATCH:      csr_data_out = mscratch;
                MEPC:          csr_data_out = mepc;
                MCAUSE:        csr_data_out = mcause;
                MTVAL:         csr_data_out = mtval;
                MIP:           csr_data_out = mip;
                MCYCLE:        csr_data_out = mcycle[31:0];
                MCYCLEH:       csr_data_out = mcycle[63:32];
                MINSTRET:      csr_data_out = minstret[31:0];
                MINSTRETH:     csr_data_out = minstret[63:32];
                MVENDORID:     csr_data_out = 32'h00000000;
                MARCHID:       csr_data_out = 32'h00000005;
		MIMPID:        csr_data_out = 32'h00000000;
		MHARTID:       csr_data_out = 32'h00000000;
                PMPADDR16:     csr_data_out = pmpaddr16;
                default:       csr_data_out = 32'b0;
            endcase
        end
    
    
    always @(*) 
        begin
            case (csr_op_in)
                3'b001: csr_wdata = csr_data_in;                         // CSRRW
                3'b010: csr_wdata = csr_data_out | csr_data_in;         // CSRRS
                3'b011: csr_wdata = csr_data_out & ~csr_data_in;        // CSRRC
                3'b101: csr_wdata = {27'b0, csr_imm_in};                // CSRRWI
                3'b110: csr_wdata = csr_data_out | {27'b0, csr_imm_in}; // CSRRSI
                3'b111: csr_wdata = csr_data_out & ~{27'b0, csr_imm_in};// CSRRCI
                default: csr_wdata = csr_data_out;
            endcase
        end

    always @(posedge clk_in or posedge rst_in) 
        begin
            if (rst_in) begin
                mie_out  <= 1'b0;
                mpie_out <= 1'b0;
                mie       <= 32'b0;
                mtvec_mode <= 2'b00;
                mtvec_base <= 30'b0;
                mepc      <= 32'b0;
                mcause    <= 32'b0;
		misa      <= MISA_RESET;
                mtval     <= 32'b0;
                mscratch  <= 32'b0;
                mip       <= 32'b0;
                mcycle    <= 64'b0;
                minstret  <= 64'b0;
                pmpaddr16 <= 32'b0;
                end
            else begin

        // Counters
                      mcycle   <= mcycle + 64'd1;
                if (instret_inc_in) 
                    
                     minstret <= minstret + 64'd1;
                

        // Trap updates
                if (set_epc_in)
                    mepc <= {pc_in[31:2], 2'b00};

                if (set_cause_in) begin
                    mcause <= {i_or_e_in, 27'b0, cause_in};
                    mtval  <= trap_value_in;
                    end

     
            
                if(mie_clear_in == 1'b1)
                    begin
                        mpie_out <= mie_out;
                        mie_out <= 1'b0;
                    end
                else if(mie_set_in == 1'b1)
                    begin
                        mie_out <= mpie_out;
                        mpie_out <= 1'b1;
                    end
        

        // CSR writes
            if (!set_cause_in && csr_do_write) begin
                case (csr_addr_in)
                    MSTATUS:   begin
                            mie_out  <= csr_wdata[3];
                            mpie_out <= csr_wdata[7];
                            end
                    MIE:        mie      <= csr_wdata & 32'h00000888; 
                    MTVEC:      begin
                            mtvec_mode <= csr_wdata[1:0];
                            mtvec_base <= csr_wdata[31:2];
                            end
                    MISA: begin
    misa <= csr_wdata & MISA_SUPPORTED_MASK;
    misa[31:30] <= 2'b01;
    misa[8]     <= 1'b1;   // I extension
    misa[12]    <= csr_wdata[12]; // M extension
end
                    MSCRATCH:  mscratch <= csr_wdata;
                    MEPC:      mepc     <= {csr_wdata[31:2], 2'b00};
                    MCAUSE:    mcause   <= csr_wdata;
                    MTVAL:     mtval    <= csr_wdata;
                    MIP:       mip      <= csr_wdata;

                    MCYCLE:    mcycle[31:0]    <= csr_wdata;
                    MCYCLEH:   mcycle[63:32]   <= csr_wdata;

                    MINSTRET:  minstret[31:0]  <= csr_wdata;
                    MINSTRETH: minstret[63:32] <= csr_wdata;
                    PMPADDR16: pmpaddr16       <= csr_wdata;

                    default: ;
                endcase
            end

        end
    end

endmodule*/


/*

`timescale 1ns / 1ps
module pragya_csr ( 
    input          clk_in,
    input          rst_in,

    // --- HARDWARE DEBUG INPUTS ---
    input wire        debug_update_dpc_in,   // High when entering debug mode to save PC
    input wire  [31:0] debug_pc_save_in,      // The PC value to save into dpc
    input wire  [2:0]  debug_cause_in,        // Halt cause

    // CSR Instruction Interface
    input          csr_wr_en_in, // from decoder
    input [11:0]   csr_addr_in,  // from decoder
    input [2:0]    csr_op_in,    // from decoder
    input [4:0]    csr_imm_in,   // from immediate generator
    input [31:0]   csr_data_in,  // from register file

    // Trap Inputs
    input [31:0]   pc_in,        // from pc
    input          set_epc_in,   // from machine control
    input          set_cause_in, // from machine control
    input          i_or_e_in,    // from machine control
    input [3:0]    cause_in,     // from machine control
    input          mie_clear_in, 
    input          mie_set_in,   // from machine control
    input [31:0]   trap_value_in,

    // Counter Input
    input          instret_inc_in,  // from machine control
    
    // Outputs
    output reg [31:0] csr_data_out,     // to wb_mux
    output      [31:0] epc_out,          // to pc
    output      [31:0] trap_address_out, // to pc
    output reg        mie_out,          // to machine control
    output      [31:0] dpc_out,          // to pc_unit
    output             meie_out,
    output             mtie_out,
    output             msie_out
);

    reg [31:0] mie;
    reg [31:0] misa;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mtval;
    reg [31:0] mscratch;
    reg [31:0] mip;
    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg [31:0] pmpaddr16;
        
    // --- DEBUG REGISTERS ---
    reg [31:0] dcsr;
    reg [31:0] dpc;
    reg [31:0] dscratch0;
    reg [31:0] dscratch1;

    reg [31:0]   csr_wdata;
    reg          mpie_out;
    wire [31:0]  mstatus_out;
    wire [31:0]  mtvec_out;
    wire [31:0]  misa_out;
    
    reg  [1:0 ] mtvec_mode; // machine trap mode
    reg  [29:0] mtvec_base; // machine trap base address
   
    wire [31:0] trap_mux_out;
    wire [31:0] vec_mux_out;
    wire [31:0] base_offset;

    localparam [31:0] MISA_RESET          = 32'h40001100;
    localparam [31:0] MISA_SUPPORTED_MASK = 32'h40001100;

    wire csr_do_write;
    assign csr_do_write =
        csr_wr_en_in &&
        (
            (csr_op_in == 3'b001) ||                                 // CSRRW
            (csr_op_in == 3'b101) ||                                 // CSRRWI
            ((csr_op_in == 3'b010) && (csr_data_in != 32'b0)) ||     // CSRRS
            ((csr_op_in == 3'b011) && (csr_data_in != 32'b0)) ||     // CSRRC
            ((csr_op_in == 3'b110) && (csr_imm_in != 5'b0)) ||       // CSRRSI
            ((csr_op_in == 3'b111) && (csr_imm_in != 5'b0))          // CSRRCI
        );
    
    // CSR ADDRESSES ----------------------------
    // Performance Counters
    parameter CYCLE     = 12'hC00;
    parameter INSTRET   = 12'hC02;
    parameter CYCLEH    = 12'hC80;
    parameter INSTRETH  = 12'hC82;
   
    // Machine Trap Setup
    parameter MSTATUS   = 12'h300;
    parameter MIE       = 12'h304;
    parameter MISA      = 12'h301;
    parameter MTVEC     = 12'h305;
    parameter MVENDORID = 12'hF11;
    parameter MARCHID   = 12'hF12;
    parameter MIMPID    = 12'hF13;
    parameter MHARTID   = 12'hF14;
   
    // Machine Trap Handling
    parameter MSCRATCH  = 12'h340;
    parameter MEPC      = 12'h341;
    parameter MCAUSE    = 12'h342;
    parameter MTVAL     = 12'h343;
    parameter MIP       = 12'h344;  
    parameter PMPADDR16 = 12'h3C0;

    // Machine Counter / Timers
    parameter MCYCLE    = 12'hB00;
    parameter MINSTRET  = 12'hB02;
    parameter MCYCLEH   = 12'hB80;
    parameter MINSTRETH = 12'hB82;

    // --- DEBUG CSR ADDRESSES ---
    parameter DCSR      = 12'h7B0;
    parameter DPC       = 12'h7B1;
    parameter DSCRATCH0 = 12'h7B2;
    parameter DSCRATCH1 = 12'h7B3;
   
    assign base_offset      = cause_in << 2;
    assign mtvec_out        = {mtvec_base, mtvec_mode};
    assign trap_mux_out     = i_or_e_in ? vec_mux_out : {mtvec_base, 2'b00};
    assign vec_mux_out      = mtvec_out[0] ? {mtvec_base, 2'b00} + base_offset : {mtvec_base, 2'b00};
    assign trap_address_out = trap_mux_out;
    assign meie_out         = mie[11];
    assign mtie_out         = mie[7];
    assign msie_out         = mie[3];
    assign mstatus_out      = {19'b0, 2'b11, 3'b0, mpie_out, 3'b0 , mie_out, 3'b0};
    assign epc_out          = mepc;
    assign misa_out         = misa;
    assign dpc_out          = dpc;

    always @* begin
        case (csr_addr_in)
            CYCLE:      csr_data_out = mcycle[31:0];
            CYCLEH:     csr_data_out = mcycle[63:32];
            INSTRET:    csr_data_out = minstret[31:0];
            INSTRETH:   csr_data_out = minstret[63:32];
            MSTATUS:    csr_data_out = mstatus_out;
            MISA:       csr_data_out = misa_out;
            MIE:        csr_data_out = mie;
            MTVEC:      csr_data_out = mtvec_out;
            MSCRATCH:   csr_data_out = mscratch;
            MEPC:       csr_data_out = mepc;
            MCAUSE:     csr_data_out = mcause;
            MTVAL:      csr_data_out = mtval;
            MIP:        csr_data_out = mip;
            MCYCLE:     csr_data_out = mcycle[31:0];
            MCYCLEH:    csr_data_out = mcycle[63:32];
            MINSTRET:   csr_data_out = minstret[31:0];
            MINSTRETH:  csr_data_out = minstret[63:32];
            MVENDORID:  csr_data_out = 32'h00000000;
            MARCHID:    csr_data_out = 32'h00000005;
            MIMPID:     csr_data_out = 32'h00000000;
            MHARTID:    csr_data_out = 32'h00000000;
            PMPADDR16:  csr_data_out = pmpaddr16;
            DCSR:       csr_data_out = dcsr;
            DPC:        csr_data_out = dpc;
            DSCRATCH0:  csr_data_out = dscratch0;
            DSCRATCH1:  csr_data_out = dscratch1;
            default:    csr_data_out = 32'b0;
        endcase
    end

    always @(*) begin
        case (csr_op_in)
            3'b001:  csr_wdata = csr_data_in;                          // CSRRW
            3'b010:  csr_wdata = csr_data_out | csr_data_in;          // CSRRS
            3'b011:  csr_wdata = csr_data_out & ~csr_data_in;         // CSRRC
            3'b101:  csr_wdata = {27'b0, csr_imm_in};                 // CSRRWI
            3'b110:  csr_wdata = csr_data_out | {27'b0, csr_imm_in};  // CSRRSI
            3'b111:  csr_wdata = csr_data_out & ~{27'b0, csr_imm_in}; // CSRRCI
            default: csr_wdata = csr_data_out;
        endcase
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            mie_out    <= 1'b0;
            mpie_out   <= 1'b0;
            mie        <= 32'b0;
            mtvec_mode <= 2'b00;
            mtvec_base <= 30'b0;
            mepc       <= 32'b0;
            mcause     <= 32'b0;
            misa       <= MISA_RESET;
            mtval      <= 32'b0;
            mscratch   <= 32'b0;
            mip        <= 32'b0;
            mcycle     <= 64'b0;
            minstret   <= 64'b0;
            pmpaddr16  <= 32'b0;
            dcsr       <= 32'h4a030003; // xdebugver=4, prv=Machine (3)
            dpc        <= 32'b0;
            dscratch0  <= 32'b0;
            dscratch1  <= 32'b0;
        end else begin
            // Counters
            mcycle <= mcycle + 64'd1;
            if (instret_inc_in) 
                minstret <= minstret + 64'd1;

            // Trap updates
            if (set_epc_in)
                mepc <= {pc_in[31:2], 2'b00};

            if (set_cause_in) begin
                mcause <= {i_or_e_in, 27'b0, cause_in};
                mtval  <= trap_value_in;
            end

            if (mie_clear_in == 1'b1) begin
                mpie_out <= mie_out;
                mie_out  <= 1'b0;
            end else if (mie_set_in == 1'b1) begin
                mie_out  <= mpie_out;
                mpie_out <= 1'b1;
            end

            // Hardware Debug State Updates
            if (debug_update_dpc_in) begin
                dpc  <= {debug_pc_save_in[31:2], 2'b00}; // Save interrupted PC
                dcsr <= {dcsr[31:9], debug_cause_in, dcsr[5:2], 2'b11}; // Update halt cause
            end

            // CSR writes
            if (!set_cause_in && csr_do_write) begin
                case (csr_addr_in)
                    MSTATUS: begin
                        mie_out  <= csr_wdata[3];
                        mpie_out <= csr_wdata[7];
                    end
                    MIE:       mie        <= csr_wdata & 32'h00000888; 
                    MTVEC: begin
                        mtvec_mode <= csr_wdata[1:0];
                        mtvec_base <= csr_wdata[31:2];
                    end
                    MISA: begin
                        misa        <= csr_wdata & MISA_SUPPORTED_MASK;
                        misa[31:30] <= 2'b01;
                        misa[8]     <= 1'b1;              // I extension
                        misa[12]    <= csr_wdata[12];     // M extension
                    end
                    MSCRATCH:  mscratch   <= csr_wdata;
                    MEPC:      mepc       <= {csr_wdata[31:2], 2'b00};
                    MCAUSE:    mcause     <= csr_wdata;
                    MTVAL:     mtval      <= csr_wdata;
                    MIP:       mip        <= csr_wdata;
                    MCYCLE:    mcycle[31:0]    <= csr_wdata;
                    MCYCLEH:   mcycle[63:32]   <= csr_wdata;
                    MINSTRET:  minstret[31:0]  <= csr_wdata;
                    MINSTRETH: minstret[63:32] <= csr_wdata;
                    PMPADDR16: pmpaddr16       <= csr_wdata;
                    DCSR:      dcsr       <= {csr_wdata[31:9], dcsr[8:6], csr_wdata[5:0]}; // Preserve read-only fields
                    DPC:       dpc        <= csr_wdata;
                    DSCRATCH0: dscratch0  <= csr_wdata;
                    DSCRATCH1: dscratch1  <= csr_wdata;
                    default: ;
                endcase
            end
        end
    end

endmodule*/



`timescale 1ns / 1ps
module pragya_csr ( 
    input          clk_in,
    input          rst_in,

    // --- HARDWARE DEBUG INPUTS ---
    input wire        debug_update_dpc_in,   // High when entering debug mode to save PC
    input wire  [31:0] debug_pc_save_in,      // The PC value to save into dpc
    input wire  [2:0]  debug_cause_in,        // Halt cause

    // CSR Instruction Interface
    input          csr_wr_en_in, // from decoder
    input [11:0]   csr_addr_in,  // from decoder
    input [2:0]    csr_op_in,    // from decoder
    input [4:0]    csr_imm_in,   // from immediate generator
    input [31:0]   csr_data_in,  // from register file

    // Trap Inputs
    input [31:0]   pc_in,        // from pc
    input          set_epc_in,   // from machine control
    input          set_cause_in, // from machine control
    input          i_or_e_in,    // from machine control
    input [3:0]    cause_in,     // from machine control
    input          mie_clear_in, 
    input          mie_set_in,   // from machine control
    input [31:0]   trap_value_in,

    // Counter Input
    input          instret_inc_in,  // from machine control
    
    // Outputs
    output reg [31:0] csr_data_out,     // to wb_mux
    output      [31:0] epc_out,          // to pc
    output      [31:0] trap_address_out, // to pc
    output reg        mie_out,          // to machine control
    output      [31:0] dpc_out,          // to pc_unit
    output             meie_out,
    output             mtie_out,
    output             msie_out
);

    reg [31:0] mie;
    reg [31:0] misa;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mtval;
    reg [31:0] mscratch;
    reg [31:0] mip;
    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg [31:0] pmpaddr16;
        
    // --- DEBUG REGISTERS ---
    reg [31:0] dcsr;
    reg [31:0] dpc;
    reg [31:0] dscratch0;
    reg [31:0] dscratch1;

    reg [31:0]   csr_wdata;
    reg          mpie_out;
    wire [31:0]  mstatus_out;
    wire [31:0]  mtvec_out;
    wire [31:0]  misa_out;
    
    reg  [1:0 ] mtvec_mode; // machine trap mode
    reg  [29:0] mtvec_base; // machine trap base address
   
    wire [31:0] trap_mux_out;
    wire [31:0] vec_mux_out;
    wire [31:0] base_offset;

    localparam [31:0] MISA_RESET          = 32'h40001100;
    localparam [31:0] MISA_SUPPORTED_MASK = 32'h40001100;

    wire csr_do_write;
    assign csr_do_write =
        csr_wr_en_in &&
        (
            (csr_op_in == 3'b001) ||                                 // CSRRW
            (csr_op_in == 3'b101) ||                                 // CSRRWI
            ((csr_op_in == 3'b010) && (csr_data_in != 32'b0)) ||     // CSRRS
            ((csr_op_in == 3'b011) && (csr_data_in != 32'b0)) ||     // CSRRC
            ((csr_op_in == 3'b110) && (csr_imm_in != 5'b0)) ||       // CSRRSI
            ((csr_op_in == 3'b111) && (csr_imm_in != 5'b0))          // CSRRCI
        );
    
    // CSR ADDRESSES ----------------------------
    // Performance Counters
    parameter CYCLE     = 12'hC00;
    parameter INSTRET   = 12'hC02;
    parameter CYCLEH    = 12'hC80;
    parameter INSTRETH  = 12'hC82;
   
    // Machine Trap Setup
    parameter MSTATUS   = 12'h300;
    parameter MIE       = 12'h304;
    parameter MISA      = 12'h301;
    parameter MTVEC     = 12'h305;
    parameter MVENDORID = 12'hF11;
    parameter MARCHID   = 12'hF12;
    parameter MIMPID    = 12'hF13;
    parameter MHARTID   = 12'hF14;
   
    // Machine Trap Handling
    parameter MSCRATCH  = 12'h340;
    parameter MEPC      = 12'h341;
    parameter MCAUSE    = 12'h342;
    parameter MTVAL     = 12'h343;
    parameter MIP       = 12'h344;  
    parameter PMPADDR16 = 12'h3C0;

    // Machine Counter / Timers
    parameter MCYCLE    = 12'hB00;
    parameter MINSTRET  = 12'hB02;
    parameter MCYCLEH   = 12'hB80;
    parameter MINSTRETH = 12'hB82;

    // --- DEBUG CSR ADDRESSES ---
    parameter DCSR      = 12'h7B0;
    parameter DPC       = 12'h7B1;
    parameter DSCRATCH0 = 12'h7B2;
    parameter DSCRATCH1 = 12'h7B3;
   
    assign base_offset      = cause_in << 2;
    assign mtvec_out        = {mtvec_base, mtvec_mode};
    assign trap_mux_out     = i_or_e_in ? vec_mux_out : {mtvec_base, 2'b00};
    assign vec_mux_out      = mtvec_out[0] ? {mtvec_base, 2'b00} + base_offset : {mtvec_base, 2'b00};
    assign trap_address_out = trap_mux_out;
    assign meie_out         = mie[11];
    assign mtie_out         = mie[7];
    assign msie_out         = mie[3];
    assign mstatus_out      = {19'b0, 2'b11, 3'b0, mpie_out, 3'b0 , mie_out, 3'b0};
    assign epc_out          = mepc;
    assign misa_out         = misa;
    assign dpc_out          = dpc;

    always @(*) begin
        case (csr_addr_in)
            CYCLE:      csr_data_out = mcycle[31:0];
            CYCLEH:     csr_data_out = mcycle[63:32];
            INSTRET:    csr_data_out = minstret[31:0];
            INSTRETH:   csr_data_out = minstret[63:32];
            MSTATUS:    csr_data_out = mstatus_out;
            MISA:       csr_data_out = misa_out;
            MIE:        csr_data_out = mie;
            MTVEC:      csr_data_out = mtvec_out;
            MSCRATCH:   csr_data_out = mscratch;
            MEPC:       csr_data_out = mepc;
            MCAUSE:     csr_data_out = mcause;
            MTVAL:      csr_data_out = mtval;
            MIP:        csr_data_out = mip;
            MCYCLE:     csr_data_out = mcycle[31:0];
            MCYCLEH:    csr_data_out = mcycle[63:32];
            MINSTRET:   csr_data_out = minstret[31:0];
            MINSTRETH:  csr_data_out = minstret[63:32];
            MVENDORID:  csr_data_out = 32'h00000000;
            MARCHID:    csr_data_out = 32'h00000005;
            MIMPID:     csr_data_out = 32'h00000000;
            MHARTID:    csr_data_out = 32'h00000000;
            PMPADDR16:  csr_data_out = pmpaddr16;
            DCSR:       csr_data_out = dcsr;
            DPC:        csr_data_out = dpc;
            DSCRATCH0:  csr_data_out = dscratch0;
            DSCRATCH1:  csr_data_out = dscratch1;
            default:    csr_data_out = 32'b0;
        endcase
    end

    always @(*) begin
        case (csr_op_in)
            3'b001:  csr_wdata = csr_data_in;                          // CSRRW
            3'b010:  csr_wdata = csr_data_out | csr_data_in;          // CSRRS
            3'b011:  csr_wdata = csr_data_out & ~csr_data_in;         // CSRRC
            3'b101:  csr_wdata = {27'b0, csr_imm_in};                 // CSRRWI
            3'b110:  csr_wdata = csr_data_out | {27'b0, csr_imm_in};  // CSRRSI
            3'b111:  csr_wdata = csr_data_out & ~{27'b0, csr_imm_in}; // CSRRCI
            default: csr_wdata = csr_data_out;
        endcase
    end

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            mie_out    <= 1'b0;
            mpie_out   <= 1'b0;
            mie        <= 32'b0;
            mtvec_mode <= 2'b00;
            mtvec_base <= 30'b0;
            mepc       <= 32'b0;
            mcause     <= 32'b0;
            misa       <= MISA_RESET;
            mtval      <= 32'b0;
            mscratch   <= 32'b0;
            mip        <= 32'b0;
            mcycle     <= 64'b0;
            minstret   <= 64'b0;
            pmpaddr16  <= 32'b0;
            dcsr       <= 32'h4a030003; // xdebugver=4, prv=Machine (3)
            dpc        <= 32'b0;
            dscratch0  <= 32'b0;
            dscratch1  <= 32'b0;
        end else begin
            // Counters
            mcycle <= mcycle + 64'd1;
            if (instret_inc_in) 
                minstret <= minstret + 64'd1;

            // Trap updates
            if (set_epc_in)
                mepc <= {pc_in[31:2], 2'b00};

            if (set_cause_in) begin
                mcause <= {i_or_e_in, 27'b0, cause_in};
                mtval  <= trap_value_in;
            end

            if (mie_clear_in == 1'b1) begin
                mpie_out <= mie_out;
                mie_out  <= 1'b0;
            end else if (mie_set_in == 1'b1) begin
                mie_out  <= mpie_out;
                mpie_out <= 1'b1;
            end

            // Hardware Debug State Updates
            if (debug_update_dpc_in) begin
                dpc  <= {debug_pc_save_in[31:2], 2'b00}; // Save interrupted PC
                dcsr <= {dcsr[31:9], debug_cause_in, dcsr[5:2], 2'b11}; // Update halt cause
            end

            // CSR writes
            if (!set_cause_in && csr_do_write) begin
                case (csr_addr_in)
                    MSTATUS: begin
                        mie_out  <= csr_wdata[3];
                        mpie_out <= csr_wdata[7];
                    end
                    MIE:       mie        <= csr_wdata & 32'h00000888; 
                    MTVEC: begin
                        mtvec_mode <= csr_wdata[1:0];
                        mtvec_base <= csr_wdata[31:2];
                    end
                    MISA: begin
                        misa        <= csr_wdata & MISA_SUPPORTED_MASK;
                        misa[31:30] <= 2'b01;
                        misa[8]     <= 1'b1;              // I extension
                        misa[12]    <= csr_wdata[12];     // M extension
                    end
                    MSCRATCH:  mscratch   <= csr_wdata;
                    MEPC:      mepc       <= {csr_wdata[31:2], 2'b00};
                    MCAUSE:    mcause     <= csr_wdata;
                    MTVAL:     mtval      <= csr_wdata;
                    MIP:       mip        <= csr_wdata;
                    MCYCLE:    mcycle[31:0]    <= csr_wdata;
                    MCYCLEH:   mcycle[63:32]   <= csr_wdata;
                    MINSTRET:  minstret[31:0]  <= csr_wdata;
                    MINSTRETH: minstret[63:32] <= csr_wdata;
                    PMPADDR16: pmpaddr16       <= csr_wdata;
                    DCSR:      dcsr       <= {csr_wdata[31:9], dcsr[8:6], csr_wdata[5:0]}; // Preserve read-only fields
                    DPC:       dpc        <= csr_wdata;
                    DSCRATCH0: dscratch0  <= csr_wdata;
                    DSCRATCH1: dscratch1  <= csr_wdata;
                    default: ;
                endcase
            end
        end
    end

endmodule
