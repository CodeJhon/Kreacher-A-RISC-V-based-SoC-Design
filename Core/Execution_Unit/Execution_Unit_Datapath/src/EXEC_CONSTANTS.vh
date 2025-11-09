// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH

// Selecting source / destination
`define SEL_REGFILE    3'b000
`define SEL_PC         3'b001
`define SEL_T1         3'b010
`define SEL_OPERAND    3'b011

// Select devices of regbank (for writing/reading)
`define NONE              2'b00
`define INTERNAL_BUS      2'b01
`define PC                2'b10
`define T1                2'b11

// Select ALU operands
// general
`define OP_BUS             2'b00
// OPA
`define OP_K_NEXT_INSTR    2'b01
`define OP_K_LUI           2'b10
// OPB
`define OP_IMM             2'b01

`endif
