`timescale 1ns/1ps

class load_store_coverage;

    //==========================================================
    // Signals
    //==========================================================

   // logic        mem_req;
    logic        mem_write;
    logic [2:0]  funct3;
    logic [31:0] address;
    logic [31:0] write_data;

    //==========================================================
    // Covergroup
    //==========================================================

    covergroup cg_load_store;

        option.per_instance = 1;
        option.name = "LOAD_STORE_COVERAGE";

        

        //------------------------------------------------------
        // Load / Store
        //------------------------------------------------------

        cp_write : coverpoint mem_write
        {
            bins load_access  = {1'b0};
            bins store_access = {1'b1};
        }

        //------------------------------------------------------
        // Access Size
        //------------------------------------------------------

        cp_size : coverpoint funct3
        {
            bins lb_access  = {3'b000};
            bins lh_access  = {3'b001};
            bins lw_access  = {3'b010};
            bins lbu_access = {3'b100};
            bins lhu_access = {3'b101};
        }

        //------------------------------------------------------
        // Address Alignment
        //------------------------------------------------------

        cp_align : coverpoint address[1:0]
        {
            bins align0 = {2'b00};
            bins align1 = {2'b01};
            bins align2 = {2'b10};
            bins align3 = {2'b11};
        }

        //------------------------------------------------------
        // Cross Coverage
        //------------------------------------------------------

        cross_write_size : cross cp_write, cp_size
{
    ignore_bins invalid_store_lbu =
        binsof(cp_write.store_access) &&
        binsof(cp_size.lbu_access);

    ignore_bins invalid_store_lhu =
        binsof(cp_write.store_access) &&
        binsof(cp_size.lhu_access);
}
        cross_write_addr : cross cp_write, cp_align;

    endgroup

    //==========================================================
    // Constructor
    //==========================================================

    function new();
        cg_load_store = new();
    endfunction

    //==========================================================
    // Sample Function
    //==========================================================

    function void sample(

        logic        req,
        logic        wr,
        logic [2:0]  f3,
        logic [31:0] addr,
        logic [31:0] data

    );

       // mem_req    = req;
        mem_write  = wr;
        funct3     = f3;
        address    = addr;
        write_data = data;

        cg_load_store.sample();

    endfunction

    //==========================================================
    // Report
    //==========================================================

    function void report();

        $display("");
        $display("========================================");
        $display("      LOAD / STORE COVERAGE");
        $display("========================================");
        $display("Coverage = %0.2f %%", cg_load_store.get_coverage());
        $display("========================================");
        $display("");

    endfunction

endclass
