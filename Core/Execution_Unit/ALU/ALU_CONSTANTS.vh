// ALU constants
`ifndef ALU_CONSTANTS_VH
`define ALU_CONSTANTS_VH

localparam ALU_ADD                             = 5'b00000;
localparam ALU_SUB                             = 5'b00001;
localparam ALU_SLT                             = 5'b00010;
localparam ALU_SLTU                            = 5'b00011;
localparam ALU_AND                             = 5'b00100;
localparam ALU_OR                              = 5'b00101;
localparam ALU_XOR                             = 5'b00110;
localparam ALU_SLL                             = 5'b00111;
localparam ALU_SRL                             = 5'b01000;
localparam ALU_SRA                             = 5'b01001;
localparam ALU_PASS_OPERAND                    = 5'b01010;

`endif
