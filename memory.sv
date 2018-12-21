`define MEMSIZE 16
`define REGSIZE 8

typedef logic [`REGSIZE-1:0] DEFAULT_TYPE;
typedef enum logic [3:0] {MEMORY_STAY, MEMORY_READ, MEMORY_WRITE} MEMORY_FLAG;

module memory_unit(
  input    logic        CLOCK
  , input  logic        RESET
  , input  MEMORY_FLAG  rw_flag
  , input  DEFAULT_TYPE address
  , input  DEFAULT_TYPE write_value
  , output DEFAULT_TYPE read_value
);
  DEFAULT_TYPE initial_memory [0:`MEMSIZE-1];
  initial $readmemb("test.mem", initial_memory);

  DEFAULT_TYPE memory [0:`MEMSIZE-1];
  assign read_value = memory[address];

  DEFAULT_TYPE next_memory [0:`MEMSIZE-1];
  always_comb begin
    if (rw_flag == MEMORY_WRITE) begin
      next_memory = {
        memory[0:address-`REGSIZE'd1],
        write_value,
        memory[address+`REGSIZE'd1:`MEMSIZE-1]
      };
    end else begin
      next_memory = memory;
    end
  end

  always_ff @(posedge CLOCK) begin
    if (RESET) begin
      memory <= initial_memory;
    end else begin
      memory <= next_memory;
    end
  end

endmodule
