`include "../../include/CORE_CONSTANTS.vh"

module MEM #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Buses
    output [XLEN-1:0]     EMAB,            //External Memory Address Bus
    output                EMCB,            //External Memory Control Bus
    input  [XLEN-1:0]     EMDB_in,            //External Memory Input Data Bus
    output [XLEN-1:0]     EMDB_out,          //External Memory Output Data Bus

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0]      EX_PC_4,
    input [XLEN-1:0]      EX_exec_result,
    input [XLEN-1:0]      EX_RS2,
    input [4:0]           EX_RD_addr_in,
    
    output [XLEN-1:0]     EX_RD,
    output [4:0]          EX_RD_addr_out,
    output [XLEN-1:0]     EX_FW_exec_result,

    //Control from/to EX stage
    input                 EX_mem_wr_en,
    input [2:0]           EX_val_rd_type,
    input [2:0]           EX_val_wr_type,
    input                 EX_result_type,
    
    input                 EX_regfile_we_in,
    
    input [2:0]           EX_sel_writeback,

    output                EX_regfile_we_out,

    //----------------------------WB Stage
    //Data from/to WB stage
    input [XLEN-1:0]      WB_RD,
    input [4:0]           WB_RD_addr_in,
    input                 WB_regfile_we_in,

    output reg [XLEN-1:0] WB_PC_4,
    output reg [XLEN-1:0] WB_exec_result,
    output reg [XLEN-1:0] WB_EMDB,
    output reg [4:0]      WB_RD_addr_out,

    //Control from/to WB stage
    output reg            WB_regfile_we_out,
    output reg [2:0]      WB_sel_writeback    

);


// ---------------------------------- Implementation of modules

extension_wr #(.XLEN(XLEN)) extend_write (
    .extend_in(EX_RS2),
    .extend_out(EMDB_out),
    .extension_type(EX_val_wr_type)
);

wire [XLEN-1:0] EMDB_in_extended;
extension_rd #(.XLEN(XLEN)) extend_read (
    .extend_in(EMDB_in),
    .extend_out(EMDB_in_extended),
    .extension_type(EX_val_rd_type)
);

wire[XLEN-1:0] exec_result;
extension_exec_result #(.XLEN(XLEN)) extend_result (
    .extend_in(EX_exec_result),
    .extend_out(exec_result),
    .extension_type(EX_result_type)
);


// ------------------------------------- Connection to adjacent stage(s)
//EX
assign EX_RD                = WB_RD;
assign EX_RD_addr_out       = WB_RD_addr_in;
assign EX_FW_exec_result        = EX_exec_result;
assign EX_regfile_we_out    = WB_regfile_we_in;

//WB
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)begin
        WB_PC_4              <= 0;
        WB_exec_result       <= 0;
        WB_EMDB              <= 0;
        WB_RD_addr_out       <= 0;

        WB_regfile_we_out    <= 0;
        WB_sel_writeback     <= 0;
    end
    else if(!pause) begin
        WB_PC_4              <= EX_PC_4;
        WB_exec_result       <= exec_result;
        WB_EMDB              <= EMDB_in_extended;
        WB_RD_addr_out       <= EX_RD_addr_in;

        WB_regfile_we_out    <= EX_regfile_we_in;
        WB_sel_writeback     <= EX_sel_writeback;
    end
end


// -------------------------------------- Connection to buses (if any)
assign EMAB                 = EX_exec_result;
assign EMCB                 = EX_mem_wr_en;

endmodule