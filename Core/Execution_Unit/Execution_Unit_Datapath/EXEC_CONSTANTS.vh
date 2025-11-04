// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH


//Bus A
localparam IN_REGFILE         = 3'b000;
localparam IN_PC              = 3'b001;
localparam IN_T1              = 3'b010;

localparam OUT_REGFILE        = 3'b000;
localparam OUT_PC             = 3'b001;
localparam OUT_T1             = 3'b010;
localparam OUT_OPERAND        = 3'b011; 

`endif
