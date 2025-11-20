`include "../CORE_CONSTANTS.vh"

module HCU #(parameter XLEN = 32)(
    //----------------------------ID Stage
    input [4:0]          EX_RS1_addr,
    input [4:0]          EX_RS2_addr,

    //----------------------------EX Stage
    output reg [1:0]     EX_sel_opa,
    output reg [1:0]     EX_sel_opb,

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
        EX_sel_opa = `HCU_BYPASS_MEM;
    else if(((EX_RS1_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (EX_RS1_addr != 0))
        EX_sel_opa = `HCU_BYPASS_WB;
    else
        EX_sel_opa = `HCU_NO_BYPASS;

    //sel_opb MUX logic
    if(((EX_RS2_addr == MEM_RD_addr_in)&& MEM_regfile_we_in) && (EX_RS2_addr != 0))   
        EX_sel_opb = `HCU_BYPASS_MEM;
    else if(((EX_RS2_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (EX_RS2_addr != 0))
        EX_sel_opb = `HCU_BYPASS_WB;
    else
        EX_sel_opb = `HCU_NO_BYPASS;
    
end


endmodule