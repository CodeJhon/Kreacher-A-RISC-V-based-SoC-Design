// =============================================================================
// File        : extension_exec_result.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Extends execution results to 32 or 64 bits based on result type control.
// =============================================================================

`include "../../include/CORE_CONSTANTS.vh"

module extension_exec_result #(parameter XLEN = 64) (
    input      [XLEN-1:0] extend_in, //Before extension
    output reg [XLEN-1:0] extend_out, //After extension

    //Control
    input extension_type
);
    
localparam EXTENSION = XLEN - 32;

always @(extend_in, extension_type) begin
    case (extension_type)
        `RESULT_64: extend_out = extend_in;
        `RESULT_32: extend_out = {{EXTENSION{extend_in[31]}}, extend_in[31:0]};
    endcase
end

endmodule