module memories_top #(parameter XLEN = 32)(
    input clk,
    input reset,
    input we,

    input PMEM_cs,
    input DMEM_cs,
    input [XLEN-1:0] EIAB, // External Instruction Address Bus
    output [XLEN-1:0] EIB, //  External Instruction Bus
    input [XLEN-1:0] EMDB_out,   //External data bus input
    input [XLEN-1:0] EMAB,      //External data bus address
    output [XLEN-1:0] EMDB_in  //External data bus output
);

//Module Implementation

ROM #(.XLEN(XLEN), .DEPTH(1024), .MEM_FILE("PMEM_content.mem")) PMEM(
    .clk(clk),
    .reset(reset),
    .cs(PMEM_cs),
    .addr(EIAB),
    .data_out(EIB)
);

RAM #(.XLEN(XLEN), .MEM_FILE("DMEM_content.mem")) DMEM(
    .clk(clk),
    .reset(reset),
    .we(we),
    .cs(DMEM_cs),
    .data_in(EMDB_out),
    .addr(EMAB),
    .data_out(EMDB_in)
);

endmodule