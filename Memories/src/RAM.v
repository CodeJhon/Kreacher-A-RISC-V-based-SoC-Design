`timescale 1ns/1ps
module RAM #(
    parameter ADDR_LINES = 10,
    parameter WORDS = 1024,
    parameter FILE_LOAD = 0,
    parameter ROW_WIDTH = 32,
    parameter MEM_FILE = "file_example.mem"
)(
    input  clk,
    input  cs,
    input  we,
    input  [ADDR_LINES-1:0] addr,        // row index
    input  [ROW_WIDTH-1:0] data_in,
    output reg [ROW_WIDTH-1:0] data_out
);

    reg [ROW_WIDTH-1:0] memory [0:WORDS-1];

    //Initialize the memory with the contents of the specified file
    initial begin
        // $readmemh reads hexadecimal values from the specified file
        if(FILE_LOAD == 1)begin
            $readmemh(MEM_FILE, memory);
            $display("INFO: Initialized ROM from file: %s", MEM_FILE);    
        end
    end

    always @(posedge clk) begin
        if (cs) begin
            if (we) begin
                memory[addr] <= data_in;
            end
            else begin
                data_out <= memory[addr];
            end
        end
    end
endmodule
