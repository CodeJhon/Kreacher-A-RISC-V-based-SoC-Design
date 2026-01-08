module core_and_mem #(parameter XLEN = 64)(
    `ifndef SYNTHESIS 
        output           commit_valid,
        output [XLEN-1:0]   commit_PC,
        output [31:0]   commit_instruction,
        output [4:0]     commit_rd_addr,
        output [XLEN-1:0]   commit_rd_value,
    `endif
    
    //Global
    input clk,
    input reset_n

);

// ------------------------------------------------ Buses
//PMEM
wire [31:0]     EIB;  //External Instruction Bus
wire [16:0]     EIAB;  //External Instruction Address Bus
//DMEM
wire [XLEN-1:0] EMAB;            //External Memory Address Bus
wire            EMCB;            //External Memory Control Bus
wire [XLEN-1:0] EMDB_out;        //External Memory Data Bus, output for the core, input for the external memory
wire [XLEN-1:0] EMDB_in;         //External Memory Data Bus, input for the core, output for the external memory

core #(.XLEN(XLEN)) core_inst (

`ifndef SYNTHESIS
    .commit_valid(commit_valid),
    .commit_PC(commit_PC),
    .commit_instruction(commit_instruction),
    .commit_rd_addr(commit_rd_addr),
    .commit_rd_value(commit_rd_value),
`endif
    .clk(clk), 
    .reset_n(reset_n),
    
    //Control
    .pause_core(1'b0),

    //PMEM signals
    .EIB(EIB),
    .EIAB(EIAB),

    //DMEM signals
    .EMAB(EMAB),
    .EMCB(EMCB),
    .EMDB_out(EMDB_out),
    .EMDB_in(EMDB_in)

);

RAM #( .ADDR_LINES(17),
        .WORDS(10240), 
        .FILE_LOAD(1),
        .ROW_WIDTH(32),
        .MEM_FILE("PMEM_content.mem")
) program_memory (
    
    .clk(clk),
    .we(1'b0),
    .cs(1'b1),
    .data_in(),
    .addr({2'b00, EIAB[16:2]}),
    .data_out(EIB)
);

RAM #( .ADDR_LINES(14),
        .WORDS  (8192),
        .FILE_LOAD(1),
        .ROW_WIDTH(64),
        .MEM_FILE("DMEM_content.mem")
       ) external_memory (
    
    .clk(clk),
    .we(EMCB),
    .cs(1'b1),
    .data_in(EMDB_out),
    .addr(EMAB[16:0]),
    .data_out(EMDB_in)
);



endmodule