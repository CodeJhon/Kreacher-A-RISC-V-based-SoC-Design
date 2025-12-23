`timescale 1ns/1ps

module RAM #(parameter XLEN = 64, parameter DEPTH = 1024, parameter MEM_FILE = "file_example.txt", parameter DELAY = 4)(
    input clk,
    input reset,
    input we,
    input cs,
    input  [XLEN-1:0] data_in,
    input  [XLEN-1:0] addr,
    output [XLEN-1:0] data_out

);

integer i;

wire [16:0] internal_address;

assign internal_address = addr[16:0];

reg [7:0] memory [DEPTH-1:0];

//Initialize the memory with the contents of the specified file
initial begin
    // $readmemh reads hexadecimal values from the specified file
    $readmemh(MEM_FILE, memory);
    $display("INFO: Initialized RAM from file: %s", MEM_FILE);
end

always @(posedge clk) begin
    if(reset)begin
        for (i=0; i<=DEPTH-1;i = i+1) begin
            memory[i] <= 8'd0;
        end
    end
    else if(we && cs)begin
        memory[internal_address+7] <= data_in[7:0];
        memory[internal_address+6] <= data_in[15:8];
        memory[internal_address+5] <= data_in[23:16];
        memory[internal_address+4] <= data_in[31:24];
        memory[internal_address+3] <= data_in[39:32];
        memory[internal_address+2] <= data_in[47:40];
        memory[internal_address+1] <= data_in[55:48];
        memory[internal_address]   <= data_in[63:56];
    end
end

//WARNING: In a real design, make sure that DELAY is not more than half the cycle of your processor, otherwise probably change architecture (Partition decode into 2 stages)
assign #DELAY data_out = cs ? {memory[internal_address], memory[internal_address+1], memory[internal_address+2], memory[internal_address+3], memory[internal_address+4], memory[internal_address+5], memory[internal_address+6], memory[internal_address+7]} : {XLEN{1'b0}};


endmodule