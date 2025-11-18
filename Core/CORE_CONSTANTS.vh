// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH

// ---- ALU CONSTANTS ----
`define ALU_ADD         5'b00000
`define ALU_SUB         5'b00001
`define ALU_SLT         5'b00010
`define ALU_SLTU        5'b00011
`define ALU_AND         5'b00100
`define ALU_OR          5'b00101
`define ALU_XOR         5'b00110
`define ALU_SLL         5'b00111
`define ALU_SRL         5'b01000
`define ALU_SRA         5'b01001
`define ALU_FORWARD_A   5'b01010

// --- CONTROL CONSTANTS ----

//sel_next_pc
`define NEXT_PC_4         2'b00
`define NEXT_PC_ALU_OUT   2'b01

//sel_opa
`define OPA_PC      2'b00
`define OPA_RS1     2'b01

//sel_opb
`define OPB_IMM     2'b00
`define OPB_RS2     2'b01

//sel_writeback
`define WBACK_ALU_OUT    2'b00
`define WBACK_PC_4       2'b01
`define WBACK_EMDB       2'b10

//val_rd_type, val_wr_type (mem stage)
`define FORWARD_INPUT   3'b000
`define SIGN_EXTEND_16  3'b001
`define SIGN_EXTEND_8   3'b010
`define ZERO_EXTEND_16  3'b011
`define ZERO_EXTEND_8   3'b100

//imm_type
`define I_IMMEDIATE 3'b000
`define S_IMMEDIATE 3'b001
`define B_IMMEDIATE 3'b010
`define U_IMMEDIATE 3'b011
`define J_IMMEDIATE 3'b100

`endif
