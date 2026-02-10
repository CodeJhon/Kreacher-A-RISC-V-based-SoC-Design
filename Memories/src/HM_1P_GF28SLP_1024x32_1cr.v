module PMEM_MACRO#(
    parameter INITFILE       = "none",
    parameter P_ADDR_WIDTH   = 1024,
    parameter P_DATA_WIDTH   = 32
)(
    input                       CLK_I,
    input                       CS_I,
    input                       WE_I,
    input                       RE_I,
    input [9:0]                 ADDR_I,
    input [P_DATA_WIDTH-1:0]    BM_I,
    input [P_DATA_WIDTH-1:0]    DW_I,
    
    output reg [P_DATA_WIDTH-1:0]DR_O,

    input [1:0]                 DLYCLK,
    input [1:0]                 DLYH,
    input [1:0]                 DLYL
);
    reg [P_DATA_WIDTH-1:0] memory [0:P_ADDR_WIDTH-1];

    always@(posedge CLK_I)begin
        if(CS_I)begin
            if(WE_I)begin
                memory[ADDR_I] <= (DW_I & BM_I) | (memory[ADDR_I] & ~BM_I);
            end
            else if(RE_I)begin
                DR_O <=  memory[ADDR_I];
            end
        end
    end

endmodule

module HM_1P_GF28SLP_1024x32_1cr #(
    parameter ADDR_LINES = 10,
    parameter WORDS      = 1024,
    parameter FILE_LOAD  = 0,
    parameter ROW_WIDTH  = 32,
    parameter MEM_FILE   = "file_example.mem",
    parameter INITFILE   = "none"
)(
    input                   CLK_I,
    input                   CS_I,
    input                   WE_I,
    input                   RE_I,
    input [ADDR_LINES-1:0]  ADDR_I,
    input [ROW_WIDTH-1:0]   BM_I,
    input [ROW_WIDTH-1:0]   DW_I,
    
    output [ROW_WIDTH-1:0]  DR_O,

    input [1:0]             DLYCLK,
    input [1:0]             DLYH,
    input [1:0]             DLYL
);


    PMEM_MACRO
    #(
        .INITFILE(INITFILE),
        .P_ADDR_WIDTH(WORDS),
        .P_DATA_WIDTH(ROW_WIDTH)
    )
    sram_core_i(
        .CLK_I(CLK_I),
        .ADDR_I(ADDR_I),
        .DW_I(DW_I),
        .BM_I(BM_I),
        .WE_I(WE_I),
        .RE_I(RE_I),
        .CS_I(CS_I),
        .DR_O(DR_O),
        .DLYL(DLYL),
        .DLYH(DLYH),
        .DLYCLK(DLYCLK)
    );

endmodule