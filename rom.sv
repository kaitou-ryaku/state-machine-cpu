`include "typedef_collection.sv"

module rom_unit(
  input    logic        CLOCK
  , input  DEFAULT_TYPE addr_bus
  , output DEFAULT_TYPE read_bus
);
  (* RAM_STYLE="BLOCK" *) reg [7:0] rom [0:`ROMSIZE-1];
  initial $readmemb("test.mem", rom);

  DEFAULT_TYPE addr_reg;
  assign read_bus = rom[addr_reg];

  always_ff @(posedge CLOCK) addr_reg <= addr_bus;

endmodule
