`define MEMSIZE 16
`define REGSIZE 8
`define CLOCK_HZ 100_000_000

module top(/*{{{*/
  input    logic                PHYSICAL_CLOCK
  , input  logic                PHYSICAL_BUTTON
  , input  logic [3:0]          PHYSICAL_SWITCH
  , input  logic                PHYSICAL_RESET
  , input  logic                PHYSICAL_UART_RX
  , output logic [`REGSIZE-1:0] PHYSICAL_LED
  , output logic                PHYSICAL_LED_RESET
  , output logic                PHYSICAL_LED_CLOCK
  , output logic                PHYSICAL_UART_TX
);
  logic CLOCK;
  logic [31:0] counter;

  clock_reducer clock_reducer0(
    .counter(counter)
    , .QUICK_CLOCK(PHYSICAL_CLOCK)
    , .SWITCH(PHYSICAL_SWITCH)
    , .SLOW_CLOCK(CLOCK)
  );

  logic RESET;
  assign RESET = ~PHYSICAL_RESET;
  logic [`REGSIZE-1:0] OUT;

  cpu cpu_0(.*);

  send #(32'h28B0) sender (
    .UART_TX(PHYSICAL_UART_TX),
    .CLK(PHYSICAL_CLOCK),
    .RESET(RESET),
    .data(OUT)
  );

  light_dimmer light_dimmer0(
    .counter(counter)
    , .OUT(OUT)
    , .RESET(RESET)
    , .CLOCK(CLOCK)
    , .LED(PHYSICAL_LED)
    , .LED_RESET(PHYSICAL_LED_RESET)
    , .LED_CLOCK(PHYSICAL_LED_CLOCK)
  );
endmodule/*}}}*/

module clock_reducer(/*{{{*/
  input    logic QUICK_CLOCK
  , input  logic [3:0] SWITCH
  , output logic SLOW_CLOCK
  , output logic [31:0] counter
);
  logic [31:0] PAR_CLOCK;
  assign PAR_CLOCK = `CLOCK_HZ / (32'h2 ** SWITCH);

  assign SLOW_CLOCK = (counter < PAR_CLOCK / 32'h2) ? 1'b0 : 1'b1;

  logic [31:0] next_counter;
  assign next_counter = (counter < PAR_CLOCK) ? counter + 32'b1 : 32'b0;

  always @(posedge QUICK_CLOCK) counter <= next_counter;
endmodule/*}}}*/

module light_dimmer(/*{{{*/
  input    logic [`REGSIZE-1:0] OUT
  , input  logic                RESET
  , input  logic                CLOCK
  , input  logic [31:0]         counter
  , output logic [`REGSIZE-1:0] LED
  , output logic                LED_RESET
  , output logic                LED_CLOCK
);
  logic [4-1:0] LED1;
  logic [4-1:0] LED2;
  assign LED1 = &(counter[6:0]) ? OUT[3:0] : 1'b0;
  assign LED2 = &(counter[1:0]) ? OUT[7:4] : 1'b0;
  assign LED = {LED2, LED1};

  assign LED_CLOCK = &(counter[6:0]) ? CLOCK : 1'b0;
  assign LED_RESET = &(counter[1:0]) ? RESET : 1'b0;
endmodule/*}}}*/

module send #(parameter logic[31:0] wtime = 32'h28B0) (/*{{{*/
  output logic UART_TX,
  input logic CLK,
  input logic RESET,
  input logic [7:0] data
);

  logic [31:0] ct;
  logic tx;
  assign UART_TX = tx;
  logic [9:0] buff;
  assign buff = {1'b1, data, 1'b0};

  always_ff @(posedge CLK) begin
    if (RESET) begin
      ct <= 0;
      tx <= 1'b1;
    end else begin
      if      (ct < wtime*10) ct <= ct + 1;
      else                    ct <= 0;

      if      (ct < wtime*1 ) tx <= buff[0];
      else if (ct < wtime*2 ) tx <= buff[1];
      else if (ct < wtime*3 ) tx <= buff[2];
      else if (ct < wtime*4 ) tx <= buff[3];
      else if (ct < wtime*5 ) tx <= buff[4];
      else if (ct < wtime*6 ) tx <= buff[5];
      else if (ct < wtime*7 ) tx <= buff[6];
      else if (ct < wtime*8 ) tx <= buff[7];
      else if (ct < wtime*9 ) tx <= buff[8];
      else if (ct < wtime*10) tx <= buff[9];
      else                    tx <= 1'b1;
    end
  end

endmodule/*}}}*/
