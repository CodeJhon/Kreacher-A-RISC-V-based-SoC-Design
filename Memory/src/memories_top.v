module memories_top #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,
    

    //PMEM signals
    input PMEM_cs,
    input  [XLEN-1:0] EIAB, // External Instruction Address Bus
    output [XLEN-1:0] EIB, //  External Instruction Bus

    //DMEM signals
    input             DMEM_cs,
    input             DMEM_we,
    input  [XLEN-1:0] EMAB,      //External data bus address
    output [XLEN-1:0] EMDB_in,  //External data bus output
    input  [XLEN-1:0] EMDB_out  //External data bus input
    
);

//Module Implementation

ROM #(.XLEN(XLEN), .DEPTH(1024), .MEM_FILE("PMEM_content.mem")) PMEM(
    .clk(clk),
    .reset(reset),
    .cs(PMEM_cs),
    .addr(EIAB),
    .data_out(EIB)
);

RAM #(.XLEN(XLEN), .DEPTH(1024), .MEM_FILE("DMEM_content.mem")) DMEM(
    .clk(clk),
    .reset(reset),
    .we(we),
    .cs(DMEM_cs),
    .data_in(EMDB_out),
    .addr(EMAB),
    .data_out(EMDB_in)
);

endmodule