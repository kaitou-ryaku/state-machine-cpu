`include "typedef_collection.sv"

module cpu(/*{{{*/
  input logic CLOCK
  , input logic RESET
  , input  DEFAULT_TYPE     read_bus
  , output MEMORY_FLAG_TYPE ctrl_bus
  , output DEFAULT_TYPE     addr_bus
  , output DEFAULT_TYPE     write_bus
  , output DEFAULT_TYPE     OUT
);
  DEFAULT_TYPE next_write_bus;
  STAGE_TYPE stage, next_stage;

  STAGE_FETCH_OPERATION_TYPE stage_fetch_operation;
  //STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate;

  DEFAULT_TYPE ip, next_ip;

  DEFAULT_TYPE ope;
  OPECODE_TYPE decode_ope;
  OPERAND_TYPE decode_src, decode_dst;
  decoder decoder0(.*);

  DEFAULT_TYPE register_a, next_register_a;
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
  jmp_addr_bus jmp_addr_bus0(.*);

  update_memory_addr_bus update_memory_addr_bus0(.*);
  update_memory_flag update_memory_flag0(.*);

  update_stage update_stage0(.*);
  update_execution_result update_execution_result0(.*);
  update_memory_src update_memory_src(.*);
  update_memory_dst update_memory_dst(.*);

  DEFAULT_TYPE next_ip_operation;
  update_stage_fetch_operation update_stage_fetch_operation0(.*, .next_ip(next_ip_operation));
  update_ip  update_ip0(.*);

  update_imm update_imm0(.*);

  clock_posedge clock_posedge0(.*);

  assign OUT = register_a;
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
      `REGSIZE'b11111110: decode_ope = NOP;
      `REGSIZE'b11111111: decode_ope = HLT;
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
  , input DEFAULT_TYPE register_a
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE memory_src
  , output DEFAULT_TYPE src
);

  always_comb begin
    unique case (decode_src)
      REG_A:         src = register_a;
      ADDRESS_REG_A: src = memory_src;
      ADDRESS_IMM:   src = memory_src;
      IMM:           src = imm;
      default:       src = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module decoder_dst(/*{{{*/
  input OPERAND_TYPE decode_dst
  , input DEFAULT_TYPE register_a
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE memory_dst
  , output DEFAULT_TYPE next_original_dst
);

  always_comb begin
    unique case (decode_dst)
      REG_A:         next_original_dst = register_a;
      ADDRESS_REG_A: next_original_dst = memory_dst;
      ADDRESS_IMM:   next_original_dst = memory_dst;
      default:       next_original_dst = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module alu(/*{{{*/
  input STAGE_TYPE stage
  , input OPECODE_TYPE decode_ope
  , input  DEFAULT_TYPE src
  , input  DEFAULT_TYPE original_dst
  , output DEFAULT_TYPE next_dst
);

  always_comb begin
    unique case (stage)
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

module jmp_addr_bus(/*{{{*/
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

module update_stage(/*{{{*/
  input STAGE_TYPE stage
  , input STAGE_FETCH_OPERATION_TYPE stage_fetch_operation
  , input STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate
  , input OPERAND_TYPE decode_src
  , input OPERAND_TYPE decode_dst
  , output STAGE_TYPE next_stage
);

  always_comb begin
    unique case (stage)
      RESET_STAGE: next_stage = FETCH_OPERATION;

      FETCH_OPERATION: unique case (stage_fetch_operation)
        END_FETCH_OPERATION: next_stage = DECODE;
        default:             next_stage = FETCH_OPERATION;
      endcase

      DECODE: next_stage = FETCH_IMMEDIATE:

      FETCH_IMMEDIATE: unique case (stage_fetch_immediate)
        END_FETCH_IMMEDIATE: next_stage = EXECUTE;
        default:             next_stage = FETCH_IMMEDIATE;
      endcase

      EXECUTE: next_stage = WRITE_REGISTER;

      WRITE_REGISTER: unique case (decode_dst)
        ADDRESS_IMM: next_stage = WRITE_MEMORY;
        default:     next_stage = FETCH_OPERATION;
      endcase

      WRITE_MEMORY: next_stage = FETCH_OPERATION;

      default: next_stage = FETCH_OPERATION;
    endcase
  end

endmodule/*}}}*/

module update_execution_result(/*{{{*/
  input STAGE_TYPE stage
  , input OPERAND_TYPE decode_dst
  , input  DEFAULT_TYPE dst
  , input  DEFAULT_TYPE register_a
  , output DEFAULT_TYPE next_register_a
  , output DEFAULT_TYPE next_write_bus
);

  always_comb begin
    if (stage == WRITE_REGISTER) begin
      unique case (decode_dst)
        REG_A: begin
          next_register_a = dst;
          next_write_bus = `REGSIZE'b0;
        end

        ADDRESS_REG_A: begin
          next_register_a = register_a;
          next_write_bus = dst;
        end

        ADDRESS_IMM: begin
          next_register_a = register_a;
          next_write_bus = dst;
        end

        default: begin
          next_register_a = register_a;
          next_write_bus = `REGSIZE'b0;
        end
      endcase

    end else begin
      next_register_a = register_a;
      next_write_bus = `REGSIZE'b0;
    end
  end

endmodule/*}}}*/

module update_ip(/*{{{*/
  input STAGE_TYPE stage
  , input DEFAULT_TYPE ip
  , input OPECODE_TYPE decode_ope
  , input DEFAULT_TYPE next_ip_operation
  , input DEFAULT_TYPE jmp
  , output DEFAULT_TYPE next_ip
);
  always_comb begin
    unique if (decode_ope == HLT) begin
      next_ip = ip;

    end else begin
      unique case (stage)
        FETCH_OPERATION: next_ip = next_ip_operation;
        FETCH_IMMEDIATE: next_ip = ip + `REGSIZE'b1;
        FETCH_SRC_IMM:   next_ip = ip + `REGSIZE'b1;
        FETCH_DST_IMM:   next_ip = ip + `REGSIZE'b1;
        EXECUTE:         next_ip = ip + jmp;
        default:         next_ip = ip;
      endcase
    end
  end
endmodule/*}}}*/

module update_imm(/*{{{*/
  input STAGE_TYPE stage
  , input  DEFAULT_TYPE read_bus
  , input  DEFAULT_TYPE imm
  , input  DEFAULT_TYPE imm_src
  , input  DEFAULT_TYPE imm_dst
  , output DEFAULT_TYPE next_imm
  , output DEFAULT_TYPE next_imm_src
  , output DEFAULT_TYPE next_imm_dst
);
  always_comb begin
    unique case (stage)
      FETCH_IMMEDIATE: next_imm = read_bus;
      default:         next_imm = imm;
    endcase
  end

  always_comb begin
    unique case (stage)
      FETCH_SRC_IMM: next_imm_src = read_bus;
      default:       next_imm_src = imm_src;
    endcase
  end

  always_comb begin
    unique case (stage)
      FETCH_DST_IMM: next_imm_dst = read_bus;
      default:       next_imm_dst = imm_dst;
    endcase
  end
endmodule/*}}}*/

module update_memory_src(/*{{{*/
  input STAGE_TYPE stage
  , input  DEFAULT_TYPE read_bus
  , input  DEFAULT_TYPE memory_src
  , output DEFAULT_TYPE next_memory_src
);
  always_comb begin
    unique case (stage)
      FETCH_SRC: next_memory_src = read_bus;
      default:   next_memory_src = memory_src;
    endcase
  end
endmodule/*}}}*/

module update_memory_dst(/*{{{*/
  input STAGE_TYPE stage
  , input  DEFAULT_TYPE read_bus
  , input  DEFAULT_TYPE memory_dst
  , output DEFAULT_TYPE next_memory_dst
);
  always_comb begin
    unique case (stage)
      FETCH_DST: next_memory_dst = read_bus;
      default:   next_memory_dst = memory_dst;
    endcase
  end
endmodule/*}}}*/

module update_memory_addr_bus(/*{{{*/
  input    STAGE_TYPE       stage
  , input  DEFAULT_TYPE     ip
  , input  OPERAND_TYPE     decode_src
  , input  OPERAND_TYPE     decode_dst
  , input  DEFAULT_TYPE     imm_src
  , input  DEFAULT_TYPE     imm_dst
  , input  DEFAULT_TYPE     register_a
  , output DEFAULT_TYPE     addr_bus
);
  always_comb begin
    unique case (stage)
      FETCH_OPERATION: addr_bus = ip;
      FETCH_IMMEDIATE: addr_bus = ip;
      FETCH_SRC_IMM:   addr_bus = ip;
      FETCH_DST_IMM:   addr_bus = ip;

      FETCH_SRC: unique case (decode_src)
        ADDRESS_REG_A: addr_bus = register_a;
        ADDRESS_IMM:   addr_bus = imm_src;
      endcase

      FETCH_DST: unique case (decode_dst)
        ADDRESS_REG_A: addr_bus = register_a;
        ADDRESS_IMM:   addr_bus = imm_dst;
      endcase

      WRITE_MEMORY: unique case (decode_dst)
        ADDRESS_REG_A: addr_bus = register_a;
        ADDRESS_IMM:   addr_bus = imm_dst;
      endcase

      default:         addr_bus = `REGSIZE'd0;
    endcase
  end
endmodule/*}}}*/

module update_memory_flag(/*{{{*/
  input    STAGE_TYPE       stage
  , output MEMORY_FLAG_TYPE ctrl_bus
);
  always_comb begin
    unique case (stage)
      FETCH_OPERATION: ctrl_bus = MEMORY_READ;
      FETCH_IMMEDIATE: ctrl_bus = MEMORY_READ;
      FETCH_SRC_IMM:   ctrl_bus = MEMORY_READ;
      FETCH_SRC:       ctrl_bus = MEMORY_READ;
      FETCH_DST_IMM:   ctrl_bus = MEMORY_READ;
      FETCH_DST:       ctrl_bus = MEMORY_READ;
      WRITE_MEMORY:    ctrl_bus = MEMORY_WRITE;
      default:         ctrl_bus = MEMORY_STAY;
    endcase
  end
endmodule/*}}}*/

module clock_posedge(/*{{{*/
  input logic CLOCK
  , input logic RESET

  , input  STAGE_TYPE       next_stage
  , input  DEFAULT_TYPE     next_ip
  , input  DEFAULT_TYPE     next_imm
  , input  DEFAULT_TYPE     next_imm_src
  , input  DEFAULT_TYPE     next_imm_dst
  , input  DEFAULT_TYPE     next_memory_src
  , input  DEFAULT_TYPE     next_memory_dst
  , input  DEFAULT_TYPE     next_register_a
  , input  DEFAULT_TYPE     next_dst
  , input  DEFAULT_TYPE     next_original_dst
  , input  DEFAULT_TYPE     next_write_bus

  , output STAGE_TYPE       stage
  , output DEFAULT_TYPE     ip
  , output DEFAULT_TYPE     imm
  , output DEFAULT_TYPE     imm_src
  , output DEFAULT_TYPE     imm_dst
  , output DEFAULT_TYPE     memory_src
  , output DEFAULT_TYPE     memory_dst
  , output DEFAULT_TYPE     register_a
  , output DEFAULT_TYPE     dst
  , output DEFAULT_TYPE     original_dst
  , output DEFAULT_TYPE     write_bus

);
  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      stage        <= RESET_STAGE;
      ip           <= `REGSIZE'b0;
      imm          <= `REGSIZE'b0;
      imm_src      <= `REGSIZE'b0;
      imm_dst      <= `REGSIZE'b0;
      memory_src   <= `REGSIZE'b0;
      memory_dst   <= `REGSIZE'b0;
      register_a   <= `REGSIZE'b0;
      dst          <= `REGSIZE'b0;
      original_dst <= `REGSIZE'b0;
      write_bus    <= `REGSIZE'b0;

    end else begin
      stage        <= next_stage;
      ip           <= next_ip;
      imm          <= next_imm;
      imm_src      <= next_imm_src;
      imm_dst      <= next_imm_dst;
      memory_src   <= next_memory_src;
      memory_dst   <= next_memory_dst;
      register_a   <= next_register_a;
      dst          <= next_dst;
      original_dst <= next_original_dst;
      write_bus    <= next_write_bus;
    end
  end
endmodule/*}}}*/

module update_stage_fetch_operation(/*{{{*/
  input logic CLOCK
  , input logic RESET
  , input STAGE_TYPE stage
  , input  DEFAULT_TYPE read_bus
  , input  DEFAULT_TYPE ip
  , output STAGE_FETCH_OPERATION_TYPE stage_fetch_operation
  , output DEFAULT_TYPE next_ip
  , output DEFAULT_TYPE ope
);
  STAGE_FETCH_OPERATION_TYPE next_stage_fetch_operation;

  always_comb begin
    unique case (stage)
      FETCH_OPERATION: begin
        unique case (stage_fetch_operation)
          BGN_FETCH_OPERATION: next_stage_fetch_operation = END_FETCH_OPERATION;
          END_FETCH_OPERATION: next_stage_fetch_operation = IDL_FETCH_OPERATION;
          IDL_FETCH_OPERATION: next_stage_fetch_operation = BGN_FETCH_OPERATION;
        endcase
      end
      default: next_stage_fetch_operation = IDL_FETCH_OPERATION;
    endcase
  end

  DEFAULT_TYPE next_ope;
  always_comb begin
    case (stage)
      FETCH_OPERATION: begin
        case (stage_fetch_operation)
          BGN_FETCH_OPERATION: begin
            next_ope = read_bus;
            next_ip  = ip;
          end

          END_FETCH_OPERATION: begin
            next_ope = ope;
            next_ip  = ip + `REGSIZE'd1;
          end

          default: begin
            next_ope = ope;
            next_ip  = ip;
          end
        endcase
      end

      default: begin
        next_ope = ope;
        next_ip  = ip;
      end
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      stage_fetch_operation <= IDL_FETCH_OPERATION;
      ope <= `BYTE_NOP_OPECODE;
    end else begin
      stage_fetch_operation <= next_stage_fetch_operation;
      ope <= next_ope;
    end
  end

endmodule/*}}}*/

module update_stage_fetch_immediate(/*{{{*/
  input logic CLOCK
  , input logic RESET
  , input STAGE_TYPE stage
  , input  DEFAULT_TYPE read_bus
  , input  DEFAULT_TYPE ip
  , output STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate
  , output DEFAULT_TYPE next_ip
  , output DEFAULT_TYPE ope
);
  STAGE_FETCH_IMMEDIATE_TYPE next_stage_fetch_immediate;

  always_comb begin
    unique case (stage)
      DECODE: unique case (stage_fetch_immediate)
        BGN_FETCH_IMMEDIATE: begin
          priority if (decode_src == IMM)           next_stage_fetch_immediate = LOAD_IMMEDIATE;
          else if     (decode_src == ADDRESS_IMM)   next_stage_fetch_immediate = LOAD_SRC_ADDR;
          else if     (decode_src == ADDRESS_REG_A) next_stage_fetch_immediate = LOAD_SRC;
          else if     (decode_dst == ADDRESS_IMM)   next_stage_fetch_immediate = LOAD_DST_ADDR;
          else if     (decode_dst == ADDRESS_REG_A) next_stage_fetch_immediate = LOAD_DST;
          else                                      next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_IMMEDIATE: begin
          priority if (decode_dst == ADDRESS_IMM)   next_stage_fetch_immediate = LOAD_DST_ADDR;
          else if     (decode_dst == ADDRESS_REG_A) next_stage_fetch_immediate = LOAD_DST;
          else                                      next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_SRC_ADDR: next_stage_fetch_immediate = LOAD_SRC;

        LOAD_SRC: begin
          priority if (decode_dst == ADDRESS_IMM)   next_stage_fetch_immediate = LOAD_DST_ADDR;
          else if     (decode_dst == ADDRESS_REG_A) next_stage_fetch_immediate = LOAD_DST;
          else                                      next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_DST_ADDR: next_stage_fetch_immediate = LOAD_DST;

        LOAD_DST: next_stage_fetch_immediate = END_FETCH_IMMEDIATE;

        END_FETCH_IMMEDIATE: next_stage_fetch_immediate = IDL_FETCH_IMMEDIATE;
        IDL_FETCH_IMMEDIATE: next_stage_fetch_immediate = BGN_FETCH_IMMEDIATE;
      endcase

      default: next_stage_fetch_immediate = IDL_FETCH_IMMEDIATE;
    endcase
  end

  DEFAULT_TYPE next_ope;
  always_comb begin
    case (stage)
      FETCH_IMMEDIATE: begin
        case (stage_fetch_immediate)
          BGN_FETCH_IMMEDIATE: begin
            next_ope = read_bus;
            next_ip  = ip;
          end

          END_FETCH_IMMEDIATE: begin
            next_ope = ope;
            next_ip  = ip + `REGSIZE'd1;
          end

          default: begin
            next_ope = ope;
            next_ip  = ip;
          end
        endcase
      end

      default: begin
        next_ope = ope;
        next_ip  = ip;
      end
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      stage_fetch_immediate <= IDL_FETCH_IMMEDIATE;
      ope <= `BYTE_NOP_OPECODE;
    end else begin
      stage_fetch_immediate <= next_stage_fetch_immediate;
      ope <= next_ope;
    end
  end

endmodule/*}}}*/
