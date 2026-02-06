`include "../../include/CORE_CONSTANTS.vh"

module extension_wr #(parameter XLEN = 64)(
    input      [XLEN-1:0]  extend_in,  //Before extension
    output reg [XLEN-1:0]  extend_out, //After extension
    output reg [XLEN-1:0]  bit_mask,

    //Control
    input [2:0]            extension_type,
    input [1:0]            extension_start_addr
);

localparam EXT_32 = XLEN - 32;
localparam EXT_16 = XLEN - 16;
localparam EXT_8 = XLEN - 8;

//Implementation
always @( * ) begin
    //Default values
    extend_out = {XLEN{1'b0}};
    bit_mask   = {XLEN{1'b0}};

    case(extension_type)
        `FORWARD_INPUT:begin
            extend_out = extend_in;
            bit_mask   = {XLEN{1'b1}};
        end

        `ZERO_EXTEND_32:begin
            extend_out = {{EXT_32{1'b0}}, extend_in[31:0]};
            bit_mask =   {{EXT_32{1'b0}},      {32{1'b1}}};
        end
        
        `ZERO_EXTEND_16:begin
            case (extension_start_addr)
                2'd0: begin
                    extend_out = {{EXT_32{1'b0}}, {16'd0,          extend_in[15:0]}};
                    bit_mask =   {{EXT_32{1'b0}}, {16'd0,               {16{1'b1}}}};
                end
                2'd1: begin
                    extend_out = {{EXT_32{1'b0}}, {8'd0, extend_in[15:0],     8'd0}};
                    bit_mask =   {{EXT_32{1'b0}}, {8'd0,      {16{1'b1}},     8'd0}};
                end
                2'd2: begin
                    extend_out = {{EXT_32{1'b0}}, {extend_in[15:0],           16'd0}};
                    bit_mask =   {{EXT_32{1'b0}}, {     {16{1'b1}},           16'd0}};
                end
            endcase
        end
        `ZERO_EXTEND_8:begin
            case (extension_start_addr)
                2'd0: begin
                    extend_out = {{EXT_32{1'b0}}, {24'd0,          extend_in[7:0]}};
                    bit_mask =   {{EXT_32{1'b0}}, {24'd0,               {8{1'b1}}}};
                end
                2'd1: begin
                    extend_out = {{EXT_32{1'b0}}, {16'd0, extend_in[7:0],     8'd0}};
                    bit_mask =   {{EXT_32{1'b0}}, {16'd0,      {8{1'b1}},     8'd0}};
                end
                2'd2: begin
                    extend_out = {{EXT_32{1'b0}}, {8'd0, extend_in[7:0],     16'd0}};
                    bit_mask =   {{EXT_32{1'b0}}, {8'd0,      {8{1'b1}},     16'd0}};
                end
                2'd3: begin
                    extend_out = {{EXT_32{1'b0}}, {extend_in[7:0],           24'd0}};
                    bit_mask =   {{EXT_32{1'b0}}, {     {8{1'b1}},           24'd0}};
                end
            endcase
        end

        `MEM_NOT_USED:begin
            extend_out = {XLEN{1'b0}};
            bit_mask   = {XLEN{1'b0}};
        end
    endcase

end


endmodule