`include "obi/typedef.svh"
`include "obi/assign.svh"

module obi_demux_intf #(
  /// The OBI configuration for all ports.
  parameter obi_pkg::obi_cfg_t ObiCfg      = obi_pkg::ObiDefaultConfig,
  /// The number of manager ports.
  parameter int unsigned       NumMgrPorts = 32'd0,
  /// The maximum number of outstanding transactions.
  parameter int unsigned       NumMaxTrans = 32'd0,
  /// The type of the port select signal.
  parameter type               select_t    = logic [cf_math_pkg::idx_width(NumMgrPorts)-1:0]
) (
  input logic         clk_i,
  input logic         rst_ni,

  input select_t      sbr_port_select_i,
  OBI_BUS.Subordinate sbr_port,

  OBI_BUS.Manager     mgr_ports [NumMgrPorts]
);

  `OBI_TYPEDEF_ALL(obi, ObiCfg)

  obi_req_t sbr_port_req;
  obi_rsp_t sbr_port_rsp;

  obi_req_t [NumMgrPorts-1:0] mgr_ports_req;
  obi_rsp_t [NumMgrPorts-1:0] mgr_ports_rsp;

  `OBI_ASSIGN_TO_REQ(sbr_port_req, sbr_port, ObiCfg)
  `OBI_ASSIGN_FROM_RSP(sbr_port, sbr_port_rsp, ObiCfg)

  for (genvar i = 0; i < NumMgrPorts; i++) begin : gen_mgr_ports_assign
    `OBI_ASSIGN_FROM_REQ(mgr_ports[i], mgr_ports_req[i], ObiCfg)
    `OBI_ASSIGN_TO_RSP(mgr_ports_rsp[i], mgr_ports[i], ObiCfg)
  end

  obi_demux #(
    .ObiCfg      ( ObiCfg      ),
    .obi_req_t   ( obi_req_t   ),
    .obi_rsp_t   ( obi_rsp_t   ),
    .NumMgrPorts ( NumMgrPorts ),
    .NumMaxTrans ( NumMaxTrans ),
    .select_t    ( select_t    )
  ) i_obi_demux (
    .clk_i,
    .rst_ni,
    .sbr_port_select_i,
    .sbr_port_req_i   ( sbr_port_req  ),
    .sbr_port_rsp_o   ( sbr_port_rsp  ),
    .mgr_ports_req_o  ( mgr_ports_req ),
    .mgr_ports_rsp_i  ( mgr_ports_rsp )
  );

endmodule