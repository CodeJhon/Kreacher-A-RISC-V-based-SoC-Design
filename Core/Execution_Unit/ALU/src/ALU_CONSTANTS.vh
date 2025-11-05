// ALU constants
`ifndef ALU_CONSTANTS_VH
`define ALU_CONSTANTS_VH

localparam ALU_ADD                             = 5'b0000;
localparam ALU_SUB                             = 5'b0001;
localparam ALU_SLT                             = 5'b0010;
localparam ALU_SLTU                            = 5'b0011;
localparam ALU_AND                             = 5'b0100;
localparam ALU_OR                              = 5'b0101;
localparam ALU_XOR                             = 5'b0110;
localparam ALU_SLL                             = 5'b0111;
localparam ALU_SRL                             = 5'b1000;
localparam ALU_SRA                             = 5'b1001;

`endif
