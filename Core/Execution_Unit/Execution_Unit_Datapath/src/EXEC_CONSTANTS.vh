// Execution Unit constants
`ifndef EXEC_CONSTANTS_VH
`define EXEC_CONSTANTS_VH

//Selecting source / destination
localparam SEL_REGFILE         = 3'b000;
localparam SEL_PC              = 3'b001;
localparam SEL_T1              = 3'b010;
localparam SEL_OPERAND        = 3'b011;

//Select writer 
localparam SEL_BUS_A    = 2'b00;
localparam SEL_BUS_B    = 2'b01;
localparam SEL_ALU_OUT  = 2'b10;

//Select ALU operands
//general
localparam OP_BUS              =  2'b00;
//OPA
localparam OP_K_NEXT_INSTR     =  2'b01;
localparam OP_K_LUI            =  2'b10;
//OPB
localparam OP_IMM              =  2'b01;

`endif
