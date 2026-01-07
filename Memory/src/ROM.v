module ROM #(parameter XLEN = 64, parameter DEPTH= 1024,parameter MEM_FILE = "file_example.mem", parameter DELAY = 4)(
    input clk,
    input reset,
    input cs,
    input  [16:0] addr,
    output reg  [31:0] data_out

);

reg [31:0] memory [DEPTH-1:0];

//Initialize the memory with the contents of the specified file
initial begin
    // $readmemh reads hexadecimal values from the specified file
    $readmemh(MEM_FILE, memory);
    $display("INFO: Initialized ROM from file: %s", MEM_FILE);
end

always @(posedge clk) begin
    if(cs) data_out = memory[addr];
    else   data_out = {XLEN{1'b0}};
end


endmodule