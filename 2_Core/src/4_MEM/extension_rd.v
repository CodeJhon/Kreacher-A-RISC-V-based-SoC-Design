`include "../../include/CORE_CONSTANTS.vh"

module extension_rd #(parameter XLEN = 64)(
    input      [XLEN-1:0]  in,  //Before extension
    output reg [XLEN-1:0]  out, //After extension

    //Control
    input [2:0]            extension_type
);

localparam EXT_32 = XLEN - 32;
localparam EXT_16 = XLEN - 16;
localparam EXT_8 = XLEN - 8;

//Implementation
always @(extension_type, in) begin
    case(extension_type)
        `FORWARD_INPUT:  out = in;

        `SIGN_EXTEND_32: out = {{EXT_32{in[XLEN-1]}},in[XLEN-1:XLEN-32]};
        `SIGN_EXTEND_16: out = {{EXT_16{in[XLEN-1]}},in[XLEN-1:XLEN-16]};
        `SIGN_EXTEND_8:  out = {{EXT_8{in[XLEN-1]}},in[XLEN-1:XLEN-8]};

        `ZERO_EXTEND_32: out = {{EXT_32{1'b0}},in[XLEN-1:XLEN-32]};
        `ZERO_EXTEND_16: out = {{EXT_16{1'b0}},in[XLEN-1:XLEN-16]};
        `ZERO_EXTEND_8:  out = {{EXT_8{1'b0}},in[XLEN-1:XLEN-8]};

        `MEM_NOT_USED: out = 0;
        default:         out = 0; 
    endcase

end


endmodule