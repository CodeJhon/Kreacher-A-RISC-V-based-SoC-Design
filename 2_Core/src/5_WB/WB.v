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
    input [XLEN-1:0]      MEM_csr_data_rd,
    input [11:0]          MEM_csr_addr_wr_in,
    
    output reg [XLEN-1:0] MEM_RD,
    output [4:0]          MEM_RD_addr_out,
    output [XLEN-1:0]     MEM_csr_data_wr,
    output [11:0]         MEM_csr_addr_wr_out,

    //Control from/to WB stage
    input                 MEM_regfile_we_in,
    input                 MEM_csr_we_in,
    input [2:0]           MEM_sel_writeback,

    output                MEM_regfile_we_out,
    output                MEM_csr_we_out
);
    
// ---------------------------------- Implementation of modules
//Mux
always @( * ) begin
    case (MEM_sel_writeback)
        `WBACK_EXEC_RESULT:   MEM_RD = MEM_exec_result;
        `WBACK_PC_step:       MEM_RD = MEM_PC_step;
        `WBACK_EMDB:          MEM_RD = MEM_EMDB;
        `WBACK_CSR:           MEM_RD = MEM_csr_data_rd;
        `WBACK_NONE:          MEM_RD = {XLEN{1'b0}};
        default:              MEM_RD = {XLEN{1'b0}};
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
assign MEM_RD_addr_out      = MEM_RD_addr_in;
assign MEM_regfile_we_out   = MEM_regfile_we_in;
assign MEM_csr_we_out       = MEM_csr_we_in;
assign MEM_csr_data_wr      = MEM_exec_result;
assign MEM_csr_addr_wr_out  = MEM_csr_addr_wr_in;

endmodule