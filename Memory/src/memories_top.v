module memories_top #(parameter XLEN = 32)(
    input clk,
    input reset,
    input we,

    //Instruction Memory (PMEM)
    input PMEM_cs,
    input [XLEN-1:0] EIAB, // External Instruction Address Bus
    output [XLEN-1:0] EIB //  External Instruction Bus
);

//Module Implementation

ROM #(.XLEN(XLEN), .MEM_FILE("PMEM_content.mem")) PMEM(
    .clk(clk),
    .reset(reset),
    .cs(PMEM_cs),
    .addr(EIAB),
    .data_out(EIB)
);



endmodule