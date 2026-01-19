`include "../../include/CORE_CONSTANTS.vh"

module build_imm #(parameter XLEN = 64)(
    input      [31:0]     build_in, //Before extension
    output reg [XLEN-1:0] build_out, //After extension

    //Control
    input [2:0]           imm_type
);

//Parameters of extension according to the imm type
localparam EXTENSION_I_S = XLEN - 11;
localparam EXTENSION_B = XLEN - 12;
localparam EXTENSION_U = XLEN - 31;
localparam EXTENSION_J = XLEN - 20;
localparam EXTENSION_ZICSR = XLEN - 5;

always @(imm_type, build_in) begin
    case (imm_type)
        `I_IMMEDIATE:       build_out = {{EXTENSION_I_S{build_in[31]}},build_in[30:25],build_in[24:21],build_in[20]};
        `S_IMMEDIATE:       build_out = {{EXTENSION_I_S{build_in[31]}},build_in[30:25],build_in[11:8],build_in[7]};
        `B_IMMEDIATE:       build_out = {{EXTENSION_B{build_in[31]}},build_in[7],build_in[30:25],build_in[11:8],1'b0};
        `U_IMMEDIATE:       build_out = {{EXTENSION_U{build_in[31]}},build_in[30:20],build_in[19:12],12'd0};
        `J_IMMEDIATE:       build_out = {{EXTENSION_J{build_in[31]}},build_in[19:12],build_in[20],build_in[30:25],build_in[24:21],1'b0};
        `ZICSR_IMMEDIATE:   build_out = {{EXTENSION_ZICSR{1'b0}}, build_in[19:15]};
        `IMM_NOT_USED:      build_out = 0;
        default:            build_out = 0;
    endcase
end

endmodule