`include "../CORE_CONSTANTS.vh"

module HCU #(parameter XLEN = 32)(
    //----------------------------IF Stage
    output               IF_stall_PC,
    output               IF_stall,

    //----------------------------ID Stage
    input [4:0]          ID_RS1_addr,
    input [4:0]          ID_RS2_addr,
    output               ID_flush,

    //----------------------------EX Stage
    input [4:0]          EX_RS1_addr,
    input [4:0]          EX_RS2_addr,
    output reg [1:0]     EX_sel_RS1,
    output reg [1:0]     EX_sel_RS2,

    input [2:0]          EX_sel_writeback,
    input [4:0]          EX_RD_addr_in,

    //----------------------------MEM Stage
    input [4:0]          MEM_RD_addr_in,
    input                MEM_regfile_we_in,

    //----------------------------WB Stage
    input [4:0]          WB_RD_addr_in,
    input                WB_regfile_we_in

);


//Solving some RAW Hazards: Bypass logic -> Attention: X0 must NOT be bypassed
always @(EX_RS1_addr, EX_RS2_addr, MEM_RD_addr_in, MEM_regfile_we_in, WB_RD_addr_in, WB_regfile_we_in) begin
    
    //sel_opa MUX logic
    if(((EX_RS1_addr == MEM_RD_addr_in)&& MEM_regfile_we_in) && (EX_RS1_addr != 0))   
        EX_sel_RS1 = `HCU_BYPASS_MEM;
    else if(((EX_RS1_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (EX_RS1_addr != 0))
        EX_sel_RS1 = `HCU_BYPASS_WB;
    else
        EX_sel_RS1 = `HCU_NO_BYPASS;

    //sel_opb MUX logic
    if(((EX_RS2_addr == MEM_RD_addr_in)&& MEM_regfile_we_in) && (EX_RS2_addr != 0))   
        EX_sel_RS2 = `HCU_BYPASS_MEM;
    else if(((EX_RS2_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (EX_RS2_addr != 0))
        EX_sel_RS2 = `HCU_BYPASS_WB;
    else
        EX_sel_RS2 = `HCU_NO_BYPASS;
    
end

assign               IF_stall_PC = 0;
assign               IF_stall = 0;
assign               ID_flush = 0;

endmodule