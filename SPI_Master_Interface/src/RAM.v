`timescale 1ns/1ps

module RAM #(
    parameter WORDS = 8192,         // 8K entries
    parameter ADDR_W = 14,           // 2^13 = 8192
    parameter IXLEN = 64
)(
    input                      clk,
    input                      reset,    // Reset usually not used for BRAM data
    input                      cs,
    input                      we,
    input      [ADDR_W-1:0]    addr,     
    input      [IXLEN-1:0]     data_in,
    output reg [IXLEN-1:0]     data_out  // Fixed: was [IXLEN:0]
);

    // Use IXLEN parameter for memory width
    reg [IXLEN-1:0] memory [0:WORDS-1];

    // Initialize memory from file
    initial begin
        $readmemh("mem_init.mem", memory);
    end

    // Synthesis-friendly RAM logic
    always @(posedge clk) begin
        if (cs) begin
            if (we) begin
                memory[addr] <= data_in;
            end else begin
                data_out <= memory[addr];
            end
        end
    end
endmodule