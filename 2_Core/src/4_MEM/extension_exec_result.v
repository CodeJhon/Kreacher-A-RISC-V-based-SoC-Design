`include "../../include/CORE_CONSTANTS.vh"

module extension_exec_result #(parameter XLEN = 64) (
    input      [XLEN-1:0] in, //Before extension
    output reg [XLEN-1:0] out, //After extension

    //Control
    input extension_type
);
    
localparam EXTENSION = XLEN - 32;

always @(in, extension_type) begin
    case (extension_type)
        `RESULT_64: out = in;
        `RESULT_32: out = {{EXTENSION{in[31]}}, in[31:0]};
        default:    out = 0;
    endcase
end

endmodule