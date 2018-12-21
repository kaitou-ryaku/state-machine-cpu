`include "typedef_collection.sv"

module memory_unit(
  input    logic            CLOCK
  , input  logic            RESET
  , input  MEMORY_FLAG_TYPE rw_flag
  , input  DEFAULT_TYPE     address
  , input  DEFAULT_TYPE     write_memory_value
  , output DEFAULT_TYPE     read_memory_value
);

  assign read_memory_value = `REGSIZE'd0;

  DEFAULT_TYPE initial_memory [0:`MEMSIZE-1];
  initial $readmemb("test.mem", initial_memory);

  DEFAULT_TYPE memory [0:`MEMSIZE-1];
  assign read_memory_value = memory[address];

  DEFAULT_TYPE next_memory;
  always_comb begin
    if (rw_flag == MEMORY_WRITE) next_memory = write_memory_value;
    else                         next_memory = memory[address];
  end

  always_ff @(posedge CLOCK) begin
    if (RESET) memory <= initial_memory;
    else memory[address] <= next_memory; // other memory address: latchbegin
  end

endmodule
