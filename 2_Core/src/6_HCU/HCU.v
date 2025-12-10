`include "../../include/CORE_CONSTANTS.vh"

module HCU #(parameter XLEN = 32)(
    //----------------------------IF Stage
    output reg           IF_stall_PC,
    output reg           IF_stall,
    output reg           IF_flush,

    //----------------------------ID Stage
    input [4:0]          ID_RS1_addr,
    input [4:0]          ID_RS2_addr,
    output reg           ID_flush,
    output reg [1:0]     ID_sel_RS1,
    output reg [1:0]     ID_sel_RS2,

    //----------------------------EX Stage
    input [4:0]          EX_RS1_addr,
    input [4:0]          EX_RS2_addr,
    output reg [1:0]     EX_sel_RS1,
    output reg [1:0]     EX_sel_RS2,

    input [2:0]          EX_sel_writeback,
    input [4:0]          EX_RD_addr_in,

    input                EX_sel_next_PC,

    //----------------------------MEM Stage
    input [4:0]          MEM_RD_addr_in,
    input                MEM_regfile_we_in,

    //----------------------------WB Stage
    input [4:0]          WB_RD_addr_in,
    input                WB_regfile_we_in

);


//Solving some RAW Hazards: Bypass logic -> Attention: X0 must NOT be bypassed
always @(EX_RS1_addr, EX_RS2_addr, MEM_RD_addr_in, MEM_regfile_we_in, WB_RD_addr_in, WB_regfile_we_in) begin
    
    //------------------------------------------------------------------------------ BYPASSING EX STAGE
    //sel_RS1 MUX logic
    if(((EX_RS1_addr == MEM_RD_addr_in)&& MEM_regfile_we_in) && (EX_RS1_addr != 0))   
        EX_sel_RS1 = `HCU_BYPASS_MEM;
    else if(((EX_RS1_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (EX_RS1_addr != 0))
        EX_sel_RS1 = `HCU_BYPASS_WB;
    else
        EX_sel_RS1 = `HCU_NO_BYPASS;
    //sel_RS2 MUX logic
    if(((EX_RS2_addr == MEM_RD_addr_in)&& MEM_regfile_we_in) && (EX_RS2_addr != 0))   
        EX_sel_RS2 = `HCU_BYPASS_MEM;
    else if(((EX_RS2_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (EX_RS2_addr != 0))
        EX_sel_RS2 = `HCU_BYPASS_WB;
    else
        EX_sel_RS2 = `HCU_NO_BYPASS;
    
    //------------------------------------------------------------------------------ BYPASSING ID STAGE
    //sel_RS1 MUX logic
    if(((ID_RS1_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (ID_RS1_addr != 0))
        ID_sel_RS1 = `HCU_BYPASS_WB;
    else
        ID_sel_RS1 = `HCU_NO_BYPASS;
    //sel_RS2 MUX logic
    if(((ID_RS2_addr == WB_RD_addr_in)&& WB_regfile_we_in) && (ID_RS2_addr != 0))
        ID_sel_RS2 = `HCU_BYPASS_WB;
    else
        ID_sel_RS2 = `HCU_NO_BYPASS;

end

//Stalling & Flushing logic
always @(ID_RS1_addr, ID_RS2_addr, EX_RD_addr_in, EX_sel_writeback, EX_sel_next_PC) begin
    //Default values
    IF_stall_PC = 0;
    IF_stall = 0;
    ID_flush = 0;
    IF_flush = 0;
    
    //Handling Control hazards by Flushing (Flush if jump recognized in EX stage)
    if(EX_sel_next_PC != 1'b0)begin
        ID_flush = 1;
        IF_flush = 1;
    end
    //Handling Data hazards by stalling & Flushing
    else if((EX_RD_addr_in == ID_RS1_addr) || (EX_RD_addr_in == ID_RS2_addr))begin
        case (EX_sel_writeback)
        
            `WBACK_EMDB: begin//Stall instruction -----> LW
                IF_stall_PC = 1;
                IF_stall = 1;
                ID_flush = 1;
            end

            default: begin
                IF_stall_PC = 0;
                IF_stall = 0;
                ID_flush = 0;
            end
        endcase
    end
end

endmodule