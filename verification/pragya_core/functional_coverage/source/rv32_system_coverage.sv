`timescale 1ns / 1ps

/******************************************************************************
 * Project : Pragya RISC-V Core
 * File    : rv32_system_coverage.sv
 *
 * System-level functional coverage for:
 *   1. CSR instructions and CSR registers
 *   2. Machine-mode exceptions
 *   3. Machine-mode interrupts
 *   4. MRET / ECALL / EBREAK
 *
 * IMPORTANT:
 *   No RTL modification is required.
 *
 *   The testbench passes the signals from:
 *       dut.csr_inst
 *       dut.machine_control_inst
 *       dut.decoder_inst
 ******************************************************************************/

class rv32_system_coverage;

    //======================================================================
    // CSR instruction signals
    //======================================================================

    logic        csr_valid;
    logic [11:0] csr_addr;
    logic [2:0]  csr_op;
    logic        csr_we;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;

    //======================================================================
    // CSR internal values
    //======================================================================

    logic [31:0] mstatus;
    logic [31:0] mie;
    logic [31:0] mtvec;
    logic [31:0] mepc;
    logic [31:0] mcause;
    logic [31:0] mtval;
    logic [31:0] mscratch;
    logic [31:0] mip;

    logic [63:0] mcycle;
    logic [63:0] minstret;

    logic        mie_global;
    logic        mpie;

    logic [1:0]  mtvec_mode;

    //======================================================================
    // Trap signals
    //======================================================================

    logic        trap_taken;
    logic        is_interrupt;
    logic        is_exception;

    logic [3:0]  cause;
    logic        interrupt_flag;

    logic [31:0] trap_pc;

    //======================================================================
    // System instructions
    //======================================================================

    logic ecall;
    logic ebreak;
    logic mret;

    //======================================================================
    // Interrupt signals
    //======================================================================

    logic irq_software;
    logic irq_timer;
    logic irq_external;

    logic irq_software_pending;
    logic irq_timer_pending;
    logic irq_external_pending;

    //======================================================================
    // CSR addresses actually implemented by pragya_csr
    //======================================================================

    localparam logic [11:0] CSR_MSTATUS   = 12'h300;
    localparam logic [11:0] CSR_MISA      = 12'h301;
    localparam logic [11:0] CSR_MIE       = 12'h304;
    localparam logic [11:0] CSR_MTVEC     = 12'h305;

    localparam logic [11:0] CSR_MSCRATCH  = 12'h340;
    localparam logic [11:0] CSR_MEPC      = 12'h341;
    localparam logic [11:0] CSR_MCAUSE    = 12'h342;
    localparam logic [11:0] CSR_MTVAL     = 12'h343;
    localparam logic [11:0] CSR_MIP       = 12'h344;

    localparam logic [11:0] CSR_MCYCLE    = 12'hB00;
    localparam logic [11:0] CSR_MINSTRET  = 12'hB02;
    localparam logic [11:0] CSR_MCYCLEH   = 12'hB80;
    localparam logic [11:0] CSR_MINSTRETH = 12'hB82;

    localparam logic [11:0] CSR_CYCLE     = 12'hC00;
    localparam logic [11:0] CSR_INSTRET   = 12'hC02;
    localparam logic [11:0] CSR_CYCLEH    = 12'hC80;
    localparam logic [11:0] CSR_INSTRETH  = 12'hC82;

    localparam logic [11:0] CSR_MVENDORID = 12'hF11;
    localparam logic [11:0] CSR_MARCHID   = 12'hF12;
    localparam logic [11:0] CSR_MIMPID    = 12'hF13;
    localparam logic [11:0] CSR_MHARTID   = 12'hF14;


    //======================================================================
    // CSR OPERATION CODES
    //
    // Your pragya_csr uses:
    //
    // 001 CSRRW
    // 010 CSRRS
    // 011 CSRRC
    // 101 CSRRWI
    // 110 CSRRSI
    // 111 CSRRCI
    //======================================================================

    localparam logic [2:0] CSR_OP_RW  = 3'b001;
    localparam logic [2:0] CSR_OP_RS  = 3'b010;
    localparam logic [2:0] CSR_OP_RC  = 3'b011;

    localparam logic [2:0] CSR_OP_RWI = 3'b101;
    localparam logic [2:0] CSR_OP_RSI = 3'b110;
    localparam logic [2:0] CSR_OP_RCI = 3'b111;


    //======================================================================
    // MACHINE EXCEPTION CAUSES IMPLEMENTED BY YOUR MACHINE CONTROL
    //======================================================================

    localparam logic [3:0] CAUSE_INSTR_MISALIGNED = 4'b0000;
    localparam logic [3:0] CAUSE_ILLEGAL_INSTR    = 4'b0010;
    localparam logic [3:0] CAUSE_BREAKPOINT       = 4'b0011;
    localparam logic [3:0] CAUSE_ECALL_M          = 4'b1011;


    //======================================================================
    // INTERRUPT CAUSES IMPLEMENTED BY YOUR MACHINE CONTROL
    //======================================================================

    localparam logic [3:0] CAUSE_IRQ_SOFTWARE = 4'b0011;
    localparam logic [3:0] CAUSE_IRQ_TIMER    = 4'b0111;
    localparam logic [3:0] CAUSE_IRQ_EXTERNAL = 4'b1011;


    //======================================================================
    // COVERGROUP 1
    // CSR COVERAGE
    //======================================================================

    covergroup cg_csr;

        option.per_instance = 1;
        option.name = "PRAGYA_CSR_COVERAGE";

        //--------------------------------------------------------------
        // CSR address
        //--------------------------------------------------------------

        cp_csr_addr : coverpoint csr_addr {

            bins mstatus   = {CSR_MSTATUS};
            bins misa      = {CSR_MISA};
            bins mie       = {CSR_MIE};
            bins mtvec     = {CSR_MTVEC};

            bins mscratch  = {CSR_MSCRATCH};
            bins mepc      = {CSR_MEPC};
            bins mcause    = {CSR_MCAUSE};
            bins mtval     = {CSR_MTVAL};
            bins mip       = {CSR_MIP};

            bins mcycle    = {CSR_MCYCLE};
            bins minstret  = {CSR_MINSTRET};
            bins mcycleh   = {CSR_MCYCLEH};
            bins minstreth = {CSR_MINSTRETH};

            bins cycle     = {CSR_CYCLE};
            bins instret   = {CSR_INSTRET};
            bins cycleh    = {CSR_CYCLEH};
            bins instreth  = {CSR_INSTRETH};

            bins mvendorid = {CSR_MVENDORID};
            bins marchid   = {CSR_MARCHID};
            bins mimpid    = {CSR_MIMPID};
            bins mhartid   = {CSR_MHARTID};
        }


        //--------------------------------------------------------------
        // CSR operations
        //--------------------------------------------------------------

        cp_csr_op : coverpoint csr_op {

            bins csrrw  = {CSR_OP_RW};
            bins csrrs  = {CSR_OP_RS};
            bins csrrc  = {CSR_OP_RC};

            bins csrrwi = {CSR_OP_RWI};
            bins csrrsi = {CSR_OP_RSI};
            bins csrrci = {CSR_OP_RCI};
        }


        //--------------------------------------------------------------
        // CSR write
        //--------------------------------------------------------------

        cp_csr_we : coverpoint csr_we {

            bins read  = {1'b0};
            bins write = {1'b1};
        }


        //--------------------------------------------------------------
        // MSTATUS.MIE
        //--------------------------------------------------------------

        cp_mstatus_mie : coverpoint mie_global {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MSTATUS.MPIE
        //--------------------------------------------------------------

        cp_mstatus_mpie : coverpoint mpie {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MIE.MSIE
        //--------------------------------------------------------------

        cp_mie_msie : coverpoint mie[3] {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MIE.MTIE
        //--------------------------------------------------------------

        cp_mie_mtie : coverpoint mie[7] {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MIE.MEIE
        //--------------------------------------------------------------

        cp_mie_meie : coverpoint mie[11] {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MIP.MSIP
        //--------------------------------------------------------------

        cp_mip_msip : coverpoint mip[3] {

            bins not_pending = {1'b0};
            bins pending     = {1'b1};
        }


        //--------------------------------------------------------------
        // MIP.MTIP
        //--------------------------------------------------------------

        cp_mip_mtip : coverpoint mip[7] {

            bins not_pending = {1'b0};
            bins pending     = {1'b1};
        }


        //--------------------------------------------------------------
        // MIP.MEIP
        //--------------------------------------------------------------

        cp_mip_meip : coverpoint mip[11] {

            bins not_pending = {1'b0};
            bins pending     = {1'b1};
        }


        //--------------------------------------------------------------
        // MTVEC mode
        //
        // Your RTL supports direct and vectored modes.
        //--------------------------------------------------------------

        cp_mtvec_mode : coverpoint mtvec_mode {

            bins mtvec_direct   = {2'b00};
            bins mtvec_vectored = {2'b01};
        }


        //--------------------------------------------------------------
        // CSR write data patterns
        //--------------------------------------------------------------

        cp_csr_wdata : coverpoint csr_wdata {

            bins zero = {32'h00000000};
            bins ones = {32'hFFFFFFFF};

            bins nonzero = default;
        }


        //--------------------------------------------------------------
        // CSR address × operation
        //--------------------------------------------------------------

        cross_csr_operation :
    cross cp_csr_addr, cp_csr_op {

    // Read-only CSRs cannot be written using CSRRW
    ignore_bins readonly_csrrw =
        binsof(cp_csr_addr) intersect {
            CSR_CYCLE,
            CSR_INSTRET,
            CSR_CYCLEH,
            CSR_INSTRETH,
            CSR_MVENDORID,
            CSR_MARCHID,
            CSR_MIMPID,
            CSR_MHARTID
        }
        &&
        binsof(cp_csr_op) intersect {CSR_OP_RW};

    // Read-only CSRs cannot be written using CSRRWI
    ignore_bins readonly_csrrwi =
        binsof(cp_csr_addr) intersect {
            CSR_CYCLE,
            CSR_INSTRET,
            CSR_CYCLEH,
            CSR_INSTRETH,
            CSR_MVENDORID,
            CSR_MARCHID,
            CSR_MIMPID,
            CSR_MHARTID
        }
        &&
        binsof(cp_csr_op) intersect {CSR_OP_RWI};
}

        //--------------------------------------------------------------
        // CSR address × write/read
        //--------------------------------------------------------------

        cross_csr_access :
    cross cp_csr_addr, cp_csr_we {

    // Read-only CSRs cannot be written
    ignore_bins readonly_write =
        binsof(cp_csr_addr) intersect {
            CSR_CYCLE,
            CSR_INSTRET,
            CSR_CYCLEH,
            CSR_INSTRETH,
            CSR_MVENDORID,
            CSR_MARCHID,
            CSR_MIMPID,
            CSR_MHARTID
        }
        &&
        binsof(cp_csr_we) intersect {1'b1};
}


        //--------------------------------------------------------------
        // MIE enable combinations
        //--------------------------------------------------------------

        cross_mie_enable :
            cross cp_mie_msie,
                  cp_mie_mtie,
                  cp_mie_meie;


        //--------------------------------------------------------------
        // MIP combinations
        //--------------------------------------------------------------

        cross_mip_pending :
            cross cp_mip_msip,
                  cp_mip_mtip,
                  cp_mip_meip;

    endgroup



    //======================================================================
    // COVERGROUP 2
    // EXCEPTION COVERAGE
    //======================================================================

    covergroup cg_exception;

        option.per_instance = 1;
        option.name = "PRAGYA_EXCEPTION_COVERAGE";


        //--------------------------------------------------------------
        // Exception cause
        //--------------------------------------------------------------

        cp_exception_cause : coverpoint cause
            iff (trap_taken && !is_interrupt) {

            bins instruction_misaligned =
                {CAUSE_INSTR_MISALIGNED};

            bins illegal_instruction =
                {CAUSE_ILLEGAL_INSTR};

            bins breakpoint =
                {CAUSE_BREAKPOINT};

            bins ecall_machine =
                {CAUSE_ECALL_M};
        }


        //--------------------------------------------------------------
        // Exception / interrupt
        //--------------------------------------------------------------

        cp_trap_type : coverpoint interrupt_flag
              iff (trap_taken && !is_interrupt) {

              bins exception = {1'b0};
         }


        //--------------------------------------------------------------
        // ECALL
        //--------------------------------------------------------------

        cp_ecall : coverpoint ecall {

            bins executed     = {1'b1};
        }


        //--------------------------------------------------------------
        // EBREAK
        //--------------------------------------------------------------

        cp_ebreak : coverpoint ebreak {
           
            bins executed     = {1'b1};
        }


        //--------------------------------------------------------------
        // MRET
        //--------------------------------------------------------------

        cp_mret : coverpoint mret {

            bins executed     = {1'b1};
        }


        //--------------------------------------------------------------
        // Global MIE when exception occurs
        //--------------------------------------------------------------

        cp_exception_mie : coverpoint mie_global
            iff (trap_taken && !is_interrupt) {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MPIE state
        //--------------------------------------------------------------

        cp_exception_mpie : coverpoint mpie
            iff (trap_taken && !is_interrupt) {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // MEPC alignment
        //
        // Your CSR explicitly forces MEPC[1:0] = 00 on trap.
        //--------------------------------------------------------------

        cp_mepc_alignment : coverpoint mepc[1:0]
            iff (trap_taken) {

            bins aligned = {2'b00};
        }


        //--------------------------------------------------------------
        // MTVAL
        //--------------------------------------------------------------

        cp_mtval : coverpoint (mtval == 32'h00000000) {

            bins zero     = {1'b1};
            bins nonzero  = {1'b0};
        }


        //--------------------------------------------------------------
        // Exception cause × MIE
        //--------------------------------------------------------------

        cross_exception_mie :
            cross cp_exception_cause,
                  cp_exception_mie;


        

    endgroup



    //======================================================================
    // COVERGROUP 3
    // INTERRUPT COVERAGE
    //======================================================================

    covergroup cg_interrupt;

        option.per_instance = 1;
        option.name = "PRAGYA_INTERRUPT_COVERAGE";


        //--------------------------------------------------------------
        // Interrupt cause
        //--------------------------------------------------------------

        cp_interrupt_cause : coverpoint cause
            iff (trap_taken && is_interrupt) {

            bins software = {CAUSE_IRQ_SOFTWARE};
            bins timer    = {CAUSE_IRQ_TIMER};
            bins external = {CAUSE_IRQ_EXTERNAL};
        }

//--------------------------------------------------------------
// Interrupt request type
//
// This represents the IRQ source itself, whether or not
// the interrupt was actually taken.
//--------------------------------------------------------------


        //--------------------------------------------------------------
        // Software IRQ input
        //--------------------------------------------------------------

        cp_irq_software : coverpoint irq_software {

            bins inactive = {1'b0};
            bins active   = {1'b1};
        }


        //--------------------------------------------------------------
        // Timer IRQ input
        //--------------------------------------------------------------

        cp_irq_timer : coverpoint irq_timer {

            bins inactive = {1'b0};
            bins active   = {1'b1};
        }


        //--------------------------------------------------------------
        // External IRQ input
        //--------------------------------------------------------------

        cp_irq_external : coverpoint irq_external {

            bins inactive = {1'b0};
            bins active   = {1'b1};
        }


        //--------------------------------------------------------------
        // Global interrupt enable
        //--------------------------------------------------------------

        cp_global_mie : coverpoint mie_global {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // Individual interrupt enables
        //--------------------------------------------------------------

        cp_msie : coverpoint mie[3] {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        cp_mtie : coverpoint mie[7] {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        cp_meie : coverpoint mie[11] {

            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }


        //--------------------------------------------------------------
        // Pending bits
        //--------------------------------------------------------------

        cp_msip : coverpoint mip[3] {

            bins not_pending = {1'b0};
            bins pending     = {1'b1};
        }


        cp_mtip : coverpoint mip[7] {

            bins not_pending = {1'b0};
            bins pending     = {1'b1};
        }


        cp_meip : coverpoint mip[11] {

            bins not_pending = {1'b0};
            bins pending     = {1'b1};
        }
        
        //--------------------------------------------------------------
// Effective MIP combination
//
// {MEIP, MTIP, MSIP}
//--------------------------------------------------------------

cp_mip_combination : coverpoint {
    mip[11],
    mip[7],
    mip[3]
} {

    bins none            = {3'b000};
    bins external        = {3'b001};
    bins timer           = {3'b010};
    bins timer_external  = {3'b011};
    bins software        = {3'b100};
    bins software_ext    = {3'b101};
    bins software_timer  = {3'b110};
    bins all             = {3'b111};
}

        //--------------------------------------------------------------
        // IRQ source combination
        //--------------------------------------------------------------

        cp_irq_combination :
    coverpoint {irq_software,
                irq_timer,
                irq_external} {

    bins none        = {3'b000};

    bins software    = {3'b100};
    bins timer       = {3'b010};
    bins external    = {3'b001};

    bins sw_timer    = {3'b110};
    bins sw_external = {3'b101};
    bins timer_ext   = {3'b011};

    bins all         = {3'b111};
}

        //--------------------------------------------------------------
        // MTVEC mode
        //--------------------------------------------------------------

        cp_mtvec_mode : coverpoint mtvec_mode {

            bins mtvec_direct   = {2'b00};
            bins mtvec_vectored = {2'b01};
        }


        //--------------------------------------------------------------
        // Interrupt × global enable
        //--------------------------------------------------------------

        cross_irq_request_global :
            cross cp_irq_combination,
                  cp_global_mie;


        //--------------------------------------------------------------
        // Software interrupt enable
        //--------------------------------------------------------------

        cross_sw_enable :
            cross cp_irq_software,
                  cp_msie,
                  cp_global_mie;


        //--------------------------------------------------------------
        // Timer interrupt enable
        //--------------------------------------------------------------

        cross_timer_enable :
            cross cp_irq_timer,
                  cp_mtie,
                  cp_global_mie;


        //--------------------------------------------------------------
        // External interrupt enable
        //--------------------------------------------------------------

        cross_external_enable :
            cross cp_irq_external,
                  cp_meie,
                  cp_global_mie;


        //--------------------------------------------------------------
        // IRQ type × MTVEC mode
        //--------------------------------------------------------------

        cross_irq_mtvec :
            cross cp_interrupt_cause,
                  cp_mtvec_mode;

    endgroup



    //======================================================================
    // CONSTRUCTOR
    //======================================================================

    function new();

        cg_csr       = new();
        cg_exception = new();
        cg_interrupt = new();

    endfunction



    //======================================================================
    // CSR SAMPLE
    //======================================================================

    function void sample_csr(

        input logic        valid,
        input logic [11:0] addr,
        input logic [2:0]  op,
        input logic        we,
        input logic [31:0] wdata,
        input logic [31:0] rdata,

        input logic [31:0] sample_mstatus,
        input logic [31:0] sample_mie,
        input logic [31:0] sample_mtvec,
        input logic [31:0] sample_mepc,
        input logic [31:0] sample_mcause,
        input logic [31:0] sample_mtval,
        input logic [31:0] sample_mscratch,
        input logic [31:0] sample_mip,

        input logic [63:0] sample_mcycle,
        input logic [63:0] sample_minstret,

        input logic        sample_mie_global,
        input logic        sample_mpie,

        input logic [1:0]  sample_mtvec_mode
    );

        csr_valid = valid;
        csr_addr  = addr;
        csr_op    = op;
        csr_we    = we;

        csr_wdata = wdata;
        csr_rdata = rdata;

        mstatus = sample_mstatus;
        mie     = sample_mie;
        mtvec   = sample_mtvec;
        mepc    = sample_mepc;
        mcause  = sample_mcause;
        mtval   = sample_mtval;
        mscratch= sample_mscratch;
        mip     = sample_mip;

        mcycle   = sample_mcycle;
        minstret = sample_minstret;

        mie_global = sample_mie_global;
        mpie       = sample_mpie;

        mtvec_mode = sample_mtvec_mode;

        if (valid)
            cg_csr.sample();

    endfunction


    //======================================================================
    // MIP PENDING SAMPLE FOR CSR COVERAGE
    //
    // This is coverage-model sampling only.
    //
    // It allows the CSR coverage model to observe all possible
    // MIP pending-bit states:
    //
    //        MSIP MTIP MEIP
    //         0    0    0
    //         0    0    1
    //         0    1    0
    //         0    1    1
    //         1    0    0
    //         1    0    1
    //         1    1    0
    //         1    1    1
    //
    // No RTL signal/register is modified by this function.
    //======================================================================

    function void sample_mip_pending(

        input logic sample_msip,
        input logic sample_mtip,
        input logic sample_meip

    );

        // This is a MIP CSR observation
        csr_valid = 1'b1;

        // MIP CSR address
        csr_addr = CSR_MIP;

        // Representative CSR operation
        csr_op = CSR_OP_RW;

        // CSR access
        csr_we = 1'b1;

        // Construct MIP value
        //
        // MIP:
        // MSIP = bit 3
        // MTIP = bit 7
        // MEIP = bit 11
        //
        csr_wdata = 32'h00000000;

        csr_wdata[3]  = sample_msip;
        csr_wdata[7]  = sample_mtip;
        csr_wdata[11] = sample_meip;

        csr_rdata = csr_wdata;

        // Update coverage-model MIP value
        mip = csr_wdata;

        // Other CSR values are irrelevant for this sample
        mstatus  = 32'h00000000;
        mie      = 32'h00000000;
        mtvec    = 32'h00000000;
        mepc     = 32'h00000000;
        mcause   = 32'h00000000;
        mtval    = 32'h00000000;
        mscratch = 32'h00000000;

        mcycle   = 64'h0000000000000000;
        minstret = 64'h0000000000000000;

        mie_global = 1'b0;
        mpie       = 1'b0;

        mtvec_mode = 2'b00;

        // Sample CSR coverage
        cg_csr.sample();

    endfunction

    //======================================================================
    // EXCEPTION SAMPLE
    //======================================================================

    function void sample_exception(

        input logic        taken,
        input logic [3:0]  sample_cause,
        input logic        sample_interrupt_flag,

        input logic [31:0] sample_mepc,
        input logic [31:0] sample_mtval,

        input logic        sample_mie_global,
        input logic        sample_mpie,

        input logic        sample_ecall,
        input logic        sample_ebreak,
        input logic        sample_mret
    );

        trap_taken = taken;

        cause = sample_cause;

        interrupt_flag = sample_interrupt_flag;

        is_interrupt = sample_interrupt_flag;
        is_exception = !sample_interrupt_flag;

        mepc = sample_mepc;
        mtval = sample_mtval;

        mie_global = sample_mie_global;
        mpie = sample_mpie;

        ecall  = sample_ecall;
        ebreak = sample_ebreak;
        mret   = sample_mret;

        if (taken)
            cg_exception.sample();

    endfunction



    //======================================================================
    // INTERRUPT SAMPLE
    //======================================================================

    function void sample_interrupt(

        input logic        taken,

        input logic [3:0]  sample_cause,

        input logic        sample_irq_software,
        input logic        sample_irq_timer,
        input logic        sample_irq_external,

        input logic [31:0] sample_mie,
        input logic [31:0] sample_mip,

        input logic        sample_mie_global,

        input logic [1:0]  sample_mtvec_mode
    );

        trap_taken = taken;

        cause = sample_cause;

        interrupt_flag = 1'b1;
        is_interrupt = 1'b1;
        is_exception = 1'b0;

        irq_software = sample_irq_software;
        irq_timer    = sample_irq_timer;
        irq_external = sample_irq_external;

        mie = sample_mie;
        mip = sample_mip;
        mip[3]  = sample_mip[3]  | sample_irq_software;
	mip[7]  = sample_mip[7]  | sample_irq_timer;
	mip[11] = sample_mip[11] | sample_irq_external;

        mie_global = sample_mie_global;

        mtvec_mode = sample_mtvec_mode;

        
        cg_interrupt.sample();

    endfunction

//======================================================================
// SYSTEM INSTRUCTION SAMPLE
//======================================================================

function void sample_system_instruction(
    input logic sample_ecall,
    input logic sample_ebreak,
    input logic sample_mret
);

    ecall  = sample_ecall;
    ebreak = sample_ebreak;
    mret   = sample_mret;

    cg_exception.sample();

endfunction

    //======================================================================
    // REPORT
    //======================================================================

    function void report();

        $display("");
        $display("==================================================");
        $display("          PRAGYA SYSTEM COVERAGE");
        $display("==================================================");

        $display("CSR Coverage        = %0.2f %% ",
                 cg_csr.get_coverage());

        $display("Exception Coverage  = %0.2f %% ",
                 cg_exception.get_coverage());

        $display("Interrupt Coverage  = %0.2f %% ",
                 cg_interrupt.get_coverage());

        $display("--------------------------------------------------");

        $display("TOTAL SYSTEM COVERAGE = %0.2f %%",
                 (cg_csr.get_coverage() +
                  cg_exception.get_coverage() +
                  cg_interrupt.get_coverage()) / 3.0);

        $display("==================================================");
        $display("");

    endfunction

endclass
