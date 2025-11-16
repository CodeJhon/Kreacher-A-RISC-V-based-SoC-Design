module core #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset
);

/*
    --- Wire terminology ---
    wire [LENGHT:0] (Fom Stage X)_Signal_Name_(To stage Y)
*/

//------------------------------------- Data signals (Not for buses)

//ALU_out
wire [XLEN-1:0] ID_ALU_out_IF;
wire [XLEN-1:0] EX_ALU_out_ID;
wire [XLEN-1:0] EX_ALU_out_MEM;
wire [XLEN-1:0] MEM_ALU_out_WB;

//PC_4
wire [XLEN-1:0] IF_PC_4_ID;
wire [XLEN-1:0] ID_PC_4_EX;
wire [XLEN-1:0] EX_PC_4_MEM;
wire [XLEN-1:0] MEM_PC_4_WB;

//PC
wire [XLEN-1:0] IF_PC_ID;
wire [XLEN-1:0] ID_PC_EX;

//EIB
wire [XLEN-1:0] IF_EIB_ID;

//RD
wire [XLEN-1:0] WB_RD_MEM;
wire [XLEN-1:0] MEM_RD_EX;
wire [XLEN-1:0] EX_RD_ID;

//RS1
wire [XLEN-1:0] ID_RS1_EX;

//RS2
wire [XLEN-1:0] ID_RS2_EX;
wire [XLEN-1:0] EX_RS2_MEM;

//imm
wire [XLEN-1:0] ID_imm_EX;

//adder_sum
wire [XLEN-1:0] EX_adder_sum_MEM;
wire [XLEN-1:0] MEM_adder_sum_WB;

//EMDB
wire [XLEN-1:0] MEM_EMDB_WB;

//------------------------------------- Control (Not for buses)


// ---------------------------------- Implementation of modules

IF_HK #(.XLEN(XLEN)) u_IF_HK (
    //Global
    .clk(clk),
    .reset(reset),
    
    //Buses
    .EIB(),      //External Instruction Bus
    .EIAB(),     //External Instruction Address Bus 
    
    //----------------------------ID Stage
    //Data from/to ID stage
    .ID_ALU_out(ID_ALU_out_IF),

    .ID_PC_4(IF_PC_4_ID),
    .ID_PC(IF_PC_ID),
    .ID_EIB(IF_EIB_ID),

    //Control from/to ID stage
    .ID_sel_next_PC()
);


ID #(.XLEN(XLEN)) u_ID (
    //Global
    .clk(clk),
    .reset(reset),

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    .IF_PC_4(IF_PC_4_ID),
    .IF_PC(IF_PC_ID),
    .IF_EIB(IF_EIB_ID),

    .IF_ALU_out(ID_ALU_out_IF),

    //Control from/to IF_HK stage
    .IF_sel_next_PC(),

    //----------------------------EX Stage
    //Data from/to EX stage
    .EX_ALU_out(EX_ALU_out_ID),
    .EX_RD(EX_RD_ID),

    .EX_PC_4(ID_PC_4_EX),
    .EX_PC(ID_PC_EX),
    .EX_RS1(ID_RS1_EX),
    .EX_RS2(ID_RS2_EX),
    .EX_imm(ID_imm_EX),

    //Control from/to EX stage
    .EX_sel_opa(),
    .EX_sel_opb(),
    .EX_sel_op(),

    .EX_mem_wr_en(),
    // .EX_val_rd_type(),
    // .EX_val_wr_type(),
    
    .EX_sel_writeback()
);


EX #(.XLEN(XLEN)) u_EX (
    //Global
    .clk(clk),
    .reset(reset),

    //----------------------------ID Stage
    //Data from/to ID stage
    .ID_PC_4(ID_PC_4_EX),
    .ID_PC(ID_PC_EX),
    .ID_RS1(ID_RS1_EX),
    .ID_RS2(ID_RS2_EX),
    .ID_imm(ID_imm_EX),

    .ID_ALU_out(EX_ALU_out_ID),
    .ID_RD(EX_RD_ID),

    //Control from/to ID stage
    .ID_sel_opa(),
    .ID_sel_opb(),
    .ID_sel_op(),

    .ID_mem_wr_en(),
    // .ID_val_rd_type(),
    // .ID_val_wr_type(),
    
    .ID_sel_writeback(),

    //----------------------------MEM Stage
    //Data from/to MEM stage
    .MEM_RD(MEM_RD_EX),

    .MEM_PC_4(EX_PC_4_MEM),
    .MEM_adder_sum(EX_adder_sum_MEM),
    .MEM_ALU_out(EX_ALU_out_MEM),
    .MEM_RS2(EX_RS2_MEM),

    //Control from/to MEM stage
    .MEM_mem_wr_en(),
    // .MEM_val_rd_type(),
    // .MEM_val_wr_type(),
    
    .MEM_sel_writeback()
);


MEM #(.XLEN(XLEN)) u_MEM (
    //Global
    .clk(clk),
    .reset(reset),

    // Buses
    .EMAB(), //Memory Address
    .EMCB(), //Memory Control
    .EMDB(), //Memory Data

    //----------------------------EX Stage
    //Data from/to EX stage
    .EX_PC_4(EX_PC_4_MEM),
    .EX_adder_sum(EX_adder_sum_MEM),
    .EX_ALU_out(EX_ALU_out_MEM),
    .EX_RS2(EX_RS2_MEM),

    .EX_RD(MEM_RD_EX),

    //Control from/to EX stage
    .EX_mem_wr_en(),
    // .EX_val_rd_type(),
    // .EX_val_wr_type(),

    .EX_sel_writeback(),

    //----------------------------WB Stage
    //Data from/to WB stage
    .WB_RD(WB_RD_MEM),

    .WB_adder_sum(MEM_adder_sum_WB),
    .WB_PC_4(MEM_PC_4_WB),
    .WB_ALU_out(MEM_ALU_out_WB),
    .WB_EMDB(MEM_EMDB_WB),

    //Control from/to WB stage
    .WB_sel_writeback()
);


WB #(.XLEN(XLEN)) u_WB (
    //Global
    .clk(clk),
    .reset(reset),

    //----------------------------MEM Stage
    //Data from/to MEM stage
    .MEM_adder_sum(MEM_adder_sum_WB),
    .MEM_PC_4(MEM_PC_4_WB),
    .MEM_ALU_out(MEM_ALU_out_WB),
    .MEM_EMDB(MEM_EMDB_WB),

    .MEM_RD(WB_RD_MEM),

    //Control from/to WB stage
    .WB_sel_writeback()
);


endmodule