`include "../CORE_CONSTANTS.vh"

module WB #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0] MEM_adder_sum,
    input [XLEN-1:0] MEM_PC_4,
    input [XLEN-1:0] MEM_ALU_out,
    input [XLEN-1:0] MEM_EMDB,

    output [XLEN-1:0] MEM_RD,

    //Control from/to WB stage
    input [2:0] WB_sel_writeback
);
    
// ---------------------------------- Implementation of modules
reg [XLEN-1:0] RD;
//Mux
always @(WB_sel_writeback) begin
    case (WB_sel_writeback)
        `WBACK_ADDER_SUM: RD = MEM_adder_sum;
        `WBACK_ALU_OUT:   RD = MEM_ALU_out;
        `WBACK_PC_4:      RD = MEM_PC_4;
        `WBACK_EMDB:      RD = MEM_EMDB;
        default:          RD = 0;
    endcase
end

// ------------------------------------- Connection to adjacent stage(s)
//MEM
assign MEM_RD = RD;

endmodule