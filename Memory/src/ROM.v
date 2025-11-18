module ROM #(parameter XLEN = 32, parameter MEM_FILE = "file_example.mem")(
    input clk,
    input reset,
    input cs,
    input  [XLEN-1:0] addr,
    output reg [XLEN-1:0] data_out

);

reg [7:0] memory [XLEN-1:0];

//Initialize the memory with the contents of the specified file
initial begin
    // $readmemh reads hexadecimal values from the specified file
    $readmemh(MEM_FILE, memory);
    $display("INFO: Initialized ROM from file: %s", MEM_FILE);
end

always @(negedge clk) begin
    if (cs) begin
       data_out = {memory[addr], memory[addr+1], memory[addr+2], memory[addr+3]}; 
    end
end


endmodule