`include "typedef_collection.sv"

module chipset(
  input    logic            CLOCK
  , input  logic            RESET

  , input  DEFAULT_TYPE     rom_read_bus
  , output DEFAULT_TYPE     rom_addr_bus

  , input  DEFAULT_TYPE     mem_read_bus
  , output DEFAULT_TYPE     mem_addr_bus

  , input  DEFAULT_TYPE     mem_read_bus
  , output MEMORY_FLAG_TYPE mem_ctrl_bus
  , output DEFAULT_TYPE     mem_addr_bus
  , output DEFAULT_TYPE     mem_write_bus

  , input  DEFAULT_TYPE     mem_write_bus
  , output DEFAULT_TYPE     mem_read_bus

  , input  MEMORY_FLAG_TYPE cpu_ctrl_bus
  , input  DEFAULT_TYPE     cpu_addr_bus
  , input  DEFAULT_TYPE     cpu_write_bus
  , output DEFAULT_TYPE     cpu_read_bus
);
  (* RAM_STYLE="BLOCK" *) reg [7:0] rom [0:`ROMSIZE-1];
  initial $readmemb("test.mem", rom);

  DEFAULT_TYPE addr_reg;
  assign read_bus = rom[addr_reg];

  always_ff @(posedge CLOCK) addr_reg <= addr_bus;

endmodule

