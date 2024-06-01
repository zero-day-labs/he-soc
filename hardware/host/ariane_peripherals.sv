// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Xilinx Peripehrals

`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"
`include "axi/assign.svh"
`include "axi/typedef.svh"

module ariane_peripherals
    import udma_subsystem_pkg::N_CAN;
    import apb_soc_pkg::NUM_ADV_TIMER;
    import ariane_soc::*;
#(
    parameter  int NumCVA6      = -1,
    parameter  int AxiAddrWidth = -1,
    parameter  int AxiDataWidth = -1,
    parameter  int AxiIdWidth   = -1,
    parameter  int AxiUserWidth = 1,
    parameter  bit InclUART     = 1,
    parameter  bit InclSPI      = 0,
    parameter  bit InclEthernet = 1,
    parameter  bit InclGPIO     = 0,
    parameter  bit InclTimer    = 1
) (
    input  logic                          clk_i           , // Clock
    input  logic                          rst_ni          , // Asynchronous reset active low
    AXI_BUS.Slave                         plic            ,
    AXI_BUS.Slave                         uart            ,
    AXI_BUS.Slave                         spi             ,
    AXI_BUS.Slave                         ethernet        ,
    AXI_BUS.Slave                         timer           ,
    AXI_BUS.Slave                         imsic           ,
    input  imsic_pkg::csr_channel_to_imsic_t   [NumCVA6-1:0]   imsic_csr_i, 
    output imsic_pkg::csr_channel_from_imsic_t [NumCVA6-1:0]   imsic_csr_o,
    output logic [NumCVA6-1:0][ariane_soc::NrIntpFiles-1:0]    irq_o,
    input  logic [31*4-1:0]               udma_evt_i      ,
    input  logic                          c2h_irq_i       ,
    input  logic                          cluster_eoc_i   ,
    input  logic [N_CAN-1:0]              can_irq_i      ,
    input  logic [NUM_ADV_TIMER-1:0]      pwm_irq_i      ,
    input  logic                        cl_dma_pe_evt_i ,
    // UART
    input  logic            rx_i            ,
    output logic            tx_o            ,

    // Ethernet
    input  logic            eth_clk_i        , // 125 MHz quadrature
    input  logic            eth_phy_tx_clk_i , // 125 MHz in-phase
    input  logic            eth_clk_200MHz_i ,

    output eth_to_pad_t     eth_to_pad       ,
    input  pad_to_eth_t     pad_to_eth       ,

    // SCMI mailbox interrupt to CVA6
    input  logic            irq_mbox_i

);

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth   ),
    .AXI_DATA_WIDTH ( AxiDataWidth   ),
    .AXI_ID_WIDTH   ( AxiIdWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth   )
  ) spi_cut();

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth   ),
    .AXI_DATA_WIDTH ( 32             ),
    .AXI_ID_WIDTH   ( AxiIdWidth     ),
    .AXI_USER_WIDTH ( AxiUserWidth   )
  ) spi_cut32();

  AXI_LITE #(
    .AXI_ADDR_WIDTH ( 7  ),
    .AXI_DATA_WIDTH ( 32 )
  ) spi_lite();

    // ---------------
    // 1. IRQC
    // ---------------
    logic [ariane_soc::NumSources-1:0] irq_sources;

    assign irq_sources[7]                            = c2h_irq_i;
    assign irq_sources[8]                            = cluster_eoc_i;
    assign irq_sources[9]                            = irq_mbox_i;
    assign irq_sources[14:10]                        = '0; // reserved for future use
    assign irq_sources[138:15]                       = udma_evt_i[123:0];
    assign irq_sources[139]                          = cl_dma_pe_evt_i;
    assign irq_sources[140]                          = can_irq_i[0];
    assign irq_sources[141]                          = can_irq_i[1];

    // Interrupt CH0 from 8 APB TIMERS
    assign irq_sources[142]                          = pwm_irq_i[0];
    assign irq_sources[143]                          = pwm_irq_i[1];
    assign irq_sources[144]                          = pwm_irq_i[2];
    assign irq_sources[145]                          = pwm_irq_i[3];
    assign irq_sources[146]                          = pwm_irq_i[4];
    assign irq_sources[147]                          = pwm_irq_i[5];
    assign irq_sources[148]                          = pwm_irq_i[6];
    assign irq_sources[149]                          = pwm_irq_i[7];

    assign irq_sources[ariane_soc::NumSources-1:150] = '0;

    ////////////////////////////////////////////////////////////////////
    /// Global Ideia
    ////////////////////////////////////////////////////////////////////
    /// XBar <==> AXI Cut <==> AXI2APB <==> APB2Reg <==> APLIC
    ////////////////////////////////////////////////////////////////////
    /////////////// XBar <==> AXI Cut
    ////////////////////////////////////////////////////////////////////
    AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth  ),
    .AXI_DATA_WIDTH ( AxiDataWidth  ),
    .AXI_ID_WIDTH   ( AxiIdWidth    ),
    .AXI_USER_WIDTH ( AxiUserWidth  )
    ) aplic_cfg_cut ();

    axi_cut_intf #(
      .ADDR_WIDTH ( AxiAddrWidth    ),
      .DATA_WIDTH ( AxiDataWidth    ),
      .ID_WIDTH   ( AxiIdWidth      ),
      .USER_WIDTH ( AxiUserWidth    )
    ) axi_aplic_cfg_cut(
      .clk_i  ( clk_i   ),
      .rst_ni ( rst_ni  ),
      .in     ( plic    ),
      .out    ( aplic_cfg_cut )
    );

    ariane_axi_soc::req_slv_t  aplic_cfg_req;
    ariane_axi_soc::resp_slv_t aplic_cfg_rsp;

    `AXI_ASSIGN_TO_REQ(aplic_cfg_req, aplic_cfg_cut)
    `AXI_ASSIGN_FROM_RESP(aplic_cfg_cut, aplic_cfg_rsp)
    
    ////////////////////////////////////////////////////////////////////
    ////////////////  AXI Cut <==> AXI2APB
    ////////////////////////////////////////////////////////////////////
    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus (clk_i);

    logic         plic_penable;
    logic         plic_pwrite;
    logic [31:0]  plic_paddr;
    logic         plic_psel;
    logic [31:0]  plic_pwdata;
    logic [31:0]  plic_prdata;
    logic         plic_pready;
    logic         plic_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_plic (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        // AW
        .AWID_i    ( aplic_cfg_req.aw.id     ),
        .AWADDR_i  ( aplic_cfg_req.aw.addr   ),
        .AWLEN_i   ( aplic_cfg_req.aw.len    ),
        .AWSIZE_i  ( aplic_cfg_req.aw.size   ),
        .AWBURST_i ( aplic_cfg_req.aw.burst  ),
        .AWLOCK_i  ( aplic_cfg_req.aw.lock   ),
        .AWCACHE_i ( aplic_cfg_req.aw.cache  ),
        .AWPROT_i  ( aplic_cfg_req.aw.prot   ),
        .AWREGION_i( aplic_cfg_req.aw.region ),
        .AWUSER_i  ( aplic_cfg_req.aw.user   ),
        .AWQOS_i   ( aplic_cfg_req.aw.qos    ),
        .AWVALID_i ( aplic_cfg_req.aw_valid  ),
        .AWREADY_o ( aplic_cfg_rsp.aw_ready ),
        // W
        .WDATA_i   ( aplic_cfg_req.w.data    ),
        .WSTRB_i   ( aplic_cfg_req.w.strb    ),
        .WLAST_i   ( aplic_cfg_req.w.last    ),
        .WUSER_i   ( aplic_cfg_req.w.user    ),
        .WVALID_i  ( aplic_cfg_req.w_valid   ),
        .WREADY_o  ( aplic_cfg_rsp.w_ready  ),
        // B
        .BID_o     ( aplic_cfg_rsp.b.id     ),
        .BRESP_o   ( aplic_cfg_rsp.b.resp   ),
        .BUSER_o   ( aplic_cfg_rsp.b.user   ),
        .BVALID_o  ( aplic_cfg_rsp.b_valid  ),
        .BREADY_i  ( aplic_cfg_req.b_ready   ),
        // AR
        .ARID_i    ( aplic_cfg_req.ar.id     ),
        .ARADDR_i  ( aplic_cfg_req.ar.addr   ),
        .ARLEN_i   ( aplic_cfg_req.ar.len    ),
        .ARSIZE_i  ( aplic_cfg_req.ar.size   ),
        .ARBURST_i ( aplic_cfg_req.ar.burst  ),
        .ARLOCK_i  ( aplic_cfg_req.ar.lock   ),
        .ARCACHE_i ( aplic_cfg_req.ar.cache  ),
        .ARPROT_i  ( aplic_cfg_req.ar.prot   ),
        .ARREGION_i( aplic_cfg_req.ar.region ),
        .ARUSER_i  ( aplic_cfg_req.ar.user   ),
        .ARQOS_i   ( aplic_cfg_req.ar.qos    ),
        .ARVALID_i ( aplic_cfg_req.ar_valid  ),
        .ARREADY_o ( aplic_cfg_rsp.ar_ready ),
        // R
        .RID_o     ( aplic_cfg_rsp.r.id     ),
        .RDATA_o   ( aplic_cfg_rsp.r.data   ),
        .RRESP_o   ( aplic_cfg_rsp.r.resp   ),
        .RLAST_o   ( aplic_cfg_rsp.r.last   ),
        .RUSER_o   ( aplic_cfg_rsp.r.user   ),
        .RVALID_o  ( aplic_cfg_rsp.r_valid  ),
        .RREADY_i  ( aplic_cfg_req.r_ready   ),
        // APB IF
        .PENABLE   ( plic_penable   ),
        .PWRITE    ( plic_pwrite    ),
        .PADDR     ( plic_paddr     ),
        .PSEL      ( plic_psel      ),
        .PWDATA    ( plic_pwdata    ),
        .PRDATA    ( plic_prdata    ),
        .PREADY    ( plic_pready    ),
        .PSLVERR   ( plic_pslverr   )
    );

    ////////////////////////////////////////////////////////////////////
    ////////////////  AXI2APB <==> APB2Reg
    ////////////////////////////////////////////////////////////////////
    apb_to_reg i_apb_to_reg (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( plic_penable ),
        .pwrite_i  ( plic_pwrite  ),
        .paddr_i   ( plic_paddr   ),
        .psel_i    ( plic_psel    ),
        .pwdata_i  ( plic_pwdata  ),
        .prdata_o  ( plic_prdata  ),
        .pready_o  ( plic_pready  ),
        .pslverr_o ( plic_pslverr ),
        .reg_o     ( reg_bus      )
    );

    // name, addr_t, data_t, strb_t
    `REG_BUS_TYPEDEF_ALL(aplic_reg, ariane_axi_soc::addr_t, logic[31:0], logic[3:0])
    aplic_reg_req_t aplic_regmap_req_o;
    aplic_reg_rsp_t aplic_regmap_resp_i;

    // assign REG_BUS.out to (req_t, rsp_t) pair
    `REG_BUS_ASSIGN_TO_REQ(aplic_regmap_req_o, reg_bus)
    `REG_BUS_ASSIGN_FROM_RSP(reg_bus, aplic_regmap_resp_i)
    ////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////
    ////////////////  IMSIC (XBAR <==> AIA)
    ////////////////////////////////////////////////////////////////////
    ariane_axi_soc::req_slv_t    lite_msi_req;
    ariane_axi_soc::resp_slv_t   lite_msi_resp;
    
    `AXI_ASSIGN_TO_REQ(lite_msi_req, imsic)
    `AXI_ASSIGN_FROM_RESP(imsic, lite_msi_resp)
    ////////////////////////////////////////////////////////////////////

    localparam imsic_protocol_pkg::protocol_cfg_t ImsicProtocolCfg = '{
        AXI_ADDR_WIDTH: AxiAddrWidth,
        AXI_DATA_WIDTH: AxiDataWidth,
        AXI_ID_WIDTH:   AxiIdWidth
    };

    for (genvar i = 0; i < imsic_pkg::DefaultImsicCfg.NrHarts; i++) begin
        assign irq_o[i] = imsic_csr_o[i].Xeip_targets;
    end

    aplic_top #(
        .AplicCfg       ( aplic_pkg::DefaultAplicCfg        ),
        .ImsicCfg       ( imsic_pkg::DefaultImsicCfg        ),
        .ProtocolCfg    ( ImsicProtocolCfg                  ),
        .reg_req_t      ( aplic_reg_req_t                   ),
        .reg_rsp_t      ( aplic_reg_rsp_t                   ),
        .axi_req_t      ( ariane_axi_soc::req_slv_t         ),
        .axi_resp_t     ( ariane_axi_soc::resp_slv_t        )
    ) aplic_top_embedded_i (
        .i_clk          ( clk_i                             ),
        .ni_rst         ( rst_ni                            ),
        .i_irq_sources  ( {irq_sources, 1'b0}               ),
        .i_req_cfg      ( aplic_regmap_req_o                ),
        .o_resp_cfg     ( aplic_regmap_resp_i               ),
        .i_imsic_csr    ( imsic_csr_i                       ),
        .o_imsic_csr    ( imsic_csr_o                       ),         
        .i_imsic_req    ( lite_msi_req                      ),
        .o_imsic_resp   ( lite_msi_resp                     )
    );

    // ---------------
    // 2. UART
    // ---------------
    logic         uart_penable;
    logic         uart_pwrite;
    logic [31:0]  uart_paddr;
    logic         uart_psel;
    logic [31:0]  uart_pwdata;
    logic [31:0]  uart_prdata;
    logic         uart_pready;
    logic         uart_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth ),
        .AXI4_ID_WIDTH      ( AxiIdWidth   ),
        .AXI4_USER_WIDTH    ( AxiUserWidth ),
        .BUFF_DEPTH_SLAVE   ( 2            ),
        .APB_ADDR_WIDTH     ( 32           )
    ) i_axi2apb_64_32_uart (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( uart.aw_id     ),
        .AWADDR_i  ( uart.aw_addr   ),
        .AWLEN_i   ( uart.aw_len    ),
        .AWSIZE_i  ( uart.aw_size   ),
        .AWBURST_i ( uart.aw_burst  ),
        .AWLOCK_i  ( uart.aw_lock   ),
        .AWCACHE_i ( uart.aw_cache  ),
        .AWPROT_i  ( uart.aw_prot   ),
        .AWREGION_i( uart.aw_region ),
        .AWUSER_i  ( uart.aw_user   ),
        .AWQOS_i   ( uart.aw_qos    ),
        .AWVALID_i ( uart.aw_valid  ),
        .AWREADY_o ( uart.aw_ready  ),
        .WDATA_i   ( uart.w_data    ),
        .WSTRB_i   ( uart.w_strb    ),
        .WLAST_i   ( uart.w_last    ),
        .WUSER_i   ( uart.w_user    ),
        .WVALID_i  ( uart.w_valid   ),
        .WREADY_o  ( uart.w_ready   ),
        .BID_o     ( uart.b_id      ),
        .BRESP_o   ( uart.b_resp    ),
        .BVALID_o  ( uart.b_valid   ),
        .BUSER_o   ( uart.b_user    ),
        .BREADY_i  ( uart.b_ready   ),
        .ARID_i    ( uart.ar_id     ),
        .ARADDR_i  ( uart.ar_addr   ),
        .ARLEN_i   ( uart.ar_len    ),
        .ARSIZE_i  ( uart.ar_size   ),
        .ARBURST_i ( uart.ar_burst  ),
        .ARLOCK_i  ( uart.ar_lock   ),
        .ARCACHE_i ( uart.ar_cache  ),
        .ARPROT_i  ( uart.ar_prot   ),
        .ARREGION_i( uart.ar_region ),
        .ARUSER_i  ( uart.ar_user   ),
        .ARQOS_i   ( uart.ar_qos    ),
        .ARVALID_i ( uart.ar_valid  ),
        .ARREADY_o ( uart.ar_ready  ),
        .RID_o     ( uart.r_id      ),
        .RDATA_o   ( uart.r_data    ),
        .RRESP_o   ( uart.r_resp    ),
        .RLAST_o   ( uart.r_last    ),
        .RUSER_o   ( uart.r_user    ),
        .RVALID_o  ( uart.r_valid   ),
        .RREADY_i  ( uart.r_ready   ),
        .PENABLE   ( uart_penable   ),
        .PWRITE    ( uart_pwrite    ),
        .PADDR     ( uart_paddr     ),
        .PSEL      ( uart_psel      ),
        .PWDATA    ( uart_pwdata    ),
        .PRDATA    ( uart_prdata    ),
        .PREADY    ( uart_pready    ),
        .PSLVERR   ( uart_pslverr   )
    );

    // CORE UART
    if (InclUART) begin : gen_uart
        apb_uart i_apb_uart0 (
            .CLK     ( clk_i           ),
            .RSTN    ( rst_ni          ),
            .PSEL    ( uart_psel       ),
            .PENABLE ( uart_penable    ),
            .PWRITE  ( uart_pwrite     ),
            .PADDR   ( uart_paddr[4:2] ),
            .PWDATA  ( uart_pwdata     ),
            .PRDATA  ( uart_prdata     ),
            .PREADY  ( uart_pready     ),
            .PSLVERR ( uart_pslverr    ),
            .INT     ( irq_sources[1]  ),
            .OUT1N   (                 ), // keep open
            .OUT2N   (                 ), // keep open
            .RTSN    (                 ), // no flow control
            .DTRN    (                 ), // no flow control
            .CTSN    ( 1'b0            ),
            .DSRN    ( 1'b0            ),
            .DCDN    ( 1'b0            ),
            .RIN     ( 1'b0            ),
            .SIN     ( rx_i            ),
            .SOUT    ( tx_o            )
        );
    end else begin
        assign irq_sources[1] = 1'b0;
        /* pragma translate_off */
        mock_uart i_mock_uart0 (
            .clk_i     ( clk_i        ),
            .rst_ni    ( rst_ni       ),
            .penable_i ( uart_penable ),
            .pwrite_i  ( uart_pwrite  ),
            .paddr_i   ( uart_paddr   ),
            .psel_i    ( uart_psel    ),
            .pwdata_i  ( uart_pwdata  ),
            .prdata_o  ( uart_prdata  ),
            .pready_o  ( uart_pready  ),
            .pslverr_o ( uart_pslverr )
        );
        /* pragma translate_on */
    end

    // ---------------
    // 3. SPI
    // ---------------
    if (InclSPI) begin : gen_spi

         axi_cut_intf #(
           .ADDR_WIDTH ( AxiAddrWidth   ),
           .DATA_WIDTH ( AxiDataWidth   ),
           .ID_WIDTH   ( AxiIdWidth     ),
           .USER_WIDTH ( AxiUserWidth   )
           ) axi_spi_cut(
              .clk_i  ( clk_i   ),
              .rst_ni ( rst_ni  ),
              .in     ( spi     ),
              .out    ( spi_cut )
              );

         axi_dw_converter_intf #(
           .AXI_ADDR_WIDTH          ( AxiAddrWidth   ),
           .AXI_ID_WIDTH            ( AxiIdWidth     ),
           .AXI_USER_WIDTH          ( AxiUserWidth   ),
           .AXI_MAX_READS           ( 1              ),
           .AXI_SLV_PORT_DATA_WIDTH ( AxiDataWidth   ),
           .AXI_MST_PORT_DATA_WIDTH ( 32             )
           ) axi_spi_dw_converter (
              .clk_i  ( clk_i     ),
              .rst_ni ( rst_ni    ),
              .slv    ( spi_cut   ),
              .mst    ( spi_cut32 )
              );

         axi_to_axi_lite_intf #(
           .AXI_ADDR_WIDTH     ( 7            ),
           .AXI_DATA_WIDTH     ( 32           ),
           .AXI_ID_WIDTH       ( AxiIdWidth   ),
           .AXI_USER_WIDTH     ( AxiUserWidth ),
           .AXI_MAX_READ_TXNS  ( 1            ),
           .AXI_MAX_WRITE_TXNS ( 1            )
           ) axi2axilite_spi (
               .clk_i      ( clk_i     ),
               .rst_ni     ( rst_ni    ),
               .testmode_i ( 1'b0      ),
               .slv        ( spi_cut32 ),
               .mst        ( spi_lite  )
               );

         xilinx_qspi axi_quad_spi_0(
           .ext_spi_clk   ( clk_i             ),
           .s_axi_aclk    ( clk_i             ),
           .s_axi_aresetn ( rst_ni            ),
           .s_axi_awaddr  ( spi_lite.aw_addr  ),
           .s_axi_awvalid ( spi_lite.aw_valid ),
           .s_axi_awready ( spi_lite.aw_ready ),
           .s_axi_wdata   ( spi_lite.w_data   ),
           .s_axi_wstrb   ( spi_lite.w_strb   ),
           .s_axi_wvalid  ( spi_lite.w_valid  ),
           .s_axi_wready  ( spi_lite.w_ready  ),
           .s_axi_bresp   ( spi_lite.b_resp   ),
           .s_axi_bvalid  ( spi_lite.b_valid  ),
           .s_axi_bready  ( spi_lite.b_ready  ),
           .s_axi_araddr  ( spi_lite.ar_addr  ),
           .s_axi_arvalid ( spi_lite.ar_valid ),
           .s_axi_arready ( spi_lite.ar_ready ),
           .s_axi_rdata   ( spi_lite.r_data   ),
           .s_axi_rresp   ( spi_lite.r_resp   ),
           .s_axi_rvalid  ( spi_lite.r_valid  ),
           .s_axi_rready  ( spi_lite.r_ready  ),
           .cfgclk        (                   ),
           .cfgmclk       (                   ),
           .eos           (                   ),
           .preq          (                   ),
           .gsr           ( 1'b0              ),
           .gts           ( 1'b1              ),
           .keyclearb     ( 1'b1              ),
           .usrcclkts     ( 1'b0              ),
           .usrdoneo      ( 1'b1              ),
           .usrdonets     ( 1'b1              ),
           .ip2intc_irpt  ( irq_sources[0]    )
          );


    end else begin
        assign spi_clk_o = 1'b0;
        assign spi_mosi = 1'b0;
        assign spi_ss = 1'b0;

        assign irq_sources [0] = 1'b0;
        assign spi.aw_ready = 1'b1;
        assign spi.ar_ready = 1'b1;
        assign spi.w_ready = 1'b1;

        assign spi.b_valid = spi.aw_valid;
        assign spi.b_id = spi.aw_id;
        assign spi.b_resp = axi_pkg::RESP_SLVERR;
        assign spi.b_user = '0;

        assign spi.r_valid = spi.ar_valid;
        assign spi.r_resp = axi_pkg::RESP_SLVERR;
        assign spi.r_data = 'hdeadbeef;
        assign spi.r_last = 1'b1;
    end


    // ---------------
    // 4. Ethernet
    // ---------------
    if (InclEthernet)
      begin

        logic [3:0] eth_txd_o, eth_rxd_i;
        logic                      eth_en, eth_we, eth_int_n, eth_mdio_i, eth_mdio_o, eth_mdio_oe;
        logic [AxiAddrWidth-1:0]   eth_addr;
        logic [AxiDataWidth-1:0]   eth_wrdata, eth_rdata;
        logic [AxiDataWidth/8-1:0] eth_be;

        assign eth_rxd_i[3] = pad_to_eth.eth_rxd3_i;
        assign eth_rxd_i[2] = pad_to_eth.eth_rxd2_i;
        assign eth_rxd_i[1] = pad_to_eth.eth_rxd1_i;
        assign eth_rxd_i[0] = pad_to_eth.eth_rxd0_i;

        assign eth_to_pad.eth_txd3_o = eth_txd_o[3];
        assign eth_to_pad.eth_txd2_o = eth_txd_o[2];
        assign eth_to_pad.eth_txd1_o = eth_txd_o[1];
        assign eth_to_pad.eth_txd0_o = eth_txd_o[0];

        axi2mem #(
        .AXI_ID_WIDTH   ( AxiIdWidth       ),
        .AXI_ADDR_WIDTH ( AxiAddrWidth     ),
        .AXI_DATA_WIDTH ( AxiDataWidth     ),
        .AXI_USER_WIDTH ( AxiUserWidth     )
        ) axi2ethernet (
            .clk_i  ( clk_i                   ),
            .rst_ni ( rst_ni                  ),
            .slave  ( ethernet                ),
            .req_o  ( eth_en                  ),
            .we_o   ( eth_we                  ),
            .addr_o ( eth_addr                ),
            .be_o   ( eth_be                  ),
            .data_o ( eth_wrdata              ),
            .data_i ( eth_rdata               )
        );

        framing_top eth_rgmii (
           .msoc_clk(clk_i),
           .core_lsu_addr(eth_addr[14:0]),
           .core_lsu_wdata(eth_wrdata),
           .core_lsu_be(eth_be),
           .ce_d(eth_en),
           .we_d(eth_en & eth_we),
           .framing_sel(eth_en),
           .framing_rdata(eth_rdata),
           .rst_int(!rst_ni),

           .clk_int( eth_clk_i  ), // 125 MHz in-phase
           .clk90_int(  eth_phy_tx_clk_i  ),    // 125 MHz quadrature
           .clk_200_int( eth_clk_200MHz_i ),
           /*
            * Ethernet: 1000BASE-T RGMII
            */
           .phy_rx_clk( pad_to_eth.eth_rxck_i ),
           .phy_rxd( eth_rxd_i ),
           .phy_rx_ctl(pad_to_eth.eth_rxctl_i),

           .phy_tx_clk(eth_to_pad.eth_txck_o),
           .phy_txd( eth_txd_o ),
           .phy_tx_ctl( eth_to_pad.eth_txctl_o ),
           .phy_reset_n( eth_to_pad.eth_rstn_o ),
           .phy_mdc( eth_to_pad.eth_mdc_o ),

           .phy_int_n( ),
           .phy_pme_n( ),

           .phy_mdio_i(pad_to_eth.eth_md_i),
           .phy_mdio_o(eth_to_pad.eth_md_o),
           .phy_mdio_oe(eth_to_pad.eth_md_oe),

           .eth_irq(irq_sources[2])
        );

      end
    else
      begin
        assign irq_sources [2] = 1'b0;
        assign ethernet.aw_ready = 1'b1;
        assign ethernet.ar_ready = 1'b1;
        assign ethernet.w_ready = 1'b1;

        assign ethernet.b_valid = ethernet.aw_valid;
        assign ethernet.b_id = ethernet.aw_id;
        assign ethernet.b_resp = axi_pkg::RESP_SLVERR;
        assign ethernet.b_user = '0;

        assign ethernet.r_valid = ethernet.ar_valid;
        assign ethernet.r_resp = axi_pkg::RESP_SLVERR;
        assign ethernet.r_data = 'hdeadbeef;
        assign ethernet.r_last = 1'b1;
    end


    // ---------------
    // 5. Timer
    // ---------------
    if (InclTimer) begin : gen_timer
        logic         timer_penable;
        logic         timer_pwrite;
        logic [31:0]  timer_paddr;
        logic         timer_psel;
        logic [31:0]  timer_pwdata;
        logic [31:0]  timer_prdata;
        logic         timer_pready;
        logic         timer_pslverr;

        axi2apb_64_32 #(
            .AXI4_ADDRESS_WIDTH ( AxiAddrWidth ),
            .AXI4_RDATA_WIDTH   ( AxiDataWidth ),
            .AXI4_WDATA_WIDTH   ( AxiDataWidth ),
            .AXI4_ID_WIDTH      ( AxiIdWidth   ),
            .AXI4_USER_WIDTH    ( AxiUserWidth ),
            .BUFF_DEPTH_SLAVE   ( 2            ),
            .APB_ADDR_WIDTH     ( 32           )
        ) i_axi2apb_64_32_timer (
            .ACLK      ( clk_i           ),
            .ARESETn   ( rst_ni          ),
            .test_en_i ( 1'b0            ),
            .AWID_i    ( timer.aw_id     ),
            .AWADDR_i  ( timer.aw_addr   ),
            .AWLEN_i   ( timer.aw_len    ),
            .AWSIZE_i  ( timer.aw_size   ),
            .AWBURST_i ( timer.aw_burst  ),
            .AWLOCK_i  ( timer.aw_lock   ),
            .AWCACHE_i ( timer.aw_cache  ),
            .AWPROT_i  ( timer.aw_prot   ),
            .AWREGION_i( timer.aw_region ),
            .AWUSER_i  ( timer.aw_user   ),
            .AWQOS_i   ( timer.aw_qos    ),
            .AWVALID_i ( timer.aw_valid  ),
            .AWREADY_o ( timer.aw_ready  ),
            .WDATA_i   ( timer.w_data    ),
            .WSTRB_i   ( timer.w_strb    ),
            .WLAST_i   ( timer.w_last    ),
            .WUSER_i   ( timer.w_user    ),
            .WVALID_i  ( timer.w_valid   ),
            .WREADY_o  ( timer.w_ready   ),
            .BID_o     ( timer.b_id      ),
            .BRESP_o   ( timer.b_resp    ),
            .BVALID_o  ( timer.b_valid   ),
            .BUSER_o   ( timer.b_user    ),
            .BREADY_i  ( timer.b_ready   ),
            .ARID_i    ( timer.ar_id     ),
            .ARADDR_i  ( timer.ar_addr   ),
            .ARLEN_i   ( timer.ar_len    ),
            .ARSIZE_i  ( timer.ar_size   ),
            .ARBURST_i ( timer.ar_burst  ),
            .ARLOCK_i  ( timer.ar_lock   ),
            .ARCACHE_i ( timer.ar_cache  ),
            .ARPROT_i  ( timer.ar_prot   ),
            .ARREGION_i( timer.ar_region ),
            .ARUSER_i  ( timer.ar_user   ),
            .ARQOS_i   ( timer.ar_qos    ),
            .ARVALID_i ( timer.ar_valid  ),
            .ARREADY_o ( timer.ar_ready  ),
            .RID_o     ( timer.r_id      ),
            .RDATA_o   ( timer.r_data    ),
            .RRESP_o   ( timer.r_resp    ),
            .RLAST_o   ( timer.r_last    ),
            .RUSER_o   ( timer.r_user    ),
            .RVALID_o  ( timer.r_valid   ),
            .RREADY_i  ( timer.r_ready   ),
            .PENABLE   ( timer_penable   ),
            .PWRITE    ( timer_pwrite    ),
            .PADDR     ( timer_paddr     ),
            .PSEL      ( timer_psel      ),
            .PWDATA    ( timer_pwdata    ),
            .PRDATA    ( timer_prdata    ),
            .PREADY    ( timer_pready    ),
            .PSLVERR   ( timer_pslverr   )
        );

        apb_timer #(
                .APB_ADDR_WIDTH ( 32 ),
                .TIMER_CNT      ( 2  )
        ) i_timer (
            .HCLK    ( clk_i            ),
            .HRESETn ( rst_ni           ),
            .PSEL    ( timer_psel       ),
            .PENABLE ( timer_penable    ),
            .PWRITE  ( timer_pwrite     ),
            .PADDR   ( timer_paddr      ),
            .PWDATA  ( timer_pwdata     ),
            .PRDATA  ( timer_prdata     ),
            .PREADY  ( timer_pready     ),
            .PSLVERR ( timer_pslverr    ),
            .irq_o   ( irq_sources[6:3] )
        );
    end
endmodule
