class pipeline_coverage;

    //------------------------------------------------------------
    // Signals
    //------------------------------------------------------------

    logic stall;
    logic flush;

    logic forward_a;
    logic forward_b;

    logic mem_operation;
    logic mem_stall;

    logic reg_write;

    //------------------------------------------------------------
    // Covergroup
    //------------------------------------------------------------

    covergroup cg_pipeline;

        option.per_instance = 1;
        option.name = "PIPELINE_COVERAGE";

        //--------------------------------------------------------
        // Pipeline Stall
        //--------------------------------------------------------

        cp_stall : coverpoint stall
        {
            bins no_stall = {0};
            bins stall    = {1};
        }

        //--------------------------------------------------------
        // Pipeline Flush
        //--------------------------------------------------------

        cp_flush : coverpoint flush
        {
            bins no_flush = {0};
            bins flush    = {1};
        }

        //--------------------------------------------------------
        // Forward A
        //--------------------------------------------------------

        cp_forward_a : coverpoint forward_a
        {
            bins no_forward = {0};
            bins forward    = {1};
        }

        //--------------------------------------------------------
        // Forward B
        //--------------------------------------------------------

        cp_forward_b : coverpoint forward_b
        {
            bins no_forward = {0};
            bins forward    = {1};
        }

        //--------------------------------------------------------
        // Memory Operation
        //--------------------------------------------------------

        cp_mem_operation : coverpoint mem_operation
        {
            bins no_mem_op = {0};
            bins mem_op    = {1};
        }

        //--------------------------------------------------------
        // Memory Stall
        //--------------------------------------------------------

        cp_mem_stall : coverpoint mem_stall
        {
            bins no_stall = {0};
            bins stall    = {1};
        }

        //--------------------------------------------------------
        // Register Write
        //--------------------------------------------------------

        cp_reg_write : coverpoint reg_write
        {
            bins no_write = {0};
            bins write    = {1};
        }

        //--------------------------------------------------------
        // Cross Coverage
        //--------------------------------------------------------

        cross_forward :
            cross cp_forward_a, cp_forward_b;

        cross_stall_mem :
            cross cp_stall, cp_mem_operation
            {
        ignore_bins impossible_no_stall_mem =
            binsof(cp_stall) intersect {0} &&
            binsof(cp_mem_operation) intersect {1};
    }

        cross_flush_stall :
            cross cp_flush, cp_stall;

        cross_memstall_memop :
    cross cp_mem_stall, cp_mem_operation
    {
        ignore_bins impossible_no_memstall_mem =
            binsof(cp_mem_stall) intersect {0} &&
            binsof(cp_mem_operation) intersect {1};
    }

        cross_forward_stall :
            cross cp_forward_a, cp_forward_b, cp_stall;

    endgroup

    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------

    function new();

        cg_pipeline = new();

    endfunction

    //------------------------------------------------------------
    // Sample
    //------------------------------------------------------------

    function void sample(

        input logic sample_stall,
        input logic sample_flush,
        input logic sample_forward_a,
        input logic sample_forward_b,
        input logic sample_mem_operation,
        input logic sample_mem_stall,
        input logic sample_reg_write

    );

        stall          = sample_stall;
        flush          = sample_flush;
        forward_a      = sample_forward_a;
        forward_b      = sample_forward_b;
        mem_operation  = sample_mem_operation;
        mem_stall      = sample_mem_stall;
        reg_write      = sample_reg_write;

        cg_pipeline.sample();

    endfunction

    //------------------------------------------------------------
    // Report
    //------------------------------------------------------------

    function void report();

        $display("");
        $display("===================================");
        $display(" PIPELINE COVERAGE REPORT");
        $display("===================================");
        $display("Coverage = %0.2f %%", cg_pipeline.get_coverage());
        $display("===================================");
        $display("");

    endfunction

endclass
