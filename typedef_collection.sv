`ifndef INCLUDE_TYPEDEF_COLLECTION_SV
`define INCLUDE_TYPEDEF_COLLECTION_SV

`define MEMSIZE 128
`define ROMSIZE 16
`define REGSIZE 8

`define BYTE_NOP_OPECODE `REGSIZE'b11111110

typedef logic [`REGSIZE-1:0] DEFAULT_TYPE;

typedef enum logic [4:0] {
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

typedef enum logic [4:0] {
  IDL_FETCH_IMMEDIATE
  , BGN_FETCH_IMMEDIATE
  , END_FETCH_IMMEDIATE
  , LOAD_IMMEDIATE
  , LOAD_SRC_ADDR
  , LOAD_SRC
  , LOAD_DST_ADDR
  , LOAD_DST
} STAGE_FETCH_IMMEDIATE_TYPE;

typedef enum logic [3:0] {ADD, MOV, HLT, JMP, NOP} OPECODE_TYPE;

typedef enum logic [2:0] {REG_A, ADDRESS_REG_A, ADDRESS_IMM, IMM, UNUSED} OPERAND_TYPE;

typedef enum logic [3:0] {MEMORY_STAY, MEMORY_READ, MEMORY_WRITE} MEMORY_FLAG_TYPE;

typedef enum logic {STAGE_STAGE_BUSY, STAGE_STAGE_STAY} STAGE_STATE_TYPE;

`endif
