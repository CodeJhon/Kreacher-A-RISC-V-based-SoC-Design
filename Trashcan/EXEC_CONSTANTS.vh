// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH

// ---- ALU CONSTANTS ----
`define ALU_ADD   5'b00000
`define ALU_SUB   5'b00001
`define ALU_SLT   5'b00010
`define ALU_SLTU  5'b00011
`define ALU_AND   5'b00100
`define ALU_OR    5'b00101
`define ALU_XOR   5'b00110
`define ALU_SLL   5'b00111
`define ALU_SRL   5'b01000
`define ALU_SRA   5'b01001

// ----- Selection of ALU operands ----
// general (Both OPA & OPB)
`define OP_BUS             2'b00
// OPA
`define OP_K_NEXT_INSTR    2'b01
`define OP_K_LUI           2'b10
// OPB
`define OP_IMM             2'b01

// ------ 2. Selecting source / destination ----
`define SEL_REGBANK        2'b01
`define SEL_ALU            2'b10
`define NONE               2'b00

// ----- 3. Select devices of regbank (for writing/reading) -----
`define REGFILE            2'b01
`define PC                 2'b10
`define T1                 2'b11
//      NONE               2'b00  ----> Also applies for this purpose

`endif
