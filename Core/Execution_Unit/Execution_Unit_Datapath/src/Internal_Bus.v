module Internal_Bus(
    input [31:0] regfile_in,
    input [31:0] PC_in,
    input [31:0] T1_in,
    
    input [2:0] sel_in,
    input [2:0] sel_out,
    
    output reg [31:0] operand,
    output reg [31:0] regfile_out,
    output reg [31:0] PC_out,
    output reg [31:0] T1_out
    );

`include "../EXEC_CONSTANTS.vh"
reg [31:0] bus_in;

always@(regfile_in, PC_in,T1_in,sel_in,sel_out)begin
    bus_in = 32'd0;
    case(sel_in)
        IN_REGFILE:     bus_in = regfile_in;
        IN_PC:          bus_in = PC_in;
        IN_T1:          bus_in = T1_in;
        default:        bus_in = 32'd0;
    endcase
    case(sel_out)
        OUT_REGFILE:    regfile_out = bus_in;
        OUT_PC:         PC_out      = bus_in;
        OUT_T1:         T1_out      = bus_in;
        OUT_OPERAND:    operand     = bus_in;
        default: ; // do nothing
    endcase 
end

endmodule
