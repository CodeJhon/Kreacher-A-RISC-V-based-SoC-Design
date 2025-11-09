// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH

// 1. Select ALU operands
// general
`define OP_BUS             2'b00
// OPA
`define OP_K_NEXT_INSTR    2'b01
`define OP_K_LUI           2'b10
// OPB
`define OP_IMM             2'b01

// 2. Selecting source / destination
`define SEL_REGBANK    2'b00
`define SEL_ALU        2'b01

// 3. Select devices of regbank (for writing/reading)
`define NONE              2'b00
`define REGFILE           2'b01
`define PC                2'b10
`define T1                2'b11

`endif
