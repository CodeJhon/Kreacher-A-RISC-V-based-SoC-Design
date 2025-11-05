module Internal_Bus(
    input [31:0] regfile_source,
    input [31:0] PC_source,
    input [31:0] T1_source,
    
    input [2:0] sel_source,
    input [2:0] sel_destination,
    
    output reg [31:0] operand,
    output reg [31:0] regfile_destination,
    output reg [31:0] PC_destination,
    output reg [31:0] T1_destination
    );

`include "./EXEC_CONSTANTS.vh"
reg [31:0] bus_source;

always@(regfile_source, PC_source,T1_source,sel_source,sel_destination)begin
    bus_source = 32'd0;
    case(sel_source)
        SEL_REGFILE:     bus_source = regfile_source;
        SEL_PC:          bus_source = PC_source;
        SEL_T1:          bus_source = T1_source;
        default:        bus_source = 32'd0;
    endcase
    case(sel_destination)
        SEL_REGFILE:    regfile_destination = bus_source;
        SEL_PC:         PC_destination      = bus_source;
        SEL_T1:         T1_destination      = bus_source;
        SEL_OPERAND:    operand     = bus_source;
        default: ; // do nothing
    endcase 
end

endmodule
