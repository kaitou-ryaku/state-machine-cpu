`include "typedef_collection.sv"

module test_memory_unit();
  logic            CLOCK;
  logic            RESET;
  MEMORY_FLAG_TYPE rw_flag;
  DEFAULT_TYPE     address;
  DEFAULT_TYPE     write_memory_value;
  DEFAULT_TYPE     read_memory_value;

  memory_unit memory_unit0(.*);

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

    #20;
    $stop;
  end
endmodule

//module test_cpu();
//  logic CLOCK;
//  logic RESET;
//  logic [`REGSIZE-1:0] OUT;
//
//  cpu cpu_0(.*);
//
//  initial begin
//    CLOCK = 1'b0;
//    forever begin
//      #5;
//      CLOCK = ~ CLOCK;
//    end
//  end
//
//  initial begin
//
//    RESET = 1'b1;
//    # 5;
//    # 1;
//    RESET = 1'b0;
//
//    #8;
//
//    #20;
//    $stop;
//  end/*}}}*/
//
//endmodule

//module test_send();
//  logic CLK;
//  logic RESET;
//  logic [7:0] data = 8'b01100111;
//  logic flag;
//  logic UART_TX;
//  logic busy;
//
//  parameter wtime = 10;
//  send #(wtime) send0(.*);
//
//  always #5 CLK++;
//
//  initial begin
//    CLK   = 0;
//    RESET = 1;
//    flag  = 1;
//
//    #6;
//    RESET = 0;
//
//    #(4*wtime);
//    flag = 0;
//
//    #(200*wtime);
//    flag = 1;
//
//    #(800*wtime);
//    $stop;
//  end
//
//endmodule
