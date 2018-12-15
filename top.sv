`define MEMSIZE 16
`define REGSIZE 8
`define PAR_CLOCK 10_000_000

module top(input logic CLK, input logic BUTTON, output logic [`REGSIZE-1:0] OUTPUT);

  logic [31:0] counter;
  logic CLOCK;
  assign CLOCK = (counter < `PAR_CLOCK/2) ? 1'b0 : 1'b1;

  logic [31:0] next_counter;
  always_comb begin
    priority if (BUTTON == 1'b0)   next_counter = 32'b0;
    else if (counter < `PAR_CLOCK) next_counter = counter + 32'b1;
    else                           next_counter = 32'b0;
  end

  always @(posedge CLK) begin
    counter <= next_counter;
  end

  logic [`REGSIZE-1:0] OUT;
  assign OUTPUT[0] = (counter % 100 == 0) ? OUT[0] : 1'b0;
  assign OUTPUT[1] = (counter % 100 == 0) ? OUT[1] : 1'b0;
  assign OUTPUT[2] = (counter % 100 == 0) ? OUT[2] : 1'b0;
  assign OUTPUT[3] = (counter % 100 == 0) ? OUT[3] : 1'b0;
  assign OUTPUT[4] = (counter % 2   == 0) ? OUT[4] : 1'b0;
  assign OUTPUT[5] = (counter % 2   == 0) ? OUT[5] : 1'b0;
  assign OUTPUT[6] = (counter % 2   == 0) ? OUT[6] : 1'b0;
  assign OUTPUT[7] = (counter % 2   == 0) ? CLOCK  : 1'b0;

  logic RESET;
  assign RESET = BUTTON;
  cpu cpu_0(.*);

endmodule
