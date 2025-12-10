module ROM #(parameter XLEN = 64, parameter DEPTH= 1024,parameter MEM_FILE = "file_example.mem")(
    input clk,
    input reset,
    input cs,
    input  [XLEN-1:0] addr,
    output reg [31:0] data_out

);

wire [16:0] internal_address;

assign internal_address = addr[16:0];

reg [7:0] memory [DEPTH-1:0];

//Initialize the memory with the contents of the specified file
initial begin
    // $readmemh reads hexadecimal values from the specified file
    $readmemh(MEM_FILE, memory);
    $display("INFO: Initialized ROM from file: %s", MEM_FILE);
end

always @(negedge clk) begin
    if (cs) begin
       data_out = {memory[internal_address], memory[internal_address+1], memory[internal_address+2], memory[internal_address+3]} ;
    end
end


endmodule