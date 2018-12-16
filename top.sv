`define MEMSIZE 16
`define REGSIZE 8
`define CLOCK_HZ 100_000_000

module top(
  input    logic                PHYSICAL_CLOCK
  , input  logic                PHYSICAL_BUTTON
  , input  logic [4-1:0]        PHYSICAL_SWITCH
  , input  logic                PHYSICAL_RESET
  , output logic [`REGSIZE-1:0] PHYSICAL_LED
  , output logic                PHYSICAL_LED_RESET
  , output logic                PHYSICAL_LED_CLOCK
);

  logic [31:0] PAR_CLOCK;
  assign PAR_CLOCK = `CLOCK_HZ / (32'h2 ** PHYSICAL_SWITCH);

  logic CLOCK;
  logic [31:0] counter;

  assign CLOCK = (counter < PAR_CLOCK / 32'h2) ? 1'b0 : 1'b1;

  logic [31:0] next_counter;
  assign next_counter = (counter < PAR_CLOCK) ? counter+32'b1 : 32'b0;

  always @(posedge PHYSICAL_CLOCK) begin
    counter <= next_counter;
  end

  logic [`REGSIZE-1:0] OUT;

  logic RESET;
  assign RESET = ~PHYSICAL_RESET;

  cpu cpu_0(.*);

  assign PHYSICAL_LED[0]    = (counter % 32'd100 == 32'd0) ? OUT[0] : 1'b0;
  assign PHYSICAL_LED[1]    = (counter % 32'd100 == 32'd0) ? OUT[1] : 1'b0;
  assign PHYSICAL_LED[2]    = (counter % 32'd100 == 32'd0) ? OUT[2] : 1'b0;
  assign PHYSICAL_LED[3]    = (counter % 32'd100 == 32'd0) ? OUT[3] : 1'b0;
  assign PHYSICAL_LED[4]    = (counter % 32'd2   == 32'd0) ? OUT[4] : 1'b0;
  assign PHYSICAL_LED[5]    = (counter % 32'd2   == 32'd0) ? OUT[5] : 1'b0;
  assign PHYSICAL_LED[6]    = (counter % 32'd2   == 32'd0) ? OUT[6] : 1'b0;
  assign PHYSICAL_LED[7]    = (counter % 32'd2   == 32'd0) ? OUT[7] : 1'b0;
  assign PHYSICAL_LED_CLOCK = (counter % 32'd100 == 32'd0) ? CLOCK  : 1'b0;
  assign PHYSICAL_LED_RESET = (counter % 32'd100 == 32'd0) ? RESET  : 1'b0;

endmodule
