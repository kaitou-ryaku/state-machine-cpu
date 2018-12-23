`include "typedef_collection.sv"

//module test_memory_unit();
//  logic            CLOCK;
//  logic            RESET;
//  MEMORY_FLAG_TYPE ctrl_bus;
//  DEFAULT_TYPE     addr_bus;
//  DEFAULT_TYPE     write_bus;
//  DEFAULT_TYPE     read_bus;
//
//  memory_unit memory_unit0(.*);
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
//  end
//endmodule

module test_cpu();
  logic CLOCK, RESET;
  logic [`REGSIZE-1:0] OUT;
  DEFAULT_TYPE addr_bus, read_bus, write_bus;
  MEMORY_FLAG_TYPE ctrl_bus;

  memory_unit memory_unit0(.*);
  cpu cpu_0(.*);

  always #5 CLOCK++;

  initial begin

    CLOCK = 1'b0;
    RESET = 1'b1;
    # 5;
    # 1;
    RESET = 1'b0;

    #8;

    #20;
    $stop;
  end

endmodule

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
