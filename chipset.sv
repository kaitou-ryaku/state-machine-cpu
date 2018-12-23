`include "typedef_collection.sv"

typedef enum logic [1:0] {CHIPSET_RESET, CHIPSET_LOAD_ROM, CHIPSET_EXEC_CPU} CHIPSET_STATE_TYPE;

module chipset(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , output DEFAULT_TYPE OUT
);

  logic            cpu_reset;
  DEFAULT_TYPE     cpu_read_bus;
  DEFAULT_TYPE     cpu_write_bus;
  DEFAULT_TYPE     cpu_addr_bus;
  MEMORY_FLAG_TYPE cpu_ctrl_bus;
  cpu cpu0(.*,
    .RESET(cpu_reset),
    .read_bus(cpu_read_bus),
    .write_bus(cpu_write_bus),
    .addr_bus(cpu_addr_bus),
    .ctrl_bus(cpu_ctrl_bus)
  );

  DEFAULT_TYPE     mem_read_bus;
  DEFAULT_TYPE     mem_write_bus;
  DEFAULT_TYPE     mem_addr_bus;
  MEMORY_FLAG_TYPE mem_ctrl_bus;
  memory_unit memory_unit0(.*,
    .read_bus(mem_read_bus),
    .write_bus(mem_write_bus),
    .addr_bus(mem_addr_bus),
    .ctrl_bus(mem_ctrl_bus)
  );

  DEFAULT_TYPE rom_read_bus;
  DEFAULT_TYPE rom_addr_bus;
  rom_unit rom_unit0(.*,
    .read_bus(rom_read_bus),
    .addr_bus(rom_addr_bus)
  );

  CHIPSET_STATE_TYPE chipset_state;
  load_rom_addr load_rom_addr0(.*);

  always_ff @(posedge CLOCK) begin
    unique case (chipset_state)
      CHIPSET_RESET:    cpu_reset <= 1'b1;
      CHIPSET_LOAD_ROM: cpu_reset <= 1'b1;
      CHIPSET_EXEC_CPU: cpu_reset <= 1'b0;
    endcase
  end

  assign cpu_read_bus = mem_read_bus;
  always_comb begin
    unique case (chipset_state)
    CHIPSET_RESET, CHIPSET_LOAD_ROM: begin
      mem_write_bus = rom_read_bus;
      mem_addr_bus  = rom_addr_bus;
      mem_ctrl_bus  = MEMORY_WRITE;
    end

    CHIPSET_EXEC_CPU: begin
      mem_write_bus = cpu_write_bus;
      mem_addr_bus  = cpu_addr_bus;
      mem_ctrl_bus  = cpu_ctrl_bus;
    end
    endcase
  end

endmodule/*}}}*/

module load_rom_addr(/*{{{*/
  input    logic              CLOCK
  , input  logic              RESET
  , output CHIPSET_STATE_TYPE chipset_state
  , output DEFAULT_TYPE       rom_addr_bus
);

  CHIPSET_STATE_TYPE next_chipset_state;
  DEFAULT_TYPE next_rom_addr_bus;

  always_comb begin
    unique case (chipset_state)
      CHIPSET_RESET: next_chipset_state = CHIPSET_LOAD_ROM;
      CHIPSET_LOAD_ROM: begin
        unique if (rom_addr_bus < `ROMSIZE)
          next_chipset_state = CHIPSET_LOAD_ROM;
        else
          next_chipset_state = CHIPSET_EXEC_CPU;
      end
      CHIPSET_EXEC_CPU: next_chipset_state = CHIPSET_EXEC_CPU;
    endcase
  end

  always_comb begin
    unique if ((chipset_state == CHIPSET_LOAD_ROM) & (rom_addr_bus < `ROMSIZE))
      next_rom_addr_bus = rom_addr_bus + `REGSIZE'd1;
    else
      next_rom_addr_bus = rom_addr_bus;
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      chipset_state <= CHIPSET_RESET;
      rom_addr_bus <= 0;
    end else begin
      chipset_state <= next_chipset_state;
      rom_addr_bus <= next_rom_addr_bus;
    end
  end
endmodule/*}}}*/
