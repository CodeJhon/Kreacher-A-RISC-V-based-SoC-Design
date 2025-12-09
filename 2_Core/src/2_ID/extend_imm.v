`include "../../include/CORE_CONSTANTS.vh"

module extend_imm #(parameter XLEN = 32)(
    input      [XLEN-1:0] in, //Before extension
    output reg [XLEN-1:0] out, //After extension

    //Control
    input [2:0]           imm_type
);

//Parameters of extension according to the imm type
localparam EXTENSION_I_S = XLEN - 11;
localparam EXTENSION_B = XLEN - 12;
localparam EXTENSION_J = XLEN - 20;

always @(imm_type, in) begin
    case (imm_type)
        `I_IMMEDIATE: out = {{EXTENSION_I_S{in[31]}},in[30:25],in[24:21],in[20]};
        `S_IMMEDIATE: out = {{EXTENSION_I_S{in[31]}},in[30:25],in[11:8],in[7]};
        `B_IMMEDIATE: out = {{EXTENSION_B{in[31]}},in[7],in[30:25],in[11:8],1'b0};
        `U_IMMEDIATE: out = {in[31],in[30:20],in[19:12],12'd0};
        `J_IMMEDIATE: out = {{EXTENSION_J{in[31]}},in[19:12],in[20],in[30:25],in[24:21],1'b0};
        `IMM_NOT_USED: out = 0;
        default:      out = 0;
    endcase
end

endmodule