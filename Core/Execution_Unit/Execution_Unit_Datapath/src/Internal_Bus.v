`include "./EXEC_CONSTANTS.vh"

module Internal_Bus(
    //Sources
    input [31:0] regbank_source,
    
    //Destinations
    output reg [31:0] regbank_dest,
    output reg [31:0] ALU_dest,
    
    //Control
    input [1:0] sel_source,
    input [1:0] sel_destination
    
    );

reg [31:0] bus_source;

always@(rebank_source,sel_source,sel_destination)begin    
    bus_source = 32'd0; //Default
    case(sel_source)
        `SEL_REGBANK:     bus_source = regbank_source;
        default:          bus_source = 32'd0;
    endcase
    case(sel_destination)
        `SEL_REGBANK:    regbank_dest = bus_source;
        `SEL_ALU:        ALU_dest     = bus_source;
        default:; 
    endcase 
end

endmodule
