`timescale 1ns/1ps
module PRAM #(
    parameter WORDS = 1024
)(
    input  clk,
    input  reset,
    input  cs,
    input  we,
    input  [9:0] addr,        // row index
    input  [31:0] data_in,
    output reg [31:0] data_out
);

    reg [31:0] memory [0:WORDS-1];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < WORDS; i = i + 1)
                memory[i] <= 32'd0;
        end
        else if (cs) begin
            if (we) begin
                memory[addr] <= data_in;
            end
            else begin
                data_out  <= memory[addr];
            end
        end
    end
endmodule

