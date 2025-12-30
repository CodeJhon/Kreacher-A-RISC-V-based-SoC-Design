module ROM #(parameter XLEN = 64, parameter DEPTH= 1024,parameter MEM_FILE = "file_example.mem", parameter DELAY = 4)(
    input clk,
    input reset,
    input cs,
    input  [16:0] addr,
    output [31:0] data_out

);

reg [31:0] memory [DEPTH-1:0];

//Initialize the memory with the contents of the specified file
initial begin
    // $readmemh reads hexadecimal values from the specified file
    $readmemh(MEM_FILE, memory);
    $display("INFO: Initialized ROM from file: %s", MEM_FILE);
end

//WARNING: In a real design, make sure that DELAY is not more than half the cycle of your processor, otherwise probably change architecture (Partition decode into 2 stages)
assign #DELAY data_out = cs ? memory[addr] : {XLEN{1'b0}};


endmodule