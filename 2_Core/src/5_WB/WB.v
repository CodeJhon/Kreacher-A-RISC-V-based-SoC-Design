`include "../../include/CORE_CONSTANTS.vh"

module WB #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0]      MEM_PC_step,
    input [XLEN-1:0]      MEM_exec_result,
    input [XLEN-1:0]      MEM_EMDB,
    input [4:0]           MEM_RD_addr_in,
    input                 MEM_regfile_we_in,

    output reg [XLEN-1:0] MEM_RD,
    output [4:0]          MEM_RD_addr_out,
    output                MEM_regfile_we_out,

    //Control from/to WB stage
    input [2:0]           WB_sel_writeback
);
    
// ---------------------------------- Implementation of modules
//Mux
always @(WB_sel_writeback, MEM_PC_step, MEM_exec_result, MEM_EMDB) begin
    case (WB_sel_writeback)
        `WBACK_EXEC_RESULT:   MEM_RD = MEM_exec_result;
        `WBACK_PC_step:          MEM_RD = MEM_PC_step;
        `WBACK_EMDB:          MEM_RD = MEM_EMDB;
        `WBACK_NONE:          MEM_RD = 0;
        default:              MEM_RD = 0;
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
assign MEM_RD_addr_out      = MEM_RD_addr_in;
assign MEM_regfile_we_out   = MEM_regfile_we_in;

endmodule