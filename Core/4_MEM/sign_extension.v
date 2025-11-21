`include "../CORE_CONSTANTS.vh"

module sign_extension #(parameter XLEN = 32)(
    input      [XLEN-1:0]  in,  //Before extension
    output reg [XLEN-1:0]  out, //After extension

    //Control
    input [2:0]            extension_type
);

localparam EXT_16 = XLEN - 16;
localparam EXT_8 = XLEN - 8;

//Implementation
always @(extension_type) begin
    case(extension_type)
        `FORWARD_INPUT:  out = in;
        `SIGN_EXTEND_16: out = {{EXT_16{in[15]}},in[15:0]};
        `SIGN_EXTEND_8:  out = {{EXT_8{in[7]}},in[7:0]};
        `ZERO_EXTEND_16: out = {{EXT_16{1'b0}},in[15:0]};
        `ZERO_EXTEND_8:  out = {{EXT_8{1'b0}},in[7:0]};
        `MEM_NOT_USED: out = 0;
        default:         out = 0; 
    endcase

end


endmodule