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

    // Latches - needed to model the behaviour of the memory
    reg [ADDR_LINES-1:0] addr_r;
    reg [ROW_WIDTH-1:0]  data_in_r;
    reg                  we_r;
    reg                  cs_r;
    integer i;

    //Initialize the memory with the contents of the specified file
    initial begin
        // $readmemh reads hexadecimal values from the specified file
        if(FILE_LOAD == 1)begin
            $readmemh(MEM_FILE, memory);
            $display("INFO: Initialized ROM from file: %s", MEM_FILE);    
        end
    end

    // Capture address, data and control on the rising edge
    always @(posedge clk) begin
        cs_r      = cs;
        addr_r    = addr;
        data_in_r = data_in;
        we_r      = we;
    end
    // Perform memory access on the falling edge (half-cycle later)
    always @(negedge clk) begin
        if (cs_r) begin
            if (we_r) begin
                memory[addr_r] <= data_in_r;
            end
            else begin
                data_out <= memory[addr_r];
            end
        end
    end
endmodule
