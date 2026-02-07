module HM_1P_GF28SLP_1024x32_1cr #(
    parameter ADDR_LINES = 10,
    parameter WORDS = 1024,
    parameter FILE_LOAD = 0,
    parameter ROW_WIDTH = 32,
    parameter MEM_FILE = "file_example.mem",
    parameter INITFILE = "none"
)(
    input CLK_I,
    input CS_I,
    input WE_I,
    input RE_I,
    input [ADDR_LINES-1:0]ADDR_I,
    input [ROW_WIDTH-1:0]BM_I,
    input [ROW_WIDTH-1:0]DW_I,
    
    output reg [ROW_WIDTH-1:0]DR_O,

    input [1:0]     DLYCLK,
    input [1:0]     DLYH,
    input [1:0]     DLYL
);

    reg [ROW_WIDTH-1:0] memory [0:WORDS-1];

    integer i;

    //Initialize the memory with the contents of the specified file
    initial begin
        // $readmemh reads hexadecimal values from the specified file
        if(FILE_LOAD == 1)begin
            $readmemh(MEM_FILE, memory);
            $display("INFO: Initialized ROM from file: %s", MEM_FILE);    
        end
    end

    always@(posedge CLK_I)begin
        if(CS_I)begin
            if(WE_I)begin
                // if(RE_I && WE_I) DR_O <= (DW_I & BM_I) | (memory[ADDR_I] & ~BM_I);
                // else DR_O <= DR_O;
                memory[ADDR_I] <= (DW_I & BM_I) | (memory[ADDR_I] & ~BM_I);
            end
            else if(RE_I)begin
                DR_O <=  memory[ADDR_I];
            end
        end
    end

endmodule