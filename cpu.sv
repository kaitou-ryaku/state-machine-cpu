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
  STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate;

  DEFAULT_TYPE ip, next_ip;

  DEFAULT_TYPE ope;
  OPECODE_TYPE decode_ope;
  OPERAND_TYPE decode_src, decode_dst;
  decoder decoder0(.*);

  DEFAULT_TYPE register_a, next_register_a;
  DEFAULT_TYPE imm;
  DEFAULT_TYPE mem_src, imm_src_addr;
  DEFAULT_TYPE mem_dst, imm_dst_addr;
  DEFAULT_TYPE addr_immediate;
  DEFAULT_TYPE next_ip_immediate;

  DEFAULT_TYPE src;
  decoder_src decoder_src0(.*);

  DEFAULT_TYPE original_dst, next_original_dst;
  decoder_dst decoder_dst0(.*);

  DEFAULT_TYPE dst, next_dst;

  alu alu0(.*);

  DEFAULT_TYPE jmp;
  jmp_addr_bus jmp_addr_bus0(.*);

  DEFAULT_TYPE addr_write;
  update_memory_write update_memory_write0(.*, .addr(addr_write));

  update_memory_addr_bus update_memory_addr_bus0(.*);
  update_memory_flag update_memory_flag0(.*);

  update_stage update_stage0(.*);
  update_execution_result update_execution_result0(.*);

  DEFAULT_TYPE next_ip_operation;
  update_stage_fetch_operation update_stage_fetch_operation0(.*, .next_ip(next_ip_operation));
  update_ip  update_ip0(.*);

  //update_imm update_imm0(.*);

  update_stage_fetch_immediate update_stage_fetch_immediate0(.*,
    .next_ip(next_ip_immediate),
    .addr(addr_immediate)
  );

  clock_posedge clock_posedge0(.*);

  assign OUT = register_a;
endmodule/*}}}*/

module decoder(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , input  STAGE_TYPE   stage
  , input  DEFAULT_TYPE ope
  , output OPECODE_TYPE decode_ope
  , output OPERAND_TYPE decode_src
  , output OPERAND_TYPE decode_dst
);

  OPECODE_TYPE next_decode_ope;
  OPERAND_TYPE next_decode_src;
  OPERAND_TYPE next_decode_dst;

  always_comb begin
    unique case (stage)
      DECODE: begin
        unique casez (ope)
          `REGSIZE'b0000????: next_decode_ope = MOV;
          `REGSIZE'b0001????: next_decode_ope = ADD;
          `REGSIZE'b1100????: next_decode_ope = JMP;
          `REGSIZE'b11111110: next_decode_ope = NOP;
          `REGSIZE'b11111111: next_decode_ope = HLT;
          default:            next_decode_ope = HLT;
        endcase

        unique casez (ope)
          `REGSIZE'b00??00??: next_decode_dst = REG_A;
          `REGSIZE'b00??01??: next_decode_dst = ADDRESS_REG_A;
          `REGSIZE'b00??10??: next_decode_dst = ADDRESS_IMM;
          `REGSIZE'b00??11??: next_decode_dst = IMM; // TODO
          default:            next_decode_dst = UNUSED;
        endcase

        unique casez (ope)
          `REGSIZE'b00????00: next_decode_src = REG_A;
          `REGSIZE'b00????01: next_decode_src = ADDRESS_REG_A;
          `REGSIZE'b00????10: next_decode_src = ADDRESS_IMM;
          `REGSIZE'b00????11: next_decode_src = IMM;
          `REGSIZE'b1100????: next_decode_src = IMM; // JMP
          default:            next_decode_src = UNUSED;
        endcase
      end

      default: begin
        next_decode_ope = decode_ope;
        next_decode_src = decode_src;
        next_decode_dst = decode_dst;
      end
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      decode_ope <= NOP;
      decode_src <= UNUSED;
      decode_dst <= UNUSED;
    end else begin
      decode_ope <= next_decode_ope;
      decode_src <= next_decode_src;
      decode_dst <= next_decode_dst;
    end
  end

endmodule/*}}}*/

module decoder_src(/*{{{*/
  input OPERAND_TYPE decode_src
  , input DEFAULT_TYPE register_a
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE mem_src
  , output DEFAULT_TYPE src
);

  always_comb begin
    unique case (decode_src)
      REG_A:         src = register_a;
      ADDRESS_REG_A: src = mem_src;
      ADDRESS_IMM:   src = mem_src;
      IMM:           src = imm;
      default:       src = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module decoder_dst(/*{{{*/
  input OPERAND_TYPE decode_dst
  , input DEFAULT_TYPE register_a
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE mem_dst
  , output DEFAULT_TYPE next_original_dst
);

  always_comb begin
    unique case (decode_dst)
      REG_A:         next_original_dst = register_a;
      ADDRESS_REG_A: next_original_dst = mem_dst;
      ADDRESS_IMM:   next_original_dst = mem_dst;
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

      DECODE: next_stage = FETCH_IMMEDIATE;

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
  , input DEFAULT_TYPE next_ip_immediate
  , input DEFAULT_TYPE jmp
  , output DEFAULT_TYPE next_ip
);
  always_comb begin
    unique if (decode_ope == HLT) begin
      next_ip = ip;

    end else begin
      unique case (stage)
        FETCH_OPERATION: next_ip = next_ip_operation;
        FETCH_IMMEDIATE: next_ip = next_ip_immediate;
        EXECUTE:         next_ip = ip + jmp;
        default:         next_ip = ip;
      endcase
    end
  end
endmodule/*}}}*/

module update_memory_addr_bus(/*{{{*/
  input    STAGE_TYPE   stage
  , input  DEFAULT_TYPE ip
  , input  DEFAULT_TYPE addr_immediate
  , input  DEFAULT_TYPE addr_write
  , output DEFAULT_TYPE addr_bus
);
  always_comb begin
    unique case (stage)
      FETCH_OPERATION: addr_bus = ip;
      FETCH_IMMEDIATE: addr_bus = addr_immediate;
      WRITE_MEMORY:    addr_bus = addr_write;
      default:         addr_bus = `REGSIZE'd0;
    endcase
  end
endmodule/*}}}*/

module update_memory_write(/*{{{*/
  input   STAGE_TYPE   stage
  , input OPERAND_TYPE decode_dst
  , input DEFAULT_TYPE register_a
  , input DEFAULT_TYPE imm_dst_addr
  , output DEFAULT_TYPE addr
);
  always_comb begin
    unique case (stage)
      WRITE_MEMORY: unique case (decode_dst)
        ADDRESS_REG_A: addr = register_a;
        ADDRESS_IMM:   addr = imm_dst_addr;
        default:       addr = `REGSIZE'd0;
      endcase

      default:         addr = `REGSIZE'd0;
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
  , input  DEFAULT_TYPE     next_register_a
  , input  DEFAULT_TYPE     next_dst
  , input  DEFAULT_TYPE     next_original_dst
  , input  DEFAULT_TYPE     next_write_bus

  , output STAGE_TYPE       stage
  , output DEFAULT_TYPE     ip
  , output DEFAULT_TYPE     register_a
  , output DEFAULT_TYPE     dst
  , output DEFAULT_TYPE     original_dst
  , output DEFAULT_TYPE     write_bus

);
  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      stage        <= RESET_STAGE;
      ip           <= `REGSIZE'b0;
      register_a   <= `REGSIZE'b0;
      dst          <= `REGSIZE'b0;
      original_dst <= `REGSIZE'b0;
      write_bus    <= `REGSIZE'b0;

    end else begin
      stage        <= next_stage;
      ip           <= next_ip;
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
  , input  DEFAULT_TYPE register_a
  , input  OPERAND_TYPE decode_src
  , input  OPERAND_TYPE decode_dst
  , output STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate
  , output DEFAULT_TYPE next_ip

  , output DEFAULT_TYPE imm
  , output DEFAULT_TYPE mem_src
  , output DEFAULT_TYPE imm_src_addr
  , output DEFAULT_TYPE mem_dst
  , output DEFAULT_TYPE imm_dst_addr
  , output DEFAULT_TYPE addr
);
  STAGE_FETCH_IMMEDIATE_TYPE next_stage_fetch_immediate;

  always_comb begin
    unique case (stage)
      FETCH_IMMEDIATE: unique case (stage_fetch_immediate)
        BGN_FETCH_IMMEDIATE: begin
          priority if (decode_src == IMM)           next_stage_fetch_immediate = WAIT_IMMEDIATE;
          else if     (decode_src == ADDRESS_IMM)   next_stage_fetch_immediate = WAIT_SRC_ADDR;
          else if     (decode_src == ADDRESS_REG_A) next_stage_fetch_immediate = WAIT_SRC;
          else if     (decode_dst == ADDRESS_IMM)   next_stage_fetch_immediate = WAIT_DST_ADDR;
          else if     (decode_dst == ADDRESS_REG_A) next_stage_fetch_immediate = WAIT_DST;
          else                                      next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_IMMEDIATE: begin
          priority if (decode_dst == ADDRESS_IMM)   next_stage_fetch_immediate = WAIT_DST_ADDR;
          else if     (decode_dst == ADDRESS_REG_A) next_stage_fetch_immediate = WAIT_DST;
          else                                      next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_SRC_ADDR: next_stage_fetch_immediate = WAIT_SRC;

        LOAD_SRC: begin
          priority if (decode_dst == ADDRESS_IMM)   next_stage_fetch_immediate = WAIT_DST_ADDR;
          else if     (decode_dst == ADDRESS_REG_A) next_stage_fetch_immediate = WAIT_DST;
          else                                      next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_DST_ADDR: next_stage_fetch_immediate = WAIT_DST;

        LOAD_DST: next_stage_fetch_immediate = END_FETCH_IMMEDIATE;

        WAIT_IMMEDIATE: next_stage_fetch_immediate = LOAD_IMMEDIATE;
        WAIT_SRC_ADDR:  next_stage_fetch_immediate = LOAD_SRC_ADDR;
        WAIT_SRC:       next_stage_fetch_immediate = LOAD_SRC;
        WAIT_DST_ADDR:  next_stage_fetch_immediate = LOAD_DST_ADDR;
        WAIT_DST:       next_stage_fetch_immediate = LOAD_DST;

        END_FETCH_IMMEDIATE: next_stage_fetch_immediate = IDL_FETCH_IMMEDIATE;
        IDL_FETCH_IMMEDIATE: next_stage_fetch_immediate = BGN_FETCH_IMMEDIATE;
      endcase

      default: next_stage_fetch_immediate = IDL_FETCH_IMMEDIATE;
    endcase
  end

  DEFAULT_TYPE next_imm;
  DEFAULT_TYPE next_mem_src;
  DEFAULT_TYPE next_mem_dst;
  DEFAULT_TYPE next_imm_src_addr;
  DEFAULT_TYPE next_imm_dst_addr;

  always_comb begin
    unique case (stage)
      FETCH_IMMEDIATE: unique case (stage_fetch_immediate)
        LOAD_IMMEDIATE: begin
          next_ip           = ip + `REGSIZE'd1;
          next_imm          = read_bus;
          next_imm_src_addr = imm_src_addr;
          next_mem_src      = mem_src;
          next_imm_dst_addr = imm_dst_addr;
          next_mem_dst      = mem_dst;
        end

        LOAD_SRC_ADDR: begin
          next_ip           = ip + `REGSIZE'd1;
          next_imm          = imm;
          next_imm_src_addr = read_bus;
          next_mem_src      = mem_src;
          next_imm_dst_addr = imm_dst_addr;
          next_mem_dst      = mem_dst;
        end

        LOAD_SRC: begin
          next_ip           = ip;
          next_imm          = imm;
          next_imm_src_addr = imm_src_addr;
          next_mem_src      = read_bus;
          next_imm_dst_addr = imm_dst_addr;
          next_mem_dst      = mem_dst;
        end

        LOAD_DST_ADDR: begin
          next_ip           = ip + `REGSIZE'd1;
          next_imm          = imm;
          next_imm_src_addr = imm_src_addr;
          next_mem_src      = mem_src;
          next_imm_dst_addr = read_bus;
          next_mem_dst      = mem_dst;
        end

        LOAD_DST: begin
          next_ip           = ip;
          next_imm          = imm;
          next_imm_src_addr = imm_src_addr;
          next_mem_src      = mem_src;
          next_imm_dst_addr = imm_dst_addr;
          next_mem_dst      = read_bus;
        end

        default: begin
          next_ip           = ip;
          next_imm          = imm;
          next_imm_src_addr = imm_src_addr;
          next_mem_src      = mem_src;
          next_imm_dst_addr = imm_dst_addr;
          next_mem_dst      = mem_dst;
        end
      endcase

      default: begin
        next_ip           = ip;
        next_imm          = imm;
        next_imm_src_addr = imm_src_addr;
        next_mem_src      = mem_src;
        next_imm_dst_addr = imm_dst_addr;
        next_mem_dst      = mem_dst;
      end
    endcase
  end

  always_comb begin
    unique case (stage)
      FETCH_IMMEDIATE: begin
        unique case (stage_fetch_immediate)

          WAIT_IMMEDIATE, LOAD_IMMEDIATE:  addr = ip;
          WAIT_SRC_ADDR,  LOAD_SRC_ADDR:   addr = ip;
          WAIT_DST_ADDR,  LOAD_DST_ADDR:   addr = ip;

          WAIT_SRC, LOAD_SRC: unique case (decode_src)
            ADDRESS_REG_A: addr = register_a;
            ADDRESS_IMM:   addr = imm_src_addr;
          endcase

          WAIT_DST, LOAD_DST: unique case (decode_dst)
            ADDRESS_REG_A: addr = register_a;
            ADDRESS_IMM:   addr = imm_dst_addr;
          endcase

          default:         addr = `REGSIZE'd0;
        endcase
      end

      default:             addr = `REGSIZE'd0;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      stage_fetch_immediate <= IDL_FETCH_IMMEDIATE;
      imm          <= `REGSIZE'd0;
      imm_src_addr <= `REGSIZE'd0;
      mem_src      <= `REGSIZE'd0;
      imm_dst_addr <= `REGSIZE'd0;
      mem_dst      <= `REGSIZE'd0;
    end else begin
      stage_fetch_immediate <= next_stage_fetch_immediate;
      imm          <= next_imm;
      imm_src_addr <= next_imm_src_addr;
      mem_src      <= next_mem_src;
      imm_dst_addr <= next_imm_dst_addr;
      mem_dst      <= next_mem_dst;
    end
  end

endmodule/*}}}*/
