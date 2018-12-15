module test();
  logic CLOCK;
  logic RESET;
  logic [`REGSIZE-1:0] OUT;

  cpu cpu_0(.*);

  initial begin
    CLOCK = 1'b0;
    forever begin
      #5;
      CLOCK = ~ CLOCK;
    end
  end

  initial begin

    RESET = 1'b1;
    # 5;
    # 1;
    RESET = 1'b0;

    #8;

    #400;
    $stop;
  end/*}}}*/

endmodule
