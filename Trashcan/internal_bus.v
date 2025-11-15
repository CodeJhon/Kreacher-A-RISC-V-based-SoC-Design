`include "./EXEC_CONSTANTS.vh"

module internal_bus(
    //Sources
    input [31:0] regbank_source,
    
    //Destinations
    output reg [31:0] regbank_dest,
    output reg [31:0] ALU_dest,
    
    //Control
    input [1:0] sel_source,
    input [1:0] sel_dest,
    
    output reg ALU_wr_en
    
    );

reg [31:0] bus_source;

always@(regbank_source,sel_source,sel_dest)begin    
    bus_source = 32'd0; //Default
    if({sel_source,sel_dest} == {`SEL_REGBANK,`SEL_ALU}) ALU_wr_en = 1'b1;
    else                                                 ALU_wr_en = 1'b0;
    case(sel_source)
        `SEL_REGBANK:     bus_source = regbank_source;
        default:          bus_source = 32'd0;
    endcase
    case(sel_dest)
        `SEL_REGBANK:    regbank_dest = bus_source;
        `SEL_ALU:        ALU_dest     = bus_source;
        default:; 
    endcase 
end

endmodule
