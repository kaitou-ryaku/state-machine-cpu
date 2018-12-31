`ifndef INCLUDE_TYPEDEF_COLLECTION_SV
`define INCLUDE_TYPEDEF_COLLECTION_SV

`define MEMSIZE 128
`define ROMSIZE 64
`define REGSIZE 8
`define STACK_UNIT `REGSIZE'd1

`define BYTE_NOP_OPECODE `REGSIZE'b11111110

typedef logic [`REGSIZE-1:0] DEFAULT_TYPE;

typedef enum logic [2:0] {
  RESET_STAGE
  , FETCH_OPERATION
  , DECODE
  , FETCH_IMMEDIATE
  , EXECUTE
  , WRITE_REGISTER
  , WRITE_MEMORY
} STAGE_TYPE;

typedef enum logic [1:0] {
  IDL_FETCH_OPERATION
  , BGN_FETCH_OPERATION
  , END_FETCH_OPERATION
} STAGE_FETCH_OPERATION_TYPE;

typedef enum logic [3:0] {
  IDL_FETCH_IMMEDIATE
  , BGN_FETCH_IMMEDIATE
  , END_FETCH_IMMEDIATE
  , WAIT_IMMEDIATE
  , LOAD_IMMEDIATE
  , WAIT_SRC_ADDR
  , LOAD_SRC_ADDR
  , WAIT_SRC
  , LOAD_SRC
  , WAIT_DST_ADDR
  , LOAD_DST_ADDR
  , WAIT_DST
  , LOAD_DST
} STAGE_FETCH_IMMEDIATE_TYPE;

typedef enum logic [3:0] {ADD, MOV, HLT, JMP, NOP, PUSH, POP} OPECODE_TYPE;

typedef enum logic [3:0] {
  REG_A
  , REG_SP
  , ADDRESS_REG_A
  , ADDRESS_REG_SP_PUSH
  , ADDRESS_REG_SP_POP
  , ADDRESS_REG_SP
  , ADDRESS_IMM
  , IMM
  , UNUSED
} OPERAND_TYPE;

typedef enum logic [3:0] {MEMORY_STAY, MEMORY_READ, MEMORY_WRITE} MEMORY_FLAG_TYPE;

typedef enum logic [1:0] {
  IDL_WRITE_MEMORY
  , BGN_WRITE_MEMORY
  , END_WRITE_MEMORY
} STAGE_WRITE_MEMORY_TYPE;

`endif
