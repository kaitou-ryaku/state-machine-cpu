`include "typedef_collection.sv"

module cpu(/*{{{*/
  input logic CLOCK
  , input logic RESET
  , output DEFAULT_TYPE OUT
);

  DEFAULT_TYPE address, read_memory_value;
  MEMORY_FLAG_TYPE rw_flag, next_rw_flag;
  DEFAULT_TYPE write_memory_value, next_write_memory_value;
  memory_unit memory_unit0(.*);

  STATE_TYPE state, next_state;
  DEFAULT_TYPE ip, next_ip;
  update_memory_parameter update_memory_parameter0(.*);

  DEFAULT_TYPE ope, next_ope;
  OPECODE_TYPE decode_ope;
  OPERAND_TYPE decode_src;
  OPERAND_TYPE decode_dst;
  decoder decoder0(.*);

  DEFAULT_TYPE a, next_a;
  DEFAULT_TYPE b, next_b;
  DEFAULT_TYPE c, next_c;

  DEFAULT_TYPE imm, next_imm;

  DEFAULT_TYPE src;
  decoder_src decoder_src0(.*);

  DEFAULT_TYPE current_dst;
  decoder_src decoder_src1(decode_dst, a, b, c, imm, current_dst);

  DEFAULT_TYPE dst;
  alu alu0(.*);

  DEFAULT_TYPE jmp;
  jmp_address jmp_address0(.*);

  update_state update_state0(.*);
  update_reg update_reg0(.*);
  update_ip  update_ip0(.*);
  update_ope update_ope0(.*);
  update_imm update_imm0(.*);

  clock_posedge clock_posedge0(.*);
  clock_posedge_memory_parameter clock_posedge_memory_parameter0(.*);

  assign OUT = a;

endmodule/*}}}*/

module decoder(/*{{{*/
  input DEFAULT_TYPE ope
  , output OPECODE_TYPE decode_ope
  , output OPERAND_TYPE decode_src
  , output OPERAND_TYPE decode_dst
);

  always_comb begin
    unique casez (ope)
      `REGSIZE'b0000????: decode_ope = MOV;
      `REGSIZE'b0001????: decode_ope = ADD;
      `REGSIZE'b1100????: decode_ope = JMP;
      `REGSIZE'b1111????: decode_ope = HLT;
      default:            decode_ope = HLT;
    endcase

    unique casez (ope)
      `REGSIZE'b????00??: decode_dst = REG_A;
      `REGSIZE'b????01??: decode_dst = REG_B;
      `REGSIZE'b????10??: decode_dst = REG_C;
      `REGSIZE'b????11??: decode_dst = IMM;
    endcase

    unique casez (ope)
      `REGSIZE'b??????00: decode_src = REG_A;
      `REGSIZE'b??????01: decode_src = REG_B;
      `REGSIZE'b??????10: decode_src = REG_C;
      `REGSIZE'b??????11: decode_src = IMM;
    endcase
  end

endmodule/*}}}*/

module decoder_src(/*{{{*/
  input OPERAND_TYPE decode_src
  , input DEFAULT_TYPE a
  , input DEFAULT_TYPE b
  , input DEFAULT_TYPE c
  , input DEFAULT_TYPE imm
  , output DEFAULT_TYPE src
);

  always_comb begin
    unique case (decode_src)
      REG_A: src = a;
      REG_B: src = b;
      REG_C: src = c;
      IMM  : src = imm;
    endcase
  end

endmodule/*}}}*/

module alu(/*{{{*/
  input OPECODE_TYPE decode_ope
  , input  DEFAULT_TYPE src
  , input  DEFAULT_TYPE current_dst
  , output DEFAULT_TYPE dst
);

  always_comb begin
    unique case (decode_ope)
      ADD:     dst = current_dst+src;
      MOV:     dst = src;
      HLT:     dst = current_dst;
      default: dst = current_dst;
    endcase
  end

endmodule/*}}}*/

module jmp_address(/*{{{*/
  input OPECODE_TYPE decode_ope
  , input DEFAULT_TYPE imm
  , output DEFAULT_TYPE jmp
);

  always_comb begin
    unique case (decode_ope)
      JMP:     jmp = imm;
      default: jmp = `REGSIZE'b0;
    endcase
  end

endmodule/*}}}*/

module update_state(/*{{{*/
  input STATE_TYPE state
  , input OPECODE_TYPE decode_ope
  , input OPERAND_TYPE decode_src
  , output STATE_TYPE next_state
);

  always_comb begin
    unique case (state)
      FETCH_OPERATION: next_state = COPY_OPERATION;
      COPY_OPERATION:  next_state = DECODE;

      DECODE: begin
        if      (decode_ope == JMP) next_state = FETCH_IMMEDIATE;
        else if (decode_src == IMM) next_state = FETCH_IMMEDIATE;
        else                        next_state = EXECUTE;
      end

      FETCH_IMMEDIATE: next_state = COPY_IMMEDIATE;
      COPY_IMMEDIATE : next_state = EXECUTE;
      EXECUTE:         next_state = WRITE;
      WRITE:           next_state = FETCH_OPERATION;
      default:         next_state = FETCH_OPERATION;
    endcase
  end

endmodule/*}}}*/

module update_reg(/*{{{*/
  input STATE_TYPE state
  , input OPERAND_TYPE decode_dst
  , input  DEFAULT_TYPE dst

  , input  DEFAULT_TYPE a
  , input  DEFAULT_TYPE b
  , input  DEFAULT_TYPE c

  , output DEFAULT_TYPE next_a
  , output DEFAULT_TYPE next_b
  , output DEFAULT_TYPE next_c
);

  always_comb begin
    if (state == EXECUTE) begin
      unique case (decode_dst)
        REG_A: begin
          next_a = dst;
          next_b = b;
          next_c = c;
        end

        REG_B: begin
          next_a = a;
          next_b = dst;
          next_c = c;
        end

        REG_C: begin
          next_a = a;
          next_b = b;
          next_c = dst;
        end

        default: begin
          next_a = a;
          next_b = b;
          next_c = c;
        end
      endcase

    end else begin
      next_a = a;
      next_b = b;
      next_c = c;
    end
  end

endmodule/*}}}*/

module update_ip(/*{{{*/
  input STATE_TYPE state
  , input DEFAULT_TYPE ip
  , input OPECODE_TYPE decode_ope
  , input DEFAULT_TYPE jmp
  , output DEFAULT_TYPE next_ip
);
  always_comb begin
    unique if (decode_ope == HLT) begin
      next_ip = ip;

    end else begin
      unique case (state)
        FETCH_OPERATION: next_ip = ip + `REGSIZE'b1;
        FETCH_IMMEDIATE: next_ip = ip + `REGSIZE'b1;
        EXECUTE:         next_ip = ip + jmp;
        default:         next_ip = ip;
      endcase
    end
  end
endmodule/*}}}*/

module update_ope(/*{{{*/
  input STATE_TYPE state
  , input  DEFAULT_TYPE ope
  , input  DEFAULT_TYPE ip
  , input  DEFAULT_TYPE read_memory_value
  , output DEFAULT_TYPE next_ope
);
  always_comb begin
    unique case (state)
      FETCH_OPERATION: next_ope = read_memory_value;
      default:         next_ope = ope;
    endcase
  end
endmodule/*}}}*/

module update_imm(/*{{{*/
  input STATE_TYPE state
  , input  DEFAULT_TYPE read_memory_value
  , input  DEFAULT_TYPE imm
  , output DEFAULT_TYPE next_imm
);
  always_comb begin
    unique case (state)
      FETCH_IMMEDIATE: next_imm = read_memory_value;
      default:         next_imm = imm;
    endcase
  end
endmodule/*}}}*/

module update_memory_parameter(/*{{{*/
  input    STATE_TYPE       state
  , input  DEFAULT_TYPE     ip
  , input  DEFAULT_TYPE     write_memory_value
  , input  MEMORY_FLAG_TYPE rw_flag
  , output DEFAULT_TYPE     next_write_memory_value
  , output MEMORY_FLAG_TYPE next_rw_flag
  , output DEFAULT_TYPE     address
);
  always_comb begin
    unique case (state)
      FETCH_OPERATION: begin
        address                 = ip;
        next_write_memory_value = write_memory_value;
        next_rw_flag            = MEMORY_READ;
      end

      FETCH_IMMEDIATE: begin
        address                 = ip;
        next_write_memory_value = write_memory_value;
        next_rw_flag            = MEMORY_READ;
      end

      default: begin
        address                 = `REGSIZE'd0;
        next_write_memory_value = write_memory_value;
        next_rw_flag            = MEMORY_STAY;
      end
    endcase
  end
endmodule/*}}}*/

module clock_posedge(/*{{{*/
  input logic CLOCK
  , input logic RESET

  , input  STATE_TYPE   next_state
  , input  DEFAULT_TYPE next_ip
  , input  DEFAULT_TYPE next_ope
  , input  DEFAULT_TYPE next_imm
  , input  DEFAULT_TYPE next_a
  , input  DEFAULT_TYPE next_b
  , input  DEFAULT_TYPE next_c

  , output STATE_TYPE   state
  , output DEFAULT_TYPE ip
  , output DEFAULT_TYPE ope
  , output DEFAULT_TYPE imm
  , output DEFAULT_TYPE a
  , output DEFAULT_TYPE b
  , output DEFAULT_TYPE c

);
  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      state <= FETCH_OPERATION;
      ip    <= `REGSIZE'b0;
      ope   <= `REGSIZE'b0;
      imm   <= `REGSIZE'b0;
      a     <= `REGSIZE'b0;
      b     <= `REGSIZE'b0;
      c     <= `REGSIZE'b0;

    end else begin
      state <= next_state;
      ip    <= next_ip;
      ope   <= next_ope;
      imm   <= next_imm;
      a     <= next_a;
      b     <= next_b;
      c     <= next_c;
    end
  end
endmodule/*}}}*/

module clock_posedge_memory_parameter(/*{{{*/
  input logic CLOCK
  , input logic RESET

  , input  DEFAULT_TYPE     next_write_memory_value
  , input  MEMORY_FLAG_TYPE next_rw_flag

  , output DEFAULT_TYPE     write_memory_value
  , output MEMORY_FLAG_TYPE rw_flag
);
  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      write_memory_value = `REGSIZE'b0;
      rw_flag            = MEMORY_STAY;

    end else begin
      write_memory_value = next_write_memory_value;
      rw_flag            = next_rw_flag;
    end
  end
endmodule/*}}}*/
