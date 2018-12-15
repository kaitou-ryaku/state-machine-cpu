set_property -dict {PACKAGE_PIN E3 IOSTANDARD  LVCMOS33} [get_ports {CLK}];
create_clock -period 10.0 -name sys_clk_pin -waveform {0.0 5.0} -add [get_ports CLK];

set_property -dict {PACKAGE_PIN F6  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[0]}];
set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[1]}];
set_property -dict {PACKAGE_PIN J2  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[2]}];
set_property -dict {PACKAGE_PIN H6  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[3]}];
set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[4]}];
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[5]}];
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {OUTPUT[6]}];
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {OUTPUT[7]}];

set_property -dict {PACKAGE_PIN D9  IOSTANDARD LVCMOS33} [get_ports {BUTTON}];
