module kreacher_top #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //TEMPORARY (ONLY FOR TB PURPOSES)
    input [1:0]      sel_next_PC,

    input [2:0]      imm_type,
    input            regfile_we,

    input [1:0]      sel_opa,
    input [1:0]      sel_opb,
    input [4:0]      sel_op,

    input            mem_wr_en,
    input [2:0]      val_rd_type,
    input [2:0]      val_wr_type,
    
    input [2:0]      sel_writeback
);

// ------------------------------------------------ Buses
//PMEM
wire [XLEN-1:0] EIB;  //External Instruction Bus
wire [XLEN-1:0] EIAB; //External Instruction Address Bus
//DMEM
wire [XLEN-1:0] EMAB;            //External Memory Address Bus
wire            EMCB;            //External Memory Control Bus
wire [XLEN-1:0] EMDB_out;        //External Memory Data Bus, output for the core, input for the external memory
wire [XLEN-1:0] EMDB_in;         //External Memory Data Bus, input for the core, output for the external memory

core #(.XLEN(XLEN)) core_inst (
    .clk(clk), 
    .reset(reset),
    //PMEM signals
    .EIB(EIB),
    .EIAB(EIAB),

    //DMEM signals
    .EMAB(EMAB),
    .EMCB(EMCB),
    .EMDB_out(EMDB_out),
    .EMDB_in(EMDB_in),

    //TEMPORARY (ONLY FOR TB PURPOSES)
    .sel_next_PC(sel_next_PC),
    .imm_type(imm_type),
    .regfile_we(regfile_we),
    .sel_opa(sel_opa),
    .sel_opb(sel_opb),
    .sel_op(sel_op),
    .mem_wr_en(mem_wr_en),
    .val_rd_type(val_rd_type),
    .val_wr_type(val_wr_type),
    .sel_writeback(sel_writeback)
);

memories_top #(.XLEN(XLEN)) memories_top_inst (
    //Global
    .clk(clk),
    .reset(reset),

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