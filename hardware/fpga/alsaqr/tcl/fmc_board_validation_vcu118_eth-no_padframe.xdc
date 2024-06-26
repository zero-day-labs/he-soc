# Ethernet
set_property -dict {PACKAGE_PIN BA16 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_rxd[0]}]
set_property -dict {PACKAGE_PIN BC13 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_rxd[1]}]
set_property -dict {PACKAGE_PIN BC14 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_rxd[2]}]
set_property -dict {PACKAGE_PIN BD15 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_rxd[3]}]
set_property -dict {PACKAGE_PIN BA15 IOSTANDARD LVCMOS18} [get_ports fmc_eth_rxctl]
set_property -dict {PACKAGE_PIN BC15 IOSTANDARD LVCMOS18} [get_ports fmc_eth_rxck]
set_property -dict {PACKAGE_PIN BF11 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_txd[0]}]
set_property -dict {PACKAGE_PIN BF12 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_txd[1]}]
set_property -dict {PACKAGE_PIN BE12 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_txd[2]}]
set_property -dict {PACKAGE_PIN BD12 IOSTANDARD LVCMOS18} [get_ports {fmc_eth_txd[3]}]
set_property -dict {PACKAGE_PIN BD11 IOSTANDARD LVCMOS18} [get_ports fmc_eth_txctl]
set_property -dict {PACKAGE_PIN BE15 IOSTANDARD LVCMOS18} [get_ports fmc_eth_txck]
set_property -dict {PACKAGE_PIN BA9 IOSTANDARD LVCMOS18} [get_ports fmc_eth_mdio]
set_property -dict {PACKAGE_PIN AR13 IOSTANDARD LVCMOS18} [get_ports fmc_eth_mdc]
set_property -dict {PACKAGE_PIN AY9 IOSTANDARD LVCMOS18} [get_ports fmc_eth_rst_n]

#############################################
# Ethernet Constraints for 1Gb/s
#############################################
# Modified for 125MHz receive clock
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets fmc_eth_rxck_IBUF_inst/O]

create_clock -period 8.000 -name fmc_eth_rxck [get_ports fmc_eth_rxck]
set_clock_groups -asynchronous -group [get_clocks fmc_eth_rxck -include_generated_clocks]

set_input_delay -clock fmc_eth_rxck -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_rxd[0] ]
set_input_delay -clock fmc_eth_rxck -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_rxd[0] ]

set_input_delay -clock fmc_eth_rxck -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_rxd[1] ]
set_input_delay -clock fmc_eth_rxck -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_rxd[1] ]

set_input_delay -clock fmc_eth_rxck -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_rxd[2] ]
set_input_delay -clock fmc_eth_rxck -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_rxd[2] ]

set_input_delay -clock fmc_eth_rxck -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_rxd[3] ]
set_input_delay -clock fmc_eth_rxck -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_rxd[3] ]

set_input_delay -clock fmc_eth_rxck -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_rxctl  ]
set_input_delay -clock fmc_eth_rxck -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_rxctl  ]

set_output_delay -clock ETH_CLK_125 -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_txd[0] ]
set_output_delay -clock ETH_CLK_125 -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_txd[0] ]

set_output_delay -clock ETH_CLK_125 -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_txd[1] ]
set_output_delay -clock ETH_CLK_125 -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_txd[1] ]

set_output_delay -clock ETH_CLK_125 -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_txd[2] ]
set_output_delay -clock ETH_CLK_125 -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_txd[2] ]
j
set_output_delay -clock ETH_CLK_125 -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_txd[3] ]
set_output_delay -clock ETH_CLK_125 -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_txd[3] ]

set_output_delay -clock ETH_CLK_125 -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_txctl  ]
set_output_delay -clock ETH_CLK_125 -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_txctl  ]

set_output_delay -clock ETH_CLK_125 -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_txck   ]
set_output_delay -clock ETH_CLK_125 -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_txck   ]

set_output_delay -clock ALSAQR_CLK  -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_mdio   ]
set_output_delay -clock ALSAQR_CLK  -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_mdio   ]

set_input_delay  -clock ALSAQR_CLK  -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_mdio   ]
set_input_delay  -clock ALSAQR_CLK  -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_mdio   ]

set_output_delay -clock ALSAQR_CLK  -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_mdc    ]
set_output_delay -clock ALSAQR_CLK  -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_mdc    ]

set_output_delay -clock ALSAQR_CLK  -max [ expr 8 * 0.35 ] [ get_ports fmc_eth_rst_n  ]
set_output_delay -clock ALSAQR_CLK  -min [ expr 8 * 0.10 ] [ get_ports fmc_eth_rst_n  ]

####################################################################################
# Constraints from file : 'timing_constr.xdc'
####################################################################################

