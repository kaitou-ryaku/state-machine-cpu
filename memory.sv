`include "typedef_collection.sv"

module memory_unit(
  input    logic            CLOCK
  , input  logic            RESET
  , input  MEMORY_FLAG_TYPE ctrl_bus
  , input  DEFAULT_TYPE     addr_bus
  , input  DEFAULT_TYPE     write_bus
  , output DEFAULT_TYPE     read_bus
  , output DEFAULT_TYPE     OUT
);

  DEFAULT_TYPE initial_memory [0:`MEMSIZE-1];
  initial $readmemb("test.mem", initial_memory);

  DEFAULT_TYPE memory [0:`MEMSIZE-1];
  assign read_bus = memory[addr_bus];
  assign OUT = memory[`MEMSIZE-1]; // memory mapped IO

  DEFAULT_TYPE next_memory;
  always_comb begin
    if (ctrl_bus == MEMORY_WRITE) next_memory = write_bus;
    else                          next_memory = memory[addr_bus];
  end

  always_ff @(posedge CLOCK) begin
    if (RESET) memory <= initial_memory;
    else memory[addr_bus] <= next_memory; // other memory addr_bus: latchbegin
  end

endmodule
