`timescale 1ns/1ps
module odd_even_handler
#(
    parameter IXLEN = 32,   // Instruction width
    parameter XLEN  = 64,   // Full data width
    parameter ADDR_BYTE_W = 17
)
(
    // Internal memory interface
    input clk,
    input reset_n,
    input  [XLEN-1:0]      data_in,
    input  [ADDR_BYTE_W-1:0] addr_handler,
    input  addr_data_valid,
    input  addr_inst_valid,
    output [IXLEN-1:0]     inst_out,
    input  we0,
    input  we1,
    input  cs0,
    input  cs1,
    output [XLEN-1:0]      data_out,

    // PRAM interface
    input  [IXLEN-1:0]     data_out_even,
    input  [IXLEN-1:0]     data_out_odd,
    output [IXLEN-1:0]     data_in_even,
    output [IXLEN-1:0]     data_in_odd,
    output [9:0]           addr,        // 2^10 = 1024
    output cs_even,
    output cs_odd,
    output we_even,
    output we_odd
);

    reg macro_sel_old;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            macro_sel_old <= 1'b0;
        end
        else if (addr_inst_valid) begin
            macro_sel_old <= addr_handler[2];
        end
    end

    assign data_in_even = data_in[31:0];
    assign data_in_odd  = data_in[63:32];
    
    assign addr         = addr_handler[12:3];

    assign cs_odd  = addr_data_valid ? (cs0 || cs1) : cs1;
    assign cs_even = addr_data_valid ? (cs0 || cs1) : cs0;

    assign we_odd  = we1;
    assign we_even = we0;

    assign data_out  = {data_out_odd, data_out_even};
    assign inst_out   = macro_sel_old ? data_out_odd : data_out_even;

endmodule

