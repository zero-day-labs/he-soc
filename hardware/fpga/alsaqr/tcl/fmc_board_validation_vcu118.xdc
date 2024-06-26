####################################################################
# PADFRAME FMC PERIPHERAL BOARD (SPI - I2C - UART - SDIO)          #
####################################################################

# QSPI - CS
set_property -dict {PACKAGE_PIN AP12 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_00_pad]
# QSPI - SCK
set_property -dict {PACKAGE_PIN AN16 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_01_pad]
# QSPI - IO0
set_property -dict {PACKAGE_PIN AR12 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_03_pad]
# QSPI - IO1
set_property -dict {PACKAGE_PIN AT14 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_02_pad]

# I2C - SCL
set_property -dict {PACKAGE_PIN AK15 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_04_pad]
# I2C - SDA
set_property -dict {PACKAGE_PIN AL15 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_05_pad]

# UART - TX
set_property -dict {PACKAGE_PIN AW10 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_06_pad]
# UART - RX
set_property -dict {PACKAGE_PIN AV10 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_07_pad]

# SDIO
set_property -dict {PACKAGE_PIN AU11 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_08_pad]
set_property -dict {PACKAGE_PIN AV11 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_09_pad]
set_property -dict {PACKAGE_PIN AT12 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_10_pad]
set_property -dict {PACKAGE_PIN AU12 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_11_pad]
set_property -dict {PACKAGE_PIN AW13 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_12_pad]
set_property -dict {PACKAGE_PIN AY13 IOSTANDARD LVCMOS18} [get_ports pad_periphs_pad_gpio_b_13_pad]

