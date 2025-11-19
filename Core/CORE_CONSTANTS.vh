// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH

// ---- OPCODE CONSTANTS ----
`define SHIFT_ARITHMETIC 7'b0010011 
`define LUI 7'b0110111
`define AUIPC 7'b0010111



// ---- func3 ----SHIFT_ARITHMETIC
`define ADDI 3'b000
`define SLLI 3'b001
`define SLTI 3'b010
`define SLTIU 3'b011
`define ANDI 3'b100
`define SRLI_SRAI 3'b101
`define XORI 3'b110
`define  ORI 3'b111 

// ---- func7 ----


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
`define ALU_FORWARD_B   5'b01010

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
`define WBACK_ALU_OUT    3'b000
`define WBACK_PC_4       3'b001
`define WBACK_EMDB       3'b010

//val_rd_type, val_wr_type (mem stage)
`define FORWARD_INPUT   3'b000
`define SIGN_EXTEND_16  3'b001
`define SIGN_EXTEND_8   3'b010
`define ZERO_EXTEND_16  3'b011
`define ZERO_EXTEND_8   3'b100
`define MEM_NOT_USED 3'b101

//imm_type
`define I_IMMEDIATE 3'b000
`define S_IMMEDIATE 3'b001
`define B_IMMEDIATE 3'b010
`define U_IMMEDIATE 3'b011
`define J_IMMEDIATE 3'b100
// `define I_IMMEDIATE_shamt 3'b101


`define ENABLE 1'b1
`define DISABLE 1'b0

`endif
