`include "typedef_collection.sv"

module cpu(/*{{{*/
  input logic CLOCK
  , input logic RESET
  , output DEFAULT_TYPE OUT
);

  DEFAULT_TYPE address, read_memory_value;
  MEMORY_FLAG_TYPE rw_flag;
  DEFAULT_TYPE write_memory_value, next_write_memory_value;
  memory_unit memory_unit0(.*);

  STATE_TYPE state, next_state;
  DEFAULT_TYPE ip, next_ip;

  DEFAULT_TYPE ope, next_ope;
  OPECODE_TYPE decode_ope;
  OPERAND_TYPE decode_src, decode_dst;
  decoder decoder0(.*);

  DEFAULT_TYPE a, next_a;
  DEFAULT_TYPE imm, next_imm;
  DEFAULT_TYPE imm_src, next_imm_src;
  DEFAULT_TYPE imm_dst, next_imm_dst;
  DEFAULT_TYPE memory_src, next_memory_src;
  DEFAULT_TYPE memory_dst, next_memory_dst;

  DEFAULT_TYPE src;
  decoder_src decoder_src0(.*);

  DEFAULT_TYPE original_dst, next_original_dst;
  decoder_dst decoder_dst0(.*);

  DEFAULT_TYPE dst, next_dst;

  alu alu0(.*);

  DEFAULT_TYPE jmp;
  jmp_address jmp_address0(.*);

  update_memory_address update_memory_address0(.*);
  update_memory_flag update_memory_flag0(.*);

  update_state update_state0(.*);
  update_execution_result update_execution_result0(.*);
  update_ip  update_ip0(.*);
  update_memory_src update_memory_src(.*);
  update_memory_dst update_memory_dst(.*);

  update_ope update_ope0(.*);
  update_imm update_imm0(.*);

  clock_posedge clock_posedge0(.*);

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
      `REGSIZE'b00??00??: decode_dst = REG_A;
      `REGSIZE'b00??01??: decode_dst = ADDRESS_REG_A;
      `REGSIZE'b00??10??: decode_dst = ADDRESS_IMM;
      `REGSIZE'b00??11??: decode_dst = IMM; // TODO
      default:            decode_dst = UNUSED;
    endcase

    unique casez (ope)
      `REGSIZE'b00????00: decode_src = REG_A;
      `REGSIZE'b00????01: decode_src = ADDRESS_REG_A;
      `REGSIZE'b00????10: decode_src = ADDRESS_IMM;
      `REGSIZE'b00????11: decode_src = IMM;
      `REGSIZE'b1100????: decode_src = IMM; // JMP
      default:            decode_src = UNUSED;
    endcase
  end

endmodule/*}}}*/

module decoder_src(/*{{{*/
  input OPERAND_TYPE decode_src
  , input DEFAULT_TYPE a
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE memory_src
  , output DEFAULT_TYPE src
);

  always_comb begin
    unique case (decode_src)
      REG_A:         src = a;
      ADDRESS_REG_A: src = memory_src;
      ADDRESS_IMM:   src = memory_src;
      IMM:           src = imm;
      default:       src = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module decoder_dst(/*{{{*/
  input OPERAND_TYPE decode_dst
  , input DEFAULT_TYPE a
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE memory_dst
  , output DEFAULT_TYPE next_original_dst
);

  always_comb begin
    unique case (decode_dst)
      REG_A:         next_original_dst = a;
      ADDRESS_REG_A: next_original_dst = memory_dst;
      ADDRESS_IMM:   next_original_dst = memory_dst;
      default:       next_original_dst = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module alu(/*{{{*/
  input STATE_TYPE state
  , input OPECODE_TYPE decode_ope
  , input  DEFAULT_TYPE src
  , input  DEFAULT_TYPE original_dst
  , output DEFAULT_TYPE next_dst
);

  always_comb begin
    unique case (state)
      EXECUTE: begin
        unique case (decode_ope)
          ADD:     next_dst = original_dst+src;
          MOV:     next_dst = src;
          HLT:     next_dst = original_dst;
          default: next_dst = original_dst;
        endcase
      end

      default: next_dst = original_dst;
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
  , input OPERAND_TYPE decode_src
  , input OPERAND_TYPE decode_dst
  , output STATE_TYPE next_state
);

  always_comb begin
    unique case (state)
      RESET_STATE: next_state = FETCH_OPERATION;

      FETCH_OPERATION: next_state = DECODE;

      DECODE: begin
        if      (decode_src == IMM)           next_state = FETCH_IMMEDIATE;
        else if (decode_src == ADDRESS_IMM)   next_state = FETCH_SRC_IMM;
        else if (decode_src == ADDRESS_REG_A) next_state = FETCH_SRC;
        else if (decode_dst == ADDRESS_IMM)   next_state = FETCH_DST_IMM;
        else if (decode_dst == ADDRESS_REG_A) next_state = FETCH_DST;
        else                                  next_state = EXECUTE;
      end

      FETCH_SRC_IMM: next_state = FETCH_SRC;

      FETCH_SRC, FETCH_IMMEDIATE: begin
        if      (decode_dst == ADDRESS_IMM)   next_state = FETCH_DST_IMM;
        else if (decode_dst == ADDRESS_REG_A) next_state = FETCH_DST;
        else                                  next_state = EXECUTE;
      end

      FETCH_DST_IMM: next_state = FETCH_DST;

      FETCH_DST: next_state = EXECUTE;

      EXECUTE: next_state = WRITE_REGISTER;

      WRITE_REGISTER: begin
        if (decode_dst == ADDRESS_IMM) next_state = WRITE_MEMORY;
        else                           next_state = FETCH_OPERATION;
      end

      WRITE_MEMORY: next_state = FETCH_OPERATION;

      default: next_state = FETCH_OPERATION;
    endcase
  end

endmodule/*}}}*/

module update_execution_result(/*{{{*/
  input STATE_TYPE state
  , input OPERAND_TYPE decode_dst
  , input  DEFAULT_TYPE dst
  , input  DEFAULT_TYPE a
  , output DEFAULT_TYPE next_a
  , output DEFAULT_TYPE next_write_memory_value
);

  always_comb begin
    if (state == WRITE_REGISTER) begin
      unique case (decode_dst)
        REG_A: begin
          next_a = dst;
          next_write_memory_value = `REGSIZE'b0;
        end

        ADDRESS_REG_A: begin
          next_a = a;
          next_write_memory_value = dst;
        end

        ADDRESS_IMM: begin
          next_a = a;
          next_write_memory_value = dst;
        end

        default: begin
          next_a = a;
          next_write_memory_value = `REGSIZE'b0;
        end
      endcase

    end else begin
      next_a = a;
      next_write_memory_value = `REGSIZE'b0;
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
        FETCH_SRC_IMM:   next_ip = ip + `REGSIZE'b1;
        FETCH_DST_IMM:   next_ip = ip + `REGSIZE'b1;
        EXECUTE:         next_ip = ip + jmp;
        default:         next_ip = ip;
      endcase
    end
  end
endmodule/*}}}*/

module update_ope(/*{{{*/
  input STATE_TYPE state
  , input  DEFAULT_TYPE ope
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
  , input  DEFAULT_TYPE imm_src
  , input  DEFAULT_TYPE imm_dst
  , output DEFAULT_TYPE next_imm
  , output DEFAULT_TYPE next_imm_src
  , output DEFAULT_TYPE next_imm_dst
);
  always_comb begin
    unique case (state)
      FETCH_IMMEDIATE: next_imm = read_memory_value;
      default:         next_imm = imm;
    endcase
  end

  always_comb begin
    unique case (state)
      FETCH_SRC_IMM: next_imm_src = read_memory_value;
      default:       next_imm_src = imm_src;
    endcase
  end

  always_comb begin
    unique case (state)
      FETCH_DST_IMM: next_imm_dst = read_memory_value;
      default:       next_imm_dst = imm_dst;
    endcase
  end
endmodule/*}}}*/

module update_memory_src(/*{{{*/
  input STATE_TYPE state
  , input  DEFAULT_TYPE read_memory_value
  , input  DEFAULT_TYPE memory_src
  , output DEFAULT_TYPE next_memory_src
);
  always_comb begin
    unique case (state)
      FETCH_SRC: next_memory_src = read_memory_value;
      default:   next_memory_src = memory_src;
    endcase
  end
endmodule/*}}}*/

module update_memory_dst(/*{{{*/
  input STATE_TYPE state
  , input  DEFAULT_TYPE read_memory_value
  , input  DEFAULT_TYPE memory_dst
  , output DEFAULT_TYPE next_memory_dst
);
  always_comb begin
    unique case (state)
      FETCH_DST: next_memory_dst = read_memory_value;
      default:   next_memory_dst = memory_dst;
    endcase
  end
endmodule/*}}}*/

module update_memory_address(/*{{{*/
  input    STATE_TYPE       state
  , input  DEFAULT_TYPE     ip
  , input  OPERAND_TYPE     decode_src
  , input  OPERAND_TYPE     decode_dst
  , input  DEFAULT_TYPE     imm_src
  , input  DEFAULT_TYPE     imm_dst
  , input  DEFAULT_TYPE     a
  , output DEFAULT_TYPE     address
);
  always_comb begin
    unique case (state)
      FETCH_OPERATION: address = ip;
      FETCH_IMMEDIATE: address = ip;
      FETCH_SRC_IMM:   address = ip;
      FETCH_DST_IMM:   address = ip;

      FETCH_SRC: unique case (decode_src)
        ADDRESS_REG_A: address = a;
        ADDRESS_IMM:   address = imm_src;
      endcase

      FETCH_DST: unique case (decode_dst)
        ADDRESS_REG_A: address = a;
        ADDRESS_IMM:   address = imm_dst;
      endcase

      WRITE_MEMORY: unique case (decode_dst)
        ADDRESS_REG_A: address = a;
        ADDRESS_IMM:   address = imm_dst;
      endcase

      default:         address = `REGSIZE'd0;
    endcase
  end
endmodule/*}}}*/

module update_memory_flag(/*{{{*/
  input    STATE_TYPE       state
  , output MEMORY_FLAG_TYPE rw_flag
);
  always_comb begin
    unique case (state)
      FETCH_OPERATION: rw_flag = MEMORY_READ;
      FETCH_IMMEDIATE: rw_flag = MEMORY_READ;
      FETCH_SRC_IMM:   rw_flag = MEMORY_READ;
      FETCH_SRC:       rw_flag = MEMORY_READ;
      FETCH_DST_IMM:   rw_flag = MEMORY_READ;
      FETCH_DST:       rw_flag = MEMORY_READ;
      WRITE_MEMORY:    rw_flag = MEMORY_WRITE;
      default:         rw_flag = MEMORY_STAY;
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
  , input  DEFAULT_TYPE next_imm_src
  , input  DEFAULT_TYPE next_imm_dst
  , input  DEFAULT_TYPE next_memory_src
  , input  DEFAULT_TYPE next_memory_dst
  , input  DEFAULT_TYPE next_a
  , input  DEFAULT_TYPE next_dst
  , input  DEFAULT_TYPE next_original_dst
  , input  DEFAULT_TYPE next_write_memory_value

  , output STATE_TYPE   state
  , output DEFAULT_TYPE ip
  , output DEFAULT_TYPE ope
  , output DEFAULT_TYPE imm
  , output DEFAULT_TYPE imm_src
  , output DEFAULT_TYPE imm_dst
  , output DEFAULT_TYPE memory_src
  , output DEFAULT_TYPE memory_dst
  , output DEFAULT_TYPE a
  , output DEFAULT_TYPE dst
  , output DEFAULT_TYPE original_dst
  , output DEFAULT_TYPE write_memory_value

);
  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      state        <= RESET_STATE;
      ip           <= `REGSIZE'b0;
      ope          <= `REGSIZE'b0;
      imm          <= `REGSIZE'b0;
      imm_src      <= `REGSIZE'b0;
      imm_dst      <= `REGSIZE'b0;
      memory_src   <= `REGSIZE'b0;
      memory_dst   <= `REGSIZE'b0;
      a            <= `REGSIZE'b0;
      dst          <= `REGSIZE'b0;
      original_dst <= `REGSIZE'b0;
      write_memory_value <= `REGSIZE'b0;

    end else begin
      state        <= next_state;
      ip           <= next_ip;
      ope          <= next_ope;
      imm          <= next_imm;
      imm_src      <= next_imm_src;
      imm_dst      <= next_imm_dst;
      memory_src   <= next_memory_src;
      memory_dst   <= next_memory_dst;
      a            <= next_a;
      dst          <= next_dst;
      original_dst <= next_original_dst;
      write_memory_value <= next_write_memory_value;
    end
  end
endmodule/*}}}*/
