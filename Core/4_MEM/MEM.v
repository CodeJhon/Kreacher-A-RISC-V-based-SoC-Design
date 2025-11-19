`include "../CORE_CONSTANTS.vh"

module MEM #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //Buses
    output [XLEN-1:0] EMAB,            //External Memory Address Bus
    output            EMCB,            //External Memory Control Bus
    input [XLEN-1:0]  EMDB_in,            //External Memory Input Data Bus
    output [XLEN-1:0]  EMDB_out,          //External Memory Output Data Bus

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0] EX_PC_4,
    input [XLEN-1:0] EX_ALU_out,
    input [XLEN-1:0] EX_RS2,
    input [4:0]      EX_RD_addr_in,
    
    output [XLEN-1:0] EX_RD,
    output [4:0]     EX_RD_addr_out,

    //Control from/to EX stage
    input            EX_mem_wr_en,
    input [2:0]      EX_val_rd_type,
    input [2:0]      EX_val_wr_type,
    
    input [2:0]      EX_sel_writeback,

    //----------------------------WB Stage
    //Data from/to WB stage
    input [XLEN-1:0] WB_RD,
    input [4:0]      WB_RD_addr_in,

    output [XLEN-1:0] WB_PC_4,
    output [XLEN-1:0] WB_ALU_out,
    output [XLEN-1:0] WB_EMDB,
    output [4:0]      WB_RD_addr_out,

    //Control from/to WB stage
    output [2:0] WB_sel_writeback

);


// ---------------------------------- Implementation of modules

sign_extension #(.XLEN(XLEN)) sign_ex_wr (
    .in(EX_RS2),
    .out(EMDB_out),
    .extension_type(EX_val_wr_type)
);

sign_extension #(.XLEN(XLEN)) sign_ex_rd (
    .in(EMDB_in),
    .out(WB_EMDB),
    .extension_type(EX_val_rd_type)
);

// ------------------------------------- Connection to adjacent stage(s)
//EX
assign EX_RD = WB_RD;
assign EX_RD_addr_out = WB_RD_addr_in;

//WB
assign WB_PC_4 = EX_PC_4;
assign WB_ALU_out = EX_ALU_out;
assign WB_RD_addr_out = EX_RD_addr_in;

assign WB_sel_writeback = EX_sel_writeback;

// -------------------------------------- Connection to buses (if any)
assign EMAB = EX_ALU_out;
assign EMCB = EX_mem_wr_en;

endmodule