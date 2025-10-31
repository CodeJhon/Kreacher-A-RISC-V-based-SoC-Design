// ALU constants
`ifndef ALU_CONSTANTS_VH
`define ALU_CONSTANTS_VH

localparam ADD                             = 5'b00000;
localparam SUBSTRACT                       = 5'b00001;
localparam SET_LESS_THAN_SIGNED            = 5'b00010;
localparam SET_LESS_THAN_UNSIGNED          = 5'b00011;
localparam BITWISE_AND                     = 5'b00100;
localparam BITWISE_OR                      = 5'b00101;
localparam BITWISE_XOR                     = 5'b00110;
localparam SHIFT_LEFT_LOGICAL              = 5'b00111;
localparam SHIFT_RIGHT_LOGICAL             = 5'b01000;
localparam SHIFT_RIGHT_ARITHMETIC          = 5'b01001;
localparam PASS_OPERAND                    = 5'b01010;

`endif
