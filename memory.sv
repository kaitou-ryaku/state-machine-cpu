`include "typedef_collection.sv"

module memory_unit(
  input    logic            CLOCK
  , input  MEMORY_FLAG_TYPE ctrl_bus
  , input  DEFAULT_TYPE     addr_bus
  , input  DEFAULT_TYPE     write_bus
  , output DEFAULT_TYPE     read_bus
);
  (* RAM_STYLE="BLOCK" *) reg [7:0] memory [0:`MEMSIZE-1];
  initial $readmemb("test.mem", memory);

  DEFAULT_TYPE addr_reg;
  assign read_bus = memory[addr_reg];

  always_ff @(posedge CLOCK) begin
    if (ctrl_bus == MEMORY_WRITE) memory[addr_bus] <= write_bus;
    addr_reg <= addr_bus;
  end

endmodule
