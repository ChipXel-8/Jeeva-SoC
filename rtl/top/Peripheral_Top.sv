`include "axi/typedef.svh"
`include "axi/assign.svh"

module peripherals_top #(
    parameter int unsigned AddrWidth = 32'd32,
    parameter int unsigned DataWidth = 32'd32,
    parameter int unsigned NoApbSlaves = 32'd6, // Now 6: UART, I2C, SPI, GPIO, Timer, PLIC
    parameter int unsigned NoRules = 32'd6,     // 6Address Rules
    parameter type rule_t = axi_pkg::xbar_rule_32_t, // From common_cells / axi_pkg
    
    // GPIO specific parameters
    parameter int unsigned GpioPadNum = 32,
    parameter int unsigned GpioPadCfgBits = 4,
    
    // Timer specific parameters
    parameter int unsigned TimerCnt = 2,

    // PLIC specific parameters
    parameter int unsigned PlicSources = 64,
    parameter int unsigned PlicTargets = 4
)(
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // DFT signal for GPIO clock gating
    input  logic        dft_cg_enable_i,

    AXI_LITE.Slave      axi_lite_slv,

 
    // UART (Slave 0)
    input  logic        uart_rx_i,
    output logic        uart_tx_o,
    output logic        uart_event_o,

    // I2C (Slave 1)
    input  logic        i2c_scl_pad_i,
    output logic        i2c_scl_pad_o,
    output logic        i2c_scl_padoen_o,
    input  logic        i2c_sda_pad_i,
    output logic        i2c_sda_pad_o,
    output logic        i2c_sda_padoen_o,
    output logic        i2c_interrupt_o,

    // SPI (Slave 2)
    output logic [1:0]  spi_events_o,
    output logic        spi_clk_o,
    output logic        spi_csn0_o,
    output logic        spi_csn1_o,
    output logic        spi_csn2_o,
    output logic        spi_csn3_o,
    output logic [1:0]  spi_mode_o,
    output logic        spi_sdo0_o,
    output logic        spi_sdo1_o,
    output logic        spi_sdo2_o,
    output logic        spi_sdo3_o,
    input  logic        spi_sdi0_i,
    input  logic        spi_sdi1_i,
    input  logic        spi_sdi2_i,
    input  logic        spi_sdi3_i,

    // GPIO (Slave 3)
    input  logic [GpioPadNum-1:0]                    gpio_in_i,
    output logic [GpioPadNum-1:0]                    gpio_in_sync_o,
    output logic [GpioPadNum-1:0]                    gpio_out_o,
    output logic [GpioPadNum-1:0]                    gpio_dir_o,
    output logic [GpioPadNum-1:0][GpioPadCfgBits-1:0] gpio_padcfg_o,
    output logic                                     gpio_interrupt_o,

    // Timer (Slave 4)
    output logic [(TimerCnt * 2) - 1:0]              timer_irq_o,

    // PLIC (Slave 5)
    input  logic [PlicSources-1:0]                   plic_src_i,
    output logic [PlicTargets-1:0]                   plic_irq_o
);

   localparam rule_t [NoRules-1:0] AddrMap = '{
     
        // PLIC (Index 5)
        '{idx: 32'd5, start_addr: 32'h4000_5000, end_addr: 32'h4000_6000},
        // Timer (Index 4)
        '{idx: 32'd4, start_addr: 32'h4000_4000, end_addr: 32'h4000_5000},
        // GPIO (Index 3)
        '{idx: 32'd3, start_addr: 32'h4000_3000, end_addr: 32'h4000_4000},
        // SPI (Index 2)
        '{idx: 32'd2, start_addr: 32'h4000_2000, end_addr: 32'h4000_3000},
        // I2C (Index 1)
        '{idx: 32'd1, start_addr: 32'h4000_1000, end_addr: 32'h4000_2000},
        // UART (Index 0)
        '{idx: 32'd0, start_addr: 32'h4000_0000, end_addr: 32'h4000_1000}
    };

    // ---------------------------------------------------------
    // Internal APB Signals
    // ---------------------------------------------------------
    logic [AddrWidth-1:0]                  apb_paddr;
    logic [2:0]                            apb_pprot;
    logic [NoApbSlaves-1:0]                apb_pselx;
    logic                                  apb_penable;
    logic                                  apb_pwrite;
    logic [DataWidth-1:0]                  apb_pwdata;
    logic [(DataWidth/8)-1:0]              apb_pstrb;

    // Response signals from Slaves to Bridge
    logic [NoApbSlaves-1:0]                apb_pready;
    logic [NoApbSlaves-1:0][DataWidth-1:0] apb_prdata; 
    logic [NoApbSlaves-1:0]                apb_pslverr;

    // ---------------------------------------------------------
    // AXI4-Lite to APB4 Bridge
    // ---------------------------------------------------------
    axi_lite_to_apb_intf #(
        .NoApbSlaves      (NoApbSlaves),
        .NoRules          (NoRules),
        .AddrWidth        (AddrWidth),
        .DataWidth        (DataWidth),
        .PipelineRequest  (1'b0),
        .PipelineResponse (1'b0),
        .rule_t           (rule_t)
    ) i_axi_lite_to_apb (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .slv        (axi_lite_slv),
        
        // APB Master Output
        .paddr_o    (apb_paddr),
        .pprot_o    (apb_pprot),
        .pselx_o    (apb_pselx),
        .penable_o  (apb_penable),
        .pwrite_o   (apb_pwrite),
        .pwdata_o   (apb_pwdata),
        .pstrb_o    (apb_pstrb),
        
        // APB Slave Inputs
        .pready_i   (apb_pready),
        .prdata_i   (apb_prdata),
        .pslverr_i  (apb_pslverr),
        
        .addr_map_i (AddrMap)
    );

    // ---------------------------------------------------------
    // APB Slave 0: UART
    // ---------------------------------------------------------
    apb_uart_sv #(
        .APB_ADDR_WIDTH (12)
    ) i_apb_uart (
        .CLK        (clk_i),
        .RSTN       (rst_ni),
        .PADDR      (apb_paddr[11:0]),
        .PWDATA     (apb_pwdata),
        .PWRITE     (apb_pwrite),
        .PSEL       (apb_pselx[0]),
        .PENABLE    (apb_penable),
        .PRDATA     (apb_prdata[0]),
        .PREADY     (apb_pready[0]),
        .PSLVERR    (apb_pslverr[0]),
        .rx_i       (uart_rx_i),
        .tx_o       (uart_tx_o),
        .event_o    (uart_event_o)
    );

    // ---------------------------------------------------------
    // APB Slave 1: I2C
    // ---------------------------------------------------------
    apb_i2c #(
        .APB_ADDR_WIDTH (12)
    ) i_apb_i2c (
        .HCLK         (clk_i),
        .HRESETn      (rst_ni),
        .PADDR        (apb_paddr[11:0]),
        .PWDATA       (apb_pwdata),
        .PWRITE       (apb_pwrite),
        .PSEL         (apb_pselx[1]),
        .PENABLE      (apb_penable),
        .PRDATA       (apb_prdata[1]),
        .PREADY       (apb_pready[1]),
        .PSLVERR      (apb_pslverr[1]),
        .interrupt_o  (i2c_interrupt_o),
        .scl_pad_i    (i2c_scl_pad_i),
        .scl_pad_o    (i2c_scl_pad_o),
        .scl_padoen_o (i2c_scl_padoen_o),
        .sda_pad_i    (i2c_sda_pad_i),
        .sda_pad_o    (i2c_sda_pad_o),
        .sda_padoen_o (i2c_sda_padoen_o)
    );

    // ---------------------------------------------------------
    // APB Slave 2: SPI Master
    // ---------------------------------------------------------
    apb_spi_master #(
        .BUFFER_DEPTH   (10), 
        .APB_ADDR_WIDTH (12)
    ) i_apb_spi (
        .HCLK         (clk_i),
        .HRESETn      (rst_ni),
        .PADDR        (apb_paddr[11:0]),
        .PWDATA       (apb_pwdata),
        .PWRITE       (apb_pwrite),
        .PSEL         (apb_pselx[2]),
        .PENABLE      (apb_penable),
        .PRDATA       (apb_prdata[2]),
        .PREADY       (apb_pready[2]),
        .PSLVERR      (apb_pslverr[2]),
        .events_o     (spi_events_o),
        .spi_clk      (spi_clk_o),
        .spi_csn0     (spi_csn0_o),
        .spi_csn1     (spi_csn1_o),
        .spi_csn2     (spi_csn2_o),
        .spi_csn3     (spi_csn3_o),
        .spi_mode     (spi_mode_o),
        .spi_sdo0     (spi_sdo0_o),
        .spi_sdo1     (spi_sdo1_o),
        .spi_sdo2     (spi_sdo2_o),
        .spi_sdo3     (spi_sdo3_o),
        .spi_sdi0     (spi_sdi0_i),
        .spi_sdi1     (spi_sdi1_i),
        .spi_sdi2     (spi_sdi2_i),
        .spi_sdi3     (spi_sdi3_i)
    );

    // ---------------------------------------------------------
    // APB Slave 3: GPIO
    // ---------------------------------------------------------
    apb_gpio #(
        .APB_ADDR_WIDTH (12),
        .PAD_NUM        (GpioPadNum),
        .NBIT_PADCFG    (GpioPadCfgBits)
    ) i_apb_gpio (
        .HCLK            (clk_i),
        .HRESETn         (rst_ni),
        .dft_cg_enable_i (dft_cg_enable_i),
        .PADDR           (apb_paddr[11:0]),
        .PWDATA          (apb_pwdata),
        .PWRITE          (apb_pwrite),
        .PSEL            (apb_pselx[3]),
        .PENABLE         (apb_penable),
        .PRDATA          (apb_prdata[3]),
        .PREADY          (apb_pready[3]),
        .PSLVERR         (apb_pslverr[3]),
        .gpio_in         (gpio_in_i),
        .gpio_in_sync    (gpio_in_sync_o),
        .gpio_out        (gpio_out_o),
        .gpio_dir        (gpio_dir_o),
        .gpio_padcfg     (gpio_padcfg_o),
        .interrupt       (gpio_interrupt_o)
    );

    // ---------------------------------------------------------
    // APB Slave 4: Timer
    // ---------------------------------------------------------
    apb_timer #(
        .APB_ADDR_WIDTH (12),
        .TIMER_CNT      (TimerCnt)
    ) i_apb_timer (
        .HCLK       (clk_i),
        .HRESETn    (rst_ni),
        .PADDR      (apb_paddr[11:0]),
        .PWDATA     (apb_pwdata),
        .PWRITE     (apb_pwrite),
        .PSEL       (apb_pselx[4]),
        .PENABLE    (apb_penable),
        .PRDATA     (apb_prdata[4]),
        .PREADY     (apb_pready[4]),
        .PSLVERR    (apb_pslverr[4]),
        .irq_o      (timer_irq_o)
    );

 
// ---------------------------------------------------------
    // APB Slave 5: PLIC
    // ---------------------------------------------------------
    apb4_plic_top #(
        .PADDR_SIZE (AddrWidth), 
        .PDATA_SIZE (DataWidth),
        .SOURCES    (PlicSources),
        .TARGETS    (PlicTargets)
    ) i_apb_plic (
        .PRESETn    (rst_ni),
        .PCLK       (clk_i),
        .PSEL       (apb_pselx[5]),
        .PENABLE    (apb_penable),
        
        // ---> THE FIX: Subtract the base address to pass the exact offset <---
        .PADDR      (apb_paddr - 32'h4000_5000), 
        
        .PWRITE     (apb_pwrite),
        .PSTRB      (apb_pstrb),
        .PWDATA     (apb_pwdata),
        .PRDATA     (apb_prdata[5]),
        .PREADY     (apb_pready[5]),
        .PSLVERR    (apb_pslverr[5]),
        .src        (plic_src_i),
        .irq        (plic_irq_o)
    );


endmodule
