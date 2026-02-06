`include "../../include/CORE_CONSTANTS.vh"

module extension_rd #(parameter XLEN = 64)(
    input      [XLEN-1:0]  extend_in,  //Before extension
    output reg [XLEN-1:0]  extend_out, //After extension

    //Control
    input [2:0]            extension_type,
    input [2:0]            extension_start_addr
);

localparam EXT_32 = XLEN - 32;
localparam EXT_16 = XLEN - 16;
localparam EXT_8 = XLEN - 8;

//Implementation
always @( * ) begin
    case(extension_type)
        `FORWARD_INPUT:  extend_out = extend_in;

        `SIGN_EXTEND_32:begin
            case(extension_start_addr[2])
            1'b0:extend_out = {{EXT_32{extend_in[XLEN-33]}},extend_in[XLEN-33:0]};
            1'b1:extend_out = {{EXT_32{extend_in[XLEN-1]}},extend_in[XLEN-1:XLEN-32]};
            endcase
        end
        `SIGN_EXTEND_16:begin
            case(extension_start_addr[2:1])        
            2'b00:extend_out = {{EXT_16{extend_in[XLEN-49]}},extend_in[XLEN-49:0]};
            2'b01:extend_out = {{EXT_16{extend_in[XLEN-33]}},extend_in[XLEN-33:XLEN-48]};
            2'b10:extend_out = {{EXT_16{extend_in[XLEN-17]}},extend_in[XLEN-17:XLEN-32]};
            2'b11:extend_out = {{EXT_16{extend_in[XLEN-1]}},extend_in[XLEN-1:XLEN-16]};
            endcase
        end
        `SIGN_EXTEND_8:begin
            case(extension_start_addr)
            3'b000:extend_out = {{EXT_8{extend_in[XLEN-57]}},extend_in[XLEN-57:0]};
            3'b001:extend_out = {{EXT_8{extend_in[XLEN-49]}},extend_in[XLEN-49:XLEN-56]};
            3'b010:extend_out = {{EXT_8{extend_in[XLEN-41]}},extend_in[XLEN-41:XLEN-48]};
            3'b011:extend_out = {{EXT_8{extend_in[XLEN-33]}},extend_in[XLEN-33:XLEN-40]};
            3'b100:extend_out = {{EXT_8{extend_in[XLEN-25]}},extend_in[XLEN-25:XLEN-32]};
            3'b101:extend_out = {{EXT_8{extend_in[XLEN-17]}},extend_in[XLEN-17:XLEN-24]};
            3'b110:extend_out = {{EXT_8{extend_in[XLEN-9]}},extend_in[XLEN-9:XLEN-16]};
            3'b111:extend_out = {{EXT_8{extend_in[XLEN-1]}},extend_in[XLEN-1:XLEN-8]};
            endcase
        end
        `ZERO_EXTEND_32:begin
            case(extension_start_addr[2])
            1'b0:extend_out = {{EXT_32{1'b0}},extend_in[XLEN-33:0]};
            1'b1:extend_out = {{EXT_32{1'b0}},extend_in[XLEN-1:XLEN-32]};
            endcase
        end
        `ZERO_EXTEND_16:begin
            case(extension_start_addr[2:1])        
            2'b00:extend_out = {{EXT_16{1'b0}},extend_in[XLEN-49:0]};
            2'b01:extend_out = {{EXT_16{1'b0}},extend_in[XLEN-33:XLEN-48]};
            2'b10:extend_out = {{EXT_16{1'b0}},extend_in[XLEN-17:XLEN-32]};
            2'b11:extend_out = {{EXT_16{1'b0}},extend_in[XLEN-1:XLEN-16]};
            endcase
        end
        `ZERO_EXTEND_8:begin
            case(extension_start_addr)
            3'b000:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-57:0]};
            3'b001:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-49:XLEN-56]};
            3'b010:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-41:XLEN-48]};
            3'b011:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-33:XLEN-40]};
            3'b100:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-25:XLEN-32]};
            3'b101:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-17:XLEN-24]};
            3'b110:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-9:XLEN-16]};
            3'b111:extend_out = {{EXT_8{1'b0}},extend_in[XLEN-1:XLEN-8]};
            endcase
        end
        `MEM_NOT_USED: extend_out = {XLEN{1'b0}};
    endcase
end

endmodule