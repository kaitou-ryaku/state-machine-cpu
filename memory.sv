`define MEMSIZE 16
`define REGSIZE 8

module memory_unit(
  input logic [`REGSIZE-1:0] address
  , output logic [`REGSIZE-1:0] value
);
  logic [`REGSIZE-1:0] memory [0:`MEMSIZE-1];
  assign value = memory[address];

  initial begin
    $readmemb("test.mem", memory);
  end

endmodule
