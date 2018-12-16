set_property -dict {PACKAGE_PIN E3 IOSTANDARD  LVCMOS33} [get_ports {PHYSICAL_CLOCK}];
create_clock -period 10.0 -name sys_clk_pin -waveform {0.0 5.0} -add [get_ports PHYSICAL_CLOCK];

set_property -dict {PACKAGE_PIN F6  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[0]}];
set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[1]}];
set_property -dict {PACKAGE_PIN J2  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[2]}];
set_property -dict {PACKAGE_PIN H6  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[3]}];
set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[4]}];
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[5]}];
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[6]}];
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED[7]}];

set_property -dict {PACKAGE_PIN J3  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED_RESET}];
set_property -dict {PACKAGE_PIN K1  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_LED_CLOCK}];

set_property -dict {PACKAGE_PIN D9  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_BUTTON[0]}];
set_property -dict {PACKAGE_PIN C9  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_BUTTON[1]}];
set_property -dict {PACKAGE_PIN B9  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_BUTTON[2]}];
set_property -dict {PACKAGE_PIN B8  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_BUTTON[3]}];

set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_SWITCH[0]}];
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_SWITCH[1]}];
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_SWITCH[2]}];
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_SWITCH[3]}];

set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_RESET}];

# UART
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_UART_TX}];
set_property -dict {PACKAGE_PIN A9  IOSTANDARD LVCMOS33} [get_ports {PHYSICAL_UART_RX}];
