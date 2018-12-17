module send #(parameter logic[31:0] wtime = 32'h28B0) (
  input    logic CLK
  , input  logic RESET
  , input  logic [7:0] data
  , input  logic flag // ready:0 send:1
  , output logic UART_TX
  , output logic busy // ready:0 send:1
);

  logic [31:0] clk_count, next_clk_count;
  logic [9:0] buff, next_buff;

  logic [4:0] buf_count, next_buf_count;
  assign UART_TX = buff[buf_count];

  logic buf_flag, clk_flag;
  assign buf_flag = (buf_count < 4'd9);
  assign clk_flag = (clk_count < wtime);

  logic next_busy;

  always_comb begin
    if (busy & clk_flag) next_clk_count = clk_count+1;
    else                 next_clk_count = 0;
  end

  always_comb begin
    if      (~busy & flag)          next_buff = {1'b1, data, 1'b0};
    else if (~busy)                 next_buff = {1'b1, 8'b11111111, 1'b0};
    else if (~buf_flag & ~clk_flag) next_buff = {1'b1, 8'b11111111, 1'b0};
    else                            next_buff = buff;
  end

  always_comb begin
    if      (~busy & flag)     next_buf_count = 4'd0;
    else if ( busy & clk_flag) next_buf_count = buf_count;
    else if ( busy & buf_flag) next_buf_count = buf_count+4'd1;
    else                       next_buf_count = 4'd9;
  end

  always_comb begin
    if      (~busy & ~flag)                 next_busy = 1'b0;
    else if ( busy & ~buf_flag & ~clk_flag) next_busy = 1'b0;
    else                                    next_busy = 1'b1;
  end

  always_ff @(posedge CLK) begin
    if (RESET) begin
      busy      <= 1'b0;
      buff      <= {1'b1, 8'b11111111, 1'b0};
      clk_count <= 0;
      buf_count <= 4'd9;
    end else begin
      busy      <= next_busy;
      buff      <= next_buff;
      clk_count <= next_clk_count;
      buf_count <= next_buf_count;
    end
  end

endmodule
