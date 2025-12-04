`include "../CORE_CONSTANTS.vh"

module WB #(parameter XLEN = 32)(
`ifndef SYNTHESIS
    input [31:0]          WB_instruction,
    input [XLEN-1:0]   WB_PC,
    output           commit_valid,
    output [4:0]   commit_rd_addr,
    output [XLEN-1:0]   commit_rd_value,
    output [31:0]   commit_instruction,
    output [XLEN-1:0]   commit_PC,
`endif
    //Global
    input clk,
    input reset,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0]      MEM_PC_4,
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
always @(WB_sel_writeback, MEM_PC_4, MEM_exec_result, MEM_EMDB) begin
    case (WB_sel_writeback)
        `WBACK_EXEC_RESULT:   MEM_RD = MEM_exec_result;
        `WBACK_PC_4:          MEM_RD = MEM_PC_4;
        `WBACK_EMDB:          MEM_RD = MEM_EMDB;
        `WBACK_NONE:          MEM_RD = 0;
        default:              MEM_RD = 0;
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
assign MEM_RD_addr_out      = MEM_RD_addr_in;
assign MEM_regfile_we_out   = MEM_regfile_we_in;

// For verification purposes
`ifndef SYNTHESIS
assign commit_valid = MEM_regfile_we_in;
assign commit_rd_addr = MEM_RD_addr_in;
assign commit_rd_value = MEM_RD;
assign commit_instruction = WB_instruction;
assign commit_PC = WB_PC;
`endif

endmodule