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

memories_top #(.XLEN(XLEN)) memories_top_inst (
    //Global
    .clk(clk),
    .reset_n(reset_n),

    //PMEM signals
    .PMEM_cs(1'b1),
    .EIAB(EIAB),
    .EIB(EIB),

    //DMEM signals
    .DMEM_cs(1'b1),
    .DMEM_we(EMCB),
    .EMAB(EMAB),
    .EMDB_out(EMDB_out),
    .EMDB_in(EMDB_in)
    
);



endmodule