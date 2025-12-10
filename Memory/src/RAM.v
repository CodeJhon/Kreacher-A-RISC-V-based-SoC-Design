module RAM #(parameter XLEN = 64, parameter DEPTH = 1024, parameter MEM_FILE = "file_example.txt")(
    input clk,
    input reset,
    input we,
    input cs,
    input  [XLEN-1:0] data_in,
    input  [XLEN-1:0] addr,
    output reg [XLEN-1:0] data_out

);

integer i;

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
        memory[addr+7] <= data_in[7:0];
        memory[addr+6] <= data_in[15:8];
        memory[addr+5] <= data_in[23:16];
        memory[addr+4] <= data_in[31:24];
        memory[addr+3] <= data_in[39:32];
        memory[addr+2] <= data_in[47:40];
        memory[addr+1] <= data_in[55:48];
        memory[addr]   <= data_in[63:56];
    end
end


always @(negedge clk) begin
    if (cs) data_out = {memory[addr], memory[addr+1], memory[addr+2], memory[addr+3], memory[addr+4], memory[addr+5], memory[addr+6], memory[addr+7]}; 
end


endmodule