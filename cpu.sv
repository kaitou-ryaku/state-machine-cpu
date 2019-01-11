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
  STAGE_TYPE stage;

  STAGE_FETCH_OPERATION_TYPE stage_fetch_operation;
  STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate;
  STAGE_WRITE_MEMORY_TYPE    stage_write_memory;

  DEFAULT_TYPE ip;

  DEFAULT_TYPE ope;
  INSTRUCTION_PACK_TYPE instruction;
  decoder decoder0(.*);

  REGISTER_PACK_TYPE register;
  DEFAULT_TYPE imm;
  DEFAULT_TYPE mem_src, imm_src_addr;
  DEFAULT_TYPE mem_dst, imm_dst_addr;
  DEFAULT_TYPE addr_immediate;
  DEFAULT_TYPE next_ip_immediate;

  DEFAULT_TYPE src;
  decoder_src decoder_src0(.*);

  DEFAULT_TYPE original_dst;
  update_original_dst update_original_dst0(.*);

  DEFAULT_TYPE dst, dst_register_flag;;

  alu alu0(.*);

  update_register_value update_register_value0(.*);

  DEFAULT_TYPE jmp;
  jmp_addr_bus jmp_addr_bus0(.*);

  DEFAULT_TYPE addr_write;
  MEMORY_FLAG_TYPE ctrl_bus_write;
  update_memory_write update_memory_write0(.*,
    .addr(addr_write),
    .ctrl_bus(ctrl_bus_write)
  );

  update_memory_addr_bus update_memory_addr_bus0(.*);
  update_memory_flag update_memory_flag0(.*);

  update_stage update_stage0(.*);

  DEFAULT_TYPE next_ip_operation;
  update_stage_fetch_operation update_stage_fetch_operation0(.*, .next_ip(next_ip_operation));
  update_ip  update_ip0(.*);

  update_stage_fetch_immediate update_stage_fetch_immediate0(.*,
    .next_ip(next_ip_immediate),
    .addr(addr_immediate)
  );

  assign OUT = register.a;

  logic flag_carry, flag_zero, flag_sign, flag_overflow, flag_underflow;
  assign flag_carry     = register.flag[`FLAG_CARRY];
  assign flag_zero      = register.flag[`FLAG_ZERO];
  assign flag_sign      = register.flag[`FLAG_SIGN];
  assign flag_overflow  = register.flag[`FLAG_OVERFLOW];
  assign flag_underflow = register.flag[`FLAG_UNDERFLOW];
endmodule/*}}}*/

module decoder(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , input  STAGE_TYPE   stage
  , input  DEFAULT_TYPE ope
  , output INSTRUCTION_PACK_TYPE instruction
);

  INSTRUCTION_PACK_TYPE next_instruction;
  always_comb begin
    unique case (stage)
      DECODE: unique casez (ope)
        `REGSIZE'b00_???_???: next_instruction.ope = MOV;
        `REGSIZE'b01_???_???: next_instruction.ope = ADD;
        `REGSIZE'b10_???_???: next_instruction.ope = CMP;

        `REGSIZE'b11_000_???: next_instruction.ope = PUSH;
        `REGSIZE'b11_001_???: next_instruction.ope = POP;

        `REGSIZE'b11_010_000: next_instruction.ope = JMP;

        `REGSIZE'b11_100_000: next_instruction.ope = JO;
        `REGSIZE'b11_100_001: next_instruction.ope = JNO;
        `REGSIZE'b11_100_010: next_instruction.ope = JC;
        `REGSIZE'b11_100_011: next_instruction.ope = JNC;
        `REGSIZE'b11_100_100: next_instruction.ope = JZ;
        `REGSIZE'b11_100_101: next_instruction.ope = JNZ;
        `REGSIZE'b11_100_110: next_instruction.ope = JBE;
        `REGSIZE'b11_100_111: next_instruction.ope = JA;
        `REGSIZE'b11_101_000: next_instruction.ope = JS;
        `REGSIZE'b11_101_001: next_instruction.ope = JNS;
        `REGSIZE'b11_101_010: next_instruction.ope = JP;
        `REGSIZE'b11_101_011: next_instruction.ope = JNP;
        `REGSIZE'b11_101_100: next_instruction.ope = JL;
        `REGSIZE'b11_101_101: next_instruction.ope = JGE;
        `REGSIZE'b11_101_110: next_instruction.ope = JLE;
        `REGSIZE'b11_101_111: next_instruction.ope = JG;

        `REGSIZE'b11_111_110: next_instruction.ope = NOP;
        `REGSIZE'b11_111_111: next_instruction.ope = HLT;
        default:              next_instruction.ope = HLT;
      endcase
      default:                next_instruction.ope = instruction.ope;
    endcase
  end

  always_comb begin
    unique case (stage)
      DECODE: unique casez (ope)
        // (MOV, ADD) (a,sp) ?
        `REGSIZE'b0?_000_???: next_instruction.dst = REG_A;
        `REGSIZE'b0?_001_???: next_instruction.dst = ADDRESS_REG_A;
        `REGSIZE'b0?_010_???: next_instruction.dst = ADDRESS_IMM;
        `REGSIZE'b0?_011_???: next_instruction.dst = IMM;
        `REGSIZE'b0?_100_???: next_instruction.dst = REG_SP;
        `REGSIZE'b0?_101_???: next_instruction.dst = ADDRESS_REG_SP;
        `REGSIZE'b0?_110_???: next_instruction.dst = ADDRESS_IMM;
        `REGSIZE'b0?_111_???: next_instruction.dst = IMM;

        // CMP (a,sp) ?
        `REGSIZE'b10_000_???: next_instruction.dst = REG_A;
        `REGSIZE'b10_001_???: next_instruction.dst = ADDRESS_REG_A;
        `REGSIZE'b10_010_???: next_instruction.dst = ADDRESS_IMM;
        `REGSIZE'b10_011_???: next_instruction.dst = IMM;
        `REGSIZE'b10_100_???: next_instruction.dst = REG_SP;
        `REGSIZE'b10_101_???: next_instruction.dst = ADDRESS_REG_SP;
        `REGSIZE'b10_110_???: next_instruction.dst = ADDRESS_IMM;
        `REGSIZE'b10_111_???: next_instruction.dst = IMM;

        // PUSH ?
        `REGSIZE'b11_000_???: next_instruction.dst = ADDRESS_REG_SP;

        // POP (a,sp)
        `REGSIZE'b11_001_000: next_instruction.dst = REG_A;
        `REGSIZE'b11_001_001: next_instruction.dst = ADDRESS_REG_A;
        `REGSIZE'b11_001_010: next_instruction.dst = ADDRESS_IMM;
        `REGSIZE'b11_001_011: next_instruction.dst = IMM;
        `REGSIZE'b11_001_100: next_instruction.dst = REG_SP;
        `REGSIZE'b11_001_101: next_instruction.dst = ADDRESS_REG_SP;
        `REGSIZE'b11_001_110: next_instruction.dst = ADDRESS_IMM;
        `REGSIZE'b11_001_111: next_instruction.dst = IMM;

        default:              next_instruction.dst = UNUSED;
        endcase
      default:                next_instruction.dst = instruction.dst;
    endcase
  end

  always_comb begin
    unique case (stage)
      DECODE: unique casez (ope)
        // (MOV, ADD) ? (a,sp)
        `REGSIZE'b0?_???_000: next_instruction.src = REG_A;
        `REGSIZE'b0?_???_001: next_instruction.src = ADDRESS_REG_A;
        `REGSIZE'b0?_???_010: next_instruction.src = ADDRESS_IMM;
        `REGSIZE'b0?_???_011: next_instruction.src = IMM; // TODO
        `REGSIZE'b0?_???_100: next_instruction.src = REG_SP;
        `REGSIZE'b0?_???_101: next_instruction.src = ADDRESS_REG_SP;
        `REGSIZE'b0?_???_110: next_instruction.src = ADDRESS_IMM;
        `REGSIZE'b0?_???_111: next_instruction.src = IMM;

        // CMP ? (a,sp)
        `REGSIZE'b10_???_000: next_instruction.src = REG_A;
        `REGSIZE'b10_???_001: next_instruction.src = ADDRESS_REG_A;
        `REGSIZE'b10_???_010: next_instruction.src = ADDRESS_IMM;
        `REGSIZE'b10_???_011: next_instruction.src = IMM; // TODO
        `REGSIZE'b10_???_100: next_instruction.src = REG_SP;
        `REGSIZE'b10_???_101: next_instruction.src = ADDRESS_REG_SP;
        `REGSIZE'b10_???_110: next_instruction.src = ADDRESS_IMM;
        `REGSIZE'b10_???_111: next_instruction.src = IMM;

        // PUSH (a,sp)
        `REGSIZE'b11_000_000: next_instruction.src = REG_A;
        `REGSIZE'b11_000_001: next_instruction.src = ADDRESS_REG_A;
        `REGSIZE'b11_000_010: next_instruction.src = ADDRESS_IMM;
        `REGSIZE'b11_000_011: next_instruction.src = IMM;
        `REGSIZE'b11_000_100: next_instruction.src = REG_SP;
        `REGSIZE'b11_000_101: next_instruction.src = ADDRESS_REG_SP;
        `REGSIZE'b11_000_110: next_instruction.src = ADDRESS_IMM;
        `REGSIZE'b11_000_111: next_instruction.src = IMM;

        // POP ?
        `REGSIZE'b11_001_???: next_instruction.src = ADDRESS_REG_SP;

        // JMP
        `REGSIZE'b11_01?_???: next_instruction.src = IMM;

        // JCC
        `REGSIZE'b11_10?_???: next_instruction.src = IMM;

        default:              next_instruction.src = UNUSED;
        endcase
      default:                next_instruction.src = instruction.src;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      instruction.ope <= NOP;
      instruction.src <= UNUSED;
      instruction.dst <= UNUSED;
    end else begin
      instruction.ope <= next_instruction.ope;
      instruction.src <= next_instruction.src;
      instruction.dst <= next_instruction.dst;
    end
  end

endmodule/*}}}*/

module decoder_src(/*{{{*/
  input INSTRUCTION_PACK_TYPE instruction
  , input REGISTER_PACK_TYPE register
  , input DEFAULT_TYPE imm
  , input DEFAULT_TYPE mem_src
  , output DEFAULT_TYPE src
);

  always_comb begin
    unique case (instruction.src)
      REG_A:               src = register.a;
      REG_SP:              src = register.sp;
      ADDRESS_REG_A:       src = mem_src;
      ADDRESS_REG_SP:      src = mem_src;
      ADDRESS_IMM:         src = mem_src;
      IMM:                 src = imm;
      default:             src = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module update_original_dst(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , input INSTRUCTION_PACK_TYPE instruction
  , input  REGISTER_PACK_TYPE register
  , input  DEFAULT_TYPE imm
  , input  DEFAULT_TYPE mem_dst
  , output DEFAULT_TYPE original_dst
);

  DEFAULT_TYPE next_original_dst;
  always_comb begin
    unique case (instruction.dst)
      REG_A:               next_original_dst = register.a;
      REG_SP:              next_original_dst = register.sp;
      ADDRESS_REG_A:       next_original_dst = mem_dst;
      ADDRESS_REG_SP:      next_original_dst = mem_dst;
      ADDRESS_IMM:         next_original_dst = mem_dst;
      default:             next_original_dst = `REGSIZE'd0;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) original_dst <= `REGSIZE'b0;
    else original_dst <= next_original_dst;
  end
endmodule/*}}}*/

module alu(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , input  STAGE_TYPE   stage
  , input  INSTRUCTION_PACK_TYPE instruction
  , input  DEFAULT_TYPE src
  , input  DEFAULT_TYPE original_dst
  , output DEFAULT_TYPE dst
  , output DEFAULT_TYPE dst_register_flag
);

  // dst(src1) = original_dst(src1) ? src(src2)
  EXTEND_DEFAULT_TYPE u_ex_src1, u_ex_src2, u_ex_inv2;
  EXTEND_DEFAULT_TYPE s_ex_src1, s_ex_src2, s_ex_inv2;

  assign u_ex_src1 = {1'b0, original_dst};
  assign u_ex_src2 = {1'b0, src};
  assign u_ex_inv2 = {1'b0, `REGSIZE'(~(src) + `REGSIZE'b1)};

  assign s_ex_src1 = {original_dst[`REGSIZE-1], original_dst};
  assign s_ex_src2 = {src[`REGSIZE-1], src};
  assign s_ex_inv2 = ~(s_ex_src2) + `EXTEND_REGSIZE'b1;

  EXTEND_DEFAULT_TYPE u_ex_dst;
  always_comb begin
    unique case (instruction.ope)
      ADD:     u_ex_dst = u_ex_src1 + u_ex_src2;
      CMP:     u_ex_dst = u_ex_src1 + u_ex_inv2;
      MOV:     u_ex_dst = u_ex_src2;
      PUSH:    u_ex_dst = u_ex_src2;
      POP:     u_ex_dst = u_ex_src2;
      HLT:     u_ex_dst = u_ex_src1;
      default: u_ex_dst = u_ex_src1;
    endcase
  end

  EXTEND_DEFAULT_TYPE s_ex_dst;
  always_comb begin
    unique case (instruction.ope)
      ADD:     s_ex_dst = s_ex_src1 + s_ex_src2;
      CMP:     s_ex_dst = s_ex_src1 + s_ex_inv2;
      MOV:     s_ex_dst = s_ex_src2;
      PUSH:    s_ex_dst = s_ex_src2;
      POP:     s_ex_dst = s_ex_src2;
      HLT:     s_ex_dst = s_ex_src1;
      default: s_ex_dst = s_ex_src1;
    endcase
  end

  logic carry, zero, sign, overflow, underflow;
  assign carry     = u_ex_dst[`EXTEND_REGSIZE-1];
  assign zero      = ~(|(u_ex_dst[`REGSIZE-1:0]));
  assign sign      = u_ex_dst[`REGSIZE-1];
  assign overflow  = ((s_ex_dst[`EXTEND_REGSIZE-1] == 1'b0) & (s_ex_dst[`REGSIZE-1] == 1'b1)) ? 1'b1 : 1'b0;
  assign underflow = ((s_ex_dst[`EXTEND_REGSIZE-1] == 1'b1) & (s_ex_dst[`REGSIZE-1] == 1'b0)) ? 1'b1 : 1'b0;

  DEFAULT_TYPE flag;
  assign flag = {1'b0, 1'b0, 1'b0, underflow, overflow, sign, zero, carry};

  DEFAULT_TYPE next_dst;
  always_comb begin
    unique case (stage)
      EXECUTE: unique case (instruction.ope)
        CMP:     next_dst = dst;
        default: next_dst = u_ex_dst[`REGSIZE-1:0];
      endcase
      default:   next_dst = dst;
    endcase
  end

  DEFAULT_TYPE next_flag;
  always_comb begin
    unique case (stage)
      EXECUTE: unique case (instruction.ope)
        ADD:     next_flag = flag;
        CMP:     next_flag = flag;
        default: next_flag = dst_register_flag;
      endcase
      default:   next_flag = dst_register_flag;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) dst <= `REGSIZE'd0;
    else dst <= next_dst;

    unique if (RESET) dst_register_flag <= `REGSIZE'd0;
    else dst_register_flag <= next_flag;
  end

endmodule/*}}}*/

module jmp_addr_bus(/*{{{*/
  input INSTRUCTION_PACK_TYPE instruction
  , input DEFAULT_TYPE imm
  , input REGISTER_PACK_TYPE register
  , output DEFAULT_TYPE jmp
);

  logic cf, zf, sf, of;
  assign cf = register.flag[`FLAG_CARRY];
  assign zf = register.flag[`FLAG_ZERO];
  assign sf = register.flag[`FLAG_SIGN];
  assign of = register.flag[`FLAG_OVERFLOW];

  always_comb begin
    unique case (instruction.ope)
      JMP:     jmp = imm;

      JO:      jmp = (of == 1'b1)                   ? imm : `REGSIZE'd0;
      JNO:     jmp = (of == 1'b0)                   ? imm : `REGSIZE'd0;
      JC:      jmp = (cf == 1'b1)                   ? imm : `REGSIZE'd0;
      JNC:     jmp = (cf == 1'b0)                   ? imm : `REGSIZE'd0;
      JZ:      jmp = (zf == 1'b1)                   ? imm : `REGSIZE'd0;
      JNZ:     jmp = (zf == 1'b0)                   ? imm : `REGSIZE'd0;
      JBE:     jmp = ((cf == 1'b1) | (zf == 1'b1))  ? imm : `REGSIZE'd0;
      JA:      jmp = ((cf == 1'b0) & (zf == 1'b0))  ? imm : `REGSIZE'd0;
      JS:      jmp = (sf == 1'b1)                   ? imm : `REGSIZE'd0;
      JNS:     jmp = (sf == 1'b0)                   ? imm : `REGSIZE'd0;
      JP:      jmp = imm; // TODO
      JNP:     jmp = imm; // TODO
      JL:      jmp = (sf != of)                     ? imm : `REGSIZE'd0;
      JGE:     jmp = (sf == of)                     ? imm : `REGSIZE'd0;
      JLE:     jmp = ((zf == 1'b1) | (sf != of))    ? imm : `REGSIZE'd0;
      JG:      jmp = ((zf != 1'b1) & (sf == of))    ? imm : `REGSIZE'd0;

      default: jmp = `REGSIZE'd0;
    endcase
  end

endmodule/*}}}*/

module update_stage(/*{{{*/
  input    logic CLOCK
  , input  logic RESET
  , input STAGE_FETCH_OPERATION_TYPE stage_fetch_operation
  , input STAGE_FETCH_IMMEDIATE_TYPE stage_fetch_immediate
  , input STAGE_WRITE_MEMORY_TYPE    stage_write_memory
  , input INSTRUCTION_PACK_TYPE instruction
  , output STAGE_TYPE stage
);

  STAGE_TYPE next_stage;
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

      WRITE_REGISTER: unique case (instruction.dst)
        ADDRESS_IMM:         next_stage = WRITE_MEMORY;
        ADDRESS_REG_SP:      next_stage = WRITE_MEMORY;
        default:             next_stage = FETCH_OPERATION;
      endcase

      WRITE_MEMORY: unique case (stage_write_memory)
        END_WRITE_MEMORY:    next_stage = FETCH_OPERATION;
        default:             next_stage = WRITE_MEMORY;
      endcase

      default: next_stage = FETCH_OPERATION;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) stage <= RESET_STAGE;
    else stage <= next_stage;
  end
endmodule/*}}}*/

module update_register_value(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , input  STAGE_TYPE   stage
  , input  INSTRUCTION_PACK_TYPE instruction
  , input  DEFAULT_TYPE dst
  , output REGISTER_PACK_TYPE register
  , input  DEFAULT_TYPE dst_register_flag
);

  REGISTER_PACK_TYPE next_register;

  always_comb begin
    unique if ((stage == WRITE_REGISTER) & (instruction.dst == REG_A )) next_register.a  = dst;
    else next_register.a = register.a;
  end

  always_comb begin
    if (stage == WRITE_REGISTER) begin
      if (instruction.dst == REG_SP)    next_register.sp = dst;
      else if (instruction.ope == PUSH) next_register.sp = register.sp-`STACK_UNIT;
      else if (instruction.ope == POP)  next_register.sp = register.sp+`STACK_UNIT;
      else next_register.sp = register.sp;
    end else next_register.sp = register.sp;
  end

  always_comb begin
    if (stage == WRITE_REGISTER) next_register.flag = dst_register_flag;
    else next_register.flag = register.flag;
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) register.a <= `REGSIZE'd0;
    else              register.a <= next_register.a;

    unique if (RESET) register.sp <= `REGSIZE'd`MEMSIZE;
    else              register.sp <= next_register.sp;

    unique if (RESET) register.flag <= `REGSIZE'd`MEMSIZE;
    else              register.flag <= next_register.flag;
  end
endmodule/*}}}*/

module update_ip(/*{{{*/
  input    logic        CLOCK
  , input  logic        RESET
  , input  STAGE_TYPE   stage
  , input INSTRUCTION_PACK_TYPE instruction
  , input  DEFAULT_TYPE next_ip_operation
  , input  DEFAULT_TYPE next_ip_immediate
  , input  DEFAULT_TYPE jmp
  , output DEFAULT_TYPE ip
);

  DEFAULT_TYPE next_ip;
  always_comb begin
    unique if (instruction.ope == HLT) next_ip = ip;
    else unique case (stage)
      FETCH_OPERATION: next_ip = next_ip_operation;
      FETCH_IMMEDIATE: next_ip = next_ip_immediate;
      EXECUTE:         next_ip = ip + jmp;
      default:         next_ip = ip;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) ip <= `REGSIZE'b0;
    else ip <= next_ip;
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
  input    logic        CLOCK
  , input  logic        RESET

  , input  REGISTER_PACK_TYPE register
  , input  DEFAULT_TYPE imm_dst_addr
  , output DEFAULT_TYPE addr

  , input  STAGE_TYPE   stage
  , input INSTRUCTION_PACK_TYPE instruction
  , input  DEFAULT_TYPE dst
  , output DEFAULT_TYPE write_bus
  , output STAGE_WRITE_MEMORY_TYPE stage_write_memory
  , output MEMORY_FLAG_TYPE ctrl_bus
);

  STAGE_WRITE_MEMORY_TYPE next_stage_write_memory;
  always_comb begin
    unique case (stage)
      WRITE_MEMORY: begin
        unique case (stage_write_memory)
          BGN_WRITE_MEMORY: next_stage_write_memory = END_WRITE_MEMORY;
          END_WRITE_MEMORY: next_stage_write_memory = IDL_WRITE_MEMORY;
          IDL_WRITE_MEMORY: next_stage_write_memory = BGN_WRITE_MEMORY;
        endcase
      end
      default: next_stage_write_memory = IDL_WRITE_MEMORY;
    endcase
  end

  always_comb begin
    unique case (stage)
      WRITE_MEMORY: unique case(stage_write_memory)
        BGN_WRITE_MEMORY: ctrl_bus = MEMORY_WRITE;
        END_WRITE_MEMORY: ctrl_bus = MEMORY_WRITE;
        IDL_WRITE_MEMORY: ctrl_bus = MEMORY_STAY;
        default:          ctrl_bus = MEMORY_STAY;
      endcase
    endcase
  end

  always_comb begin
    unique case (stage)
      WRITE_MEMORY: unique case (instruction.dst)
        ADDRESS_REG_A:  addr = register.a;
        ADDRESS_REG_SP: addr = register.sp;
        ADDRESS_IMM:    addr = imm_dst_addr;
        default:        addr = `REGSIZE'd0;
      endcase

      default:          addr = `REGSIZE'd0;
    endcase
  end

  DEFAULT_TYPE next_write_bus;
  always_comb begin
    unique case (stage)
      WRITE_MEMORY: unique case (instruction.dst)
        REG_A:          next_write_bus = write_bus;
        REG_SP:         next_write_bus = write_bus;
        ADDRESS_REG_A:  next_write_bus = dst;
        ADDRESS_REG_SP: next_write_bus = dst;
        ADDRESS_IMM:    next_write_bus = dst;
        default:        next_write_bus = write_bus;
      endcase

      default:         next_write_bus = write_bus;
    endcase
  end

  always_ff @(posedge CLOCK) begin
    unique if (RESET) begin
      stage_write_memory <= IDL_WRITE_MEMORY;
      write_bus <= `REGSIZE'b0;
    end else begin
      stage_write_memory <= next_stage_write_memory;
      write_bus <= next_write_bus;
    end
  end
endmodule/*}}}*/

module update_memory_flag(/*{{{*/
  input    STAGE_TYPE       stage
  , input  MEMORY_FLAG_TYPE ctrl_bus_write
  , output MEMORY_FLAG_TYPE ctrl_bus
);
  always_comb begin
    unique case (stage)
      FETCH_OPERATION: ctrl_bus = MEMORY_READ;
      FETCH_IMMEDIATE: ctrl_bus = MEMORY_READ;
      WRITE_MEMORY:    ctrl_bus = ctrl_bus_write;
      default:         ctrl_bus = MEMORY_STAY;
    endcase
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
  , input  REGISTER_PACK_TYPE register
  , input  INSTRUCTION_PACK_TYPE instruction
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
          priority if (instruction.src == IMM)            next_stage_fetch_immediate = WAIT_IMMEDIATE;
          else if     (instruction.src == ADDRESS_IMM)    next_stage_fetch_immediate = WAIT_SRC_ADDR;
          else if     (instruction.src == ADDRESS_REG_A)  next_stage_fetch_immediate = WAIT_SRC;
          else if     (instruction.src == ADDRESS_REG_SP) next_stage_fetch_immediate = WAIT_SRC;
          else if     (instruction.dst == ADDRESS_IMM)    next_stage_fetch_immediate = WAIT_DST_ADDR;
          else if     (instruction.dst == ADDRESS_REG_A)  next_stage_fetch_immediate = WAIT_DST;
          else if     (instruction.dst == ADDRESS_REG_SP) next_stage_fetch_immediate = WAIT_DST;
          else                                            next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_IMMEDIATE: begin
          priority if (instruction.dst == ADDRESS_IMM)    next_stage_fetch_immediate = WAIT_DST_ADDR;
          else if     (instruction.dst == ADDRESS_REG_A)  next_stage_fetch_immediate = WAIT_DST;
          else if     (instruction.dst == ADDRESS_REG_SP) next_stage_fetch_immediate = WAIT_DST;
          else                                            next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
        end

        LOAD_SRC_ADDR: next_stage_fetch_immediate = WAIT_SRC;

        LOAD_SRC: begin
          priority if (instruction.dst == ADDRESS_IMM)    next_stage_fetch_immediate = WAIT_DST_ADDR;
          else if     (instruction.dst == ADDRESS_REG_A)  next_stage_fetch_immediate = WAIT_DST;
          else if     (instruction.dst == ADDRESS_REG_SP) next_stage_fetch_immediate = WAIT_DST;
          else                                            next_stage_fetch_immediate = END_FETCH_IMMEDIATE;
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

          WAIT_SRC, LOAD_SRC: unique case (instruction.src)
            ADDRESS_REG_A:       addr = register.a;
            ADDRESS_REG_SP:      addr = register.sp;
            ADDRESS_IMM:         addr = imm_src_addr;
          endcase

          WAIT_DST, LOAD_DST: unique case (instruction.dst)
            ADDRESS_REG_A:  addr = register.a;
            ADDRESS_REG_SP: addr = register.sp;
            ADDRESS_IMM:    addr = imm_dst_addr;
          endcase

          default:          addr = `REGSIZE'd0;
        endcase
      end

      default:              addr = `REGSIZE'd0;
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
