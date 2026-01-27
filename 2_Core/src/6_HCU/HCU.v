`include "../../include/CORE_CONSTANTS.vh"

module HCU #(parameter XLEN = 64)(
    //Interrupt Handler
    input                interrupt_taken_natural,

    //Illegal Instruction
    input                illegal_trap,

    //----------------------------IF Stage
    output reg           IF_stall_PC,
    output reg           IF_stall,
    output reg           IF_flush,

    //----------------------------ID Stage
    input [4:0]          ID_RS1_addr,
    input [4:0]          ID_RS2_addr,
    input [11:0]         ID_csr_addr_rd,
    output reg           ID_flush,
    output reg [1:0]     ID_sel_RS1,
    output reg [1:0]     ID_sel_RS2,
    output reg [1:0]     ID_sel_csr_data_rd,

    //----------------------------EX Stage
    input [4:0]          EX_RS1_addr,
    input [4:0]          EX_RS2_addr,
    input [11:0]         EX_csr_addr_rd,
    output reg           EX_flush,
    output reg [1:0]     EX_sel_RS1,
    output reg [1:0]     EX_sel_RS2,
    output reg [1:0]     EX_sel_csr_data_rd,

    input [2:0]          EX_sel_writeback,
    input [4:0]          EX_RD_addr_in,

    input                EX_control_transfer_en,

    //----------------------------MEM Stage
    input [4:0]          MEM_RD_addr_in,
    input                MEM_regfile_we_in,
    input [11:0]         MEM_csr_addr_wr_in,
    input                MEM_csr_we_in,

    //----------------------------WB Stage
    input [4:0]          WB_RD_addr_in,
    input                WB_regfile_we_in,
    input [11:0]         WB_csr_addr_wr_in,
    input                WB_csr_we_in
    

);


//Solving some RAW Hazards in Regfile: Bypass logic -> Attention: X0 must NOT be bypassed
always @(*) begin
    
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

//Solving some RAW Hazards in CSR bank: Bypass logic
always @(*) begin
    //Default values 
    EX_sel_csr_data_rd = `HCU_NO_BYPASS;
    ID_sel_csr_data_rd = `HCU_NO_BYPASS;
    
    //------------------------------------------------------------------------------ BYPASSING EX STAGE
    //sel_csr_data_rd MUX logic -> Only bypass if writable csr addresses
    if(EX_csr_addr_rd == `MSTATUS_ADDR || EX_csr_addr_rd == `MEPC_ADDR || EX_csr_addr_rd == `MCAUSE_ADDR) begin
        if((EX_csr_addr_rd == MEM_csr_addr_wr_in) && MEM_csr_we_in)
            EX_sel_csr_data_rd = `HCU_BYPASS_MEM;
        else if((EX_csr_addr_rd == WB_csr_addr_wr_in) && WB_csr_we_in)
            EX_sel_csr_data_rd = `HCU_BYPASS_WB;
        else
            EX_sel_csr_data_rd = `HCU_NO_BYPASS;
    end

    //------------------------------------------------------------------------------ BYPASSING ID STAGE
    //sel_csr_data_rd MUX logic -> Only bypass if writable csr addresses
    if(ID_csr_addr_rd == `MSTATUS_ADDR || ID_csr_addr_rd == `MEPC_ADDR || ID_csr_addr_rd == `MCAUSE_ADDR) begin
        if((ID_csr_addr_rd == WB_csr_addr_wr_in) && WB_csr_we_in)
            ID_sel_csr_data_rd = `HCU_BYPASS_WB;
        else
            ID_sel_csr_data_rd = `HCU_NO_BYPASS;
    end
end

//Stalling & Flushing logic
always @(*) begin
    //Default values
    IF_stall_PC = 0;
    IF_stall = 0;
    ID_flush = 0;
    IF_flush = 0;
    EX_flush = 0;
    
    //Prioritize flush if an interrupt has been taken naturally 
    if(interrupt_taken_natural)begin
        ID_flush = 1;
        IF_flush = 1;
        EX_flush = 1;
    end

    //2nd priority: Illegal instructions
    else if(illegal_trap)begin
        ID_flush = 1;
        IF_flush = 1;
    end

    //Handling Control hazards by Flushing (Flush if jump recognized in EX stage)
    else if(EX_control_transfer_en != 1'b0)begin
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