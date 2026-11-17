`include "axi/typedef.svh"
`include "axi/assign.svh"

module axi_lite_to_apb_intf #(
  parameter int unsigned NoApbSlaves = 32'd1,  // Number of connected APB slaves
  parameter int unsigned NoRules     = 32'd1,  // Number of APB address rules
  parameter int unsigned AddrWidth   = 32'd32, // Address width
  parameter int unsigned DataWidth   = 32'd32, // Data width
  parameter bit PipelineRequest      = 1'b0,   // Pipeline request path
  parameter bit PipelineResponse     = 1'b0,   // Pipeline response path
  parameter type         rule_t      = logic,  // Address Decoder rule from `common_cells`
  // DEPENDENT PARAMERETS, DO NOT OVERWRITE!
  parameter type              addr_t = logic [AddrWidth-1:0],
  parameter type              data_t = logic [DataWidth-1:0],
  parameter type              strb_t = logic [DataWidth/8-1:0],
  parameter type              sel_t  = logic [NoApbSlaves-1:0]
) (
  input  logic                    clk_i,     // Clock
  input  logic                    rst_ni,    // Asynchronous reset active low
  // AXI LITE slave port
  AXI_LITE.Slave                  slv,
  // APB master port
  output addr_t                   paddr_o,
  output logic  [2:0]             pprot_o,
  output sel_t                    pselx_o,
  output logic                    penable_o,
  output logic                    pwrite_o,
  output data_t                   pwdata_o,
  output strb_t                   pstrb_o,
  input  logic  [NoApbSlaves-1:0] pready_i,
  input  data_t [NoApbSlaves-1:0] prdata_i,
  input         [NoApbSlaves-1:0] pslverr_i,
  // APB Slave Address Map
  input  rule_t [NoRules-1:0]     addr_map_i
);
  localparam int unsigned SelIdxWidth = NoApbSlaves > 1 ? $clog2(NoApbSlaves) : 1;

  typedef struct packed {
    addr_t          paddr;   // same as AXI4-Lite
    axi_pkg::prot_t pprot;   // same as AXI4-Lite, specification is the same
    logic           psel;    // onehot, one psel line per connected APB4 slave
    logic           penable; // enable signal shows second APB4 cycle
    logic           pwrite;  // write enable
    data_t          pwdata;  // write data, comes from W channel
    strb_t          pstrb;   // write strb, comes from W channel
  } apb_req_t;

  typedef struct packed {
    logic  pready;   // slave signals that it is ready
    data_t prdata;   // read data, connects to R channel
    logic  pslverr;  // gets translated into either `axi_pkg::RESP_OK` or `axi_pkg::RESP_SLVERR`
  } apb_resp_t;

  `AXI_LITE_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t)
  `AXI_LITE_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t)
  `AXI_LITE_TYPEDEF_B_CHAN_T(b_chan_t)
  `AXI_LITE_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t)
  `AXI_LITE_TYPEDEF_R_CHAN_T(r_chan_t, data_t)
  `AXI_LITE_TYPEDEF_REQ_T(axi_req_t, aw_chan_t, w_chan_t, ar_chan_t)
  `AXI_LITE_TYPEDEF_RESP_T(axi_resp_t, b_chan_t, r_chan_t)

  axi_req_t                     axi_req;
  axi_resp_t                    axi_resp;
  apb_req_t   [NoApbSlaves-1:0] apb_req;
  apb_resp_t  [NoApbSlaves-1:0] apb_resp;
  logic       [SelIdxWidth-1:0] apb_sel;

  `AXI_LITE_ASSIGN_TO_REQ(axi_req, slv)
  `AXI_LITE_ASSIGN_FROM_RESP(slv, axi_resp)

  onehot_to_bin #(
    .ONEHOT_WIDTH ( NoApbSlaves )
  ) i_onehot_to_bin (
    .onehot ( pselx_o ),
    .bin    ( apb_sel )
  );

  assign paddr_o   = apb_req[apb_sel].paddr;
  assign pprot_o   = apb_req[apb_sel].pprot;
  assign penable_o = apb_req[apb_sel].penable;
  assign pwrite_o  = apb_req[apb_sel].pwrite;
  assign pwdata_o  = apb_req[apb_sel].pwdata;
  assign pstrb_o   = apb_req[apb_sel].pstrb;
  for (genvar i = 0; i < NoApbSlaves; i++) begin : gen_apb_resp_assign
    assign pselx_o[i]          = apb_req[i].psel;
    assign apb_resp[i].pready  = pready_i[i];
    assign apb_resp[i].prdata  = prdata_i[i];
    assign apb_resp[i].pslverr = pslverr_i[i];
  end

  axi_lite_to_apb #(
    .NoApbSlaves      ( NoApbSlaves       ),
    .NoRules          ( NoRules           ),
    .AddrWidth        ( AddrWidth         ),
    .DataWidth        ( DataWidth         ),
    .PipelineRequest  ( PipelineRequest   ),
    .PipelineResponse ( PipelineResponse  ),
    .axi_lite_req_t   ( axi_req_t         ),
    .axi_lite_resp_t  ( axi_resp_t        ),
    .apb_req_t        ( apb_req_t         ),
    .apb_resp_t       ( apb_resp_t        ),
    .rule_t           ( rule_t            )
  ) i_axi_lite_to_apb (
    .clk_i,     // Clock
    .rst_ni,    // Asynchronous reset active low
    // AXI LITE slave port
    .axi_lite_req_i  ( axi_req  ),
    .axi_lite_resp_o ( axi_resp ),
    // APB master port
    .apb_req_o       ( apb_req  ),
    .apb_resp_i      ( apb_resp ),
    // APB Slave Address Map
    .addr_map_i
  );
endmodule
