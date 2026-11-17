`timescale 1ns / 1ps
`include "axi/typedef.svh"
`include "axi/assign.svh"

module soc_top (
    // ========================================================
    // Physical FPGA Pins
    // ========================================================
    // System Clock & Reset
    input  logic        clk_i,
    input  logic        rst_ni,

    // UART
    input  logic        uart_rx,
    output logic        uart_tx,

    // I2C
    inout  wire         i2c_scl,
    inout  wire         i2c_sda,

    // QSPI (Quad SPI with 4 Chip Selects)
    output logic        qspi_clk,
    output logic [3:0]  qspi_csn, 
    inout  wire  [3:0]  qspi_io,  

    // GPIO
    inout  wire [31:0]  gpio,

    // ========================================================
    // EXTERNAL JTAG PINS (Added for Firmware Loader)
    // ========================================================
    input  logic        jtag_tck_i,
    input  logic        jtag_tms_i,
    input  logic        jtag_tdi_i,
    input  logic        jtag_trst_ni,
    output logic        jtag_tdo_o
);

    // ========================================================
    // 1. Internal Wires & Tristate IO Buffers
    // ========================================================
    
    // --- I2C Wires & Buffers ---
    wire i2c_scl_i, i2c_scl_o, i2c_scl_oen;
    wire i2c_sda_i, i2c_sda_o, i2c_sda_oen;

    assign i2c_scl   = (~i2c_scl_oen) ? i2c_scl_o : 1'bz;
    assign i2c_scl_i = i2c_scl;

    assign i2c_sda   = (~i2c_sda_oen) ? i2c_sda_o : 1'bz;
    assign i2c_sda_i = i2c_sda;

    // --- GPIO Wires & Buffers ---
    wire [31:0] gpio_in, gpio_out, gpio_dir;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : gen_gpio_iobuf
            assign gpio[i] = gpio_dir[i] ? gpio_out[i] : 1'bz;
        end
    endgenerate
    assign gpio_in = gpio;

    // --- QSPI Wires & Buffers ---
    wire [1:0] spi_mode;
    wire [3:0] spi_sdo;
    wire [3:0] spi_sdi;
// Quad RX: release all four data lines.
// Quad TX: master drives all four data lines.
// Standard mode: master drives IO0.

assign qspi_io[0] =
    (spi_mode == 2'b10) ? 1'bz : spi_sdo[0];

assign qspi_io[1] =
    (spi_mode == 2'b01) ? spi_sdo[1] : 1'bz;

assign qspi_io[2] =
    (spi_mode == 2'b01) ? spi_sdo[2] : 1'bz;

assign qspi_io[3] =
    (spi_mode == 2'b01) ? spi_sdo[3] : 1'bz;
  
    assign spi_sdi[0] = qspi_io[0];
    assign spi_sdi[1] = qspi_io[1];
    assign spi_sdi[2] = qspi_io[2];
    assign spi_sdi[3] = qspi_io[3];


    // ========================================================
    // 2. AXI-Lite Bus Interconnect
    // ========================================================
    AXI_LITE #(
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(32)
    ) axi_lite_bus ();


    // ========================================================
    // 3. Interrupt Routing (PLIC)
    // ========================================================
    wire        uart_event;
    wire        i2c_interrupt;
    wire        gpio_interrupt;
    wire [3:0]  timer_irq;
    wire [1:0]  spi_events;
    wire [3:0]  plic_irq;
    wire [63:0] plic_interrupt_sources;
    


    assign plic_interrupt_sources[0]    = 1'b0;             
    assign plic_interrupt_sources[1]    = uart_event;        
    assign plic_interrupt_sources[2]    = i2c_interrupt;     
    assign plic_interrupt_sources[3]    = gpio_interrupt;    
    assign plic_interrupt_sources[7:4]  = timer_irq;         
    assign plic_interrupt_sources[9:8]  = spi_events;        
    
   
    assign plic_interrupt_sources[63:10] = '0;           


    // ========================================================
    // 4. Core Subsystem (RISC-V + Memory + AXI Bridge)
    // ========================================================
    axi_bus i_axi_bus (
        .pg_riscv32_mp_clk_in ( clk_i ),
        .pg_riscv32_mp_rst_in ( rst_ni ),
        
        // AXI4 Master Interface mapped directly to the AXI_LITE interface
        .axi_awaddr           ( axi_lite_bus.aw_addr  ),
       // .axi_awprot           ( axi_lite_bus.aw_prot  ),
        .axi_awvalid          ( axi_lite_bus.aw_valid ),
        .axi_awready          ( axi_lite_bus.aw_ready ),
        
        .axi_wdata            ( axi_lite_bus.w_data   ),
        .axi_wstrb            ( axi_lite_bus.w_strb   ),
        .axi_wvalid           ( axi_lite_bus.w_valid  ),
        .axi_wready           ( axi_lite_bus.w_ready  ),
        
       // .axi_bresp            ( axi_lite_bus.b_resp   ),
        .axi_bvalid           ( axi_lite_bus.b_valid  ),
        .axi_bready           ( axi_lite_bus.b_ready  ),
        
        .axi_araddr           ( axi_lite_bus.ar_addr  ),
       
        .axi_arvalid          ( axi_lite_bus.ar_valid ),
        .axi_arready          ( axi_lite_bus.ar_ready ),
        
        .axi_rdata            ( axi_lite_bus.r_data   ),
       // .axi_rresp            ( axi_lite_bus.r_resp   ),
        .axi_rvalid           ( axi_lite_bus.r_valid  ),
        .axi_rready           ( axi_lite_bus.r_ready  ),

        // Route the Target 0 Interrupt from the RISC-V core
        .ext_irq_in           ( plic_irq[0] ),

        // External JTAG Connections
        .jtag_tck_i           ( jtag_tck_i ),
        .jtag_tms_i           ( jtag_tms_i ),
        .jtag_tdi_i           ( jtag_tdi_i ),
        .jtag_trst_ni         ( jtag_trst_ni ),
        .jtag_tdo_o           ( jtag_tdo_o )
    );


    // ========================================================
    // 5. Peripheral Subsystem (APB Bridge + Peripherals)
    // ========================================================
    peripherals_top #(
        .AddrWidth   ( 32 ),
        .DataWidth   ( 32 ),
        .GpioPadNum  ( 32 )
    ) i_peripheral_top (
        .clk_i             ( clk_i ),
        .rst_ni            ( rst_ni ),
        .dft_cg_enable_i   ( 1'b0 ),
        
        .axi_lite_slv      ( axi_lite_bus ),
        
        .uart_rx_i         ( uart_rx ),
        .uart_tx_o         ( uart_tx ),
        .uart_event_o      ( uart_event ),
        
        .i2c_scl_pad_i     ( i2c_scl_i ),
        .i2c_scl_pad_o     ( i2c_scl_o ),
        .i2c_scl_padoen_o  ( i2c_scl_oen ),
        .i2c_sda_pad_i     ( i2c_sda_i ),
        .i2c_sda_pad_o     ( i2c_sda_o ),
        .i2c_sda_padoen_o  ( i2c_sda_oen ),
        .i2c_interrupt_o   ( i2c_interrupt ),
        
        .spi_events_o      ( spi_events ),
        .spi_clk_o         ( qspi_clk ),
        .spi_csn0_o        ( qspi_csn[0] ),
        .spi_csn1_o        ( qspi_csn[1] ),
        .spi_csn2_o        ( qspi_csn[2] ),
        .spi_csn3_o        ( qspi_csn[3] ),
        .spi_mode_o        ( spi_mode ),    
        .spi_sdo0_o        ( spi_sdo[0] ),  
        .spi_sdo1_o        ( spi_sdo[1] ),  
        .spi_sdo2_o        ( spi_sdo[2] ),  
        .spi_sdo3_o        ( spi_sdo[3] ),  
        .spi_sdi0_i        ( spi_sdi[0] ),  
        .spi_sdi1_i        ( spi_sdi[1] ),  
        .spi_sdi2_i        ( spi_sdi[2] ),  
        .spi_sdi3_i        ( spi_sdi[3] ),  
        
        .gpio_in_i         ( gpio_in ),
        .gpio_in_sync_o    ( ),
        .gpio_out_o        ( gpio_out ),
        .gpio_dir_o        ( gpio_dir ),
        .gpio_padcfg_o     ( ),
        .gpio_interrupt_o  ( gpio_interrupt ),
        
        .timer_irq_o       ( timer_irq ),
        .plic_src_i        ( plic_interrupt_sources ),
        .plic_irq_o        ( plic_irq )
    );
// ========================================================
// INTERRUPT DEBUG MONITOR
// ========================================================
always @(posedge clk_i) begin
    if (rst_ni) begin

        // Timer interrupt outputs
        if (|timer_irq)
            $display(
                "[SOC] TIMER IRQ HIGH: timer_irq=%b time=%0t",
                timer_irq, $time
            );

        // Timer interrupts reaching PLIC sources
        if (|plic_interrupt_sources[7:4])
            $display(
                "[SOC] TIMER PLIC SOURCES HIGH: sources[7:4]=%b time=%0t",
                plic_interrupt_sources[7:4], $time
            );

        // PLIC interrupt output connected to CPU
        if (plic_irq[0])
            $display(
                "[SOC] PLIC TARGET 0 HIGH at %0t",
                $time
            );

    end
end
endmodule
