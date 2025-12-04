`include "../CORE_CONSTANTS.vh"

module MEM #(parameter XLEN = 32)(
`ifndef SYNTHESIS 
    input [XLEN-1:0]   MEM_PC,
    input [31:0]   MEM_instruction,
    output [31:0]   WB_instruction,
    output [XLEN-1:0]   WB_PC,
`endif
    //Global
    input clk,
    input reset,

    //Buses
    output [XLEN-1:0] EMAB,            //External Memory Address Bus
    output            EMCB,            //External Memory Control Bus
    input  [XLEN-1:0] EMDB_in,            //External Memory Input Data Bus
    output [XLEN-1:0] EMDB_out,          //External Memory Output Data Bus

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0]  EX_PC_4,
    input [XLEN-1:0]  EX_exec_result,
    input [XLEN-1:0]  EX_RS2,
    input [4:0]       EX_RD_addr_in,
    
    output [XLEN-1:0] EX_RD,
    output [4:0]      EX_RD_addr_out,

    //Control from/to EX stage
    input             EX_mem_wr_en,
    input [2:0]       EX_val_rd_type,
    input [2:0]       EX_val_wr_type,
    input             EX_regfile_we_in,
    
    input [2:0]       EX_sel_writeback,

    output            EX_regfile_we_out,

    //----------------------------WB Stage
    //Data from/to WB stage
    input [XLEN-1:0]  WB_RD,
    input [4:0]       WB_RD_addr_in,
    input             WB_regfile_we_in,

    output [XLEN-1:0] WB_PC_4,
    output [XLEN-1:0] WB_exec_result,
    output [XLEN-1:0] WB_EMDB,
    output [4:0]      WB_RD_addr_out,

    //Control from/to WB stage
    output            WB_regfile_we_out,
    output [2:0]      WB_sel_writeback    

);


// ---------------------------------- Implementation of modules

sign_extension #(.XLEN(XLEN)) sign_ex_wr (
    .in(EX_RS2),
    .out(EMDB_out),
    .extension_type(EX_val_wr_type)
);

wire [XLEN-1:0] EMDB_in_extended;
sign_extension #(.XLEN(XLEN)) sign_ex_rd (
    .in(EMDB_in),
    .out(EMDB_in_extended),
    .extension_type(EX_val_rd_type)
);

// ------------------------------------- Connection to adjacent stage(s)
//EX
assign EX_RD                = WB_RD;
assign EX_RD_addr_out       = WB_RD_addr_in;
assign EX_regfile_we_out    = WB_regfile_we_in;

//WB
assign WB_PC_4              = EX_PC_4;
assign WB_exec_result           = EX_exec_result;
assign WB_EMDB              = EMDB_in_extended;
assign WB_RD_addr_out       = EX_RD_addr_in;
assign WB_regfile_we_out    = EX_regfile_we_in;

assign WB_sel_writeback     = EX_sel_writeback;

// -------------------------------------- Connection to buses (if any)
assign EMAB                 = EX_exec_result;
assign EMCB                 = EX_mem_wr_en;

`ifndef SYNTHESIS
    assign WB_instruction = MEM_instruction;
    assign WB_PC = MEM_PC;
`endif

endmodule