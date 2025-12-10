module verification_commits  #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,
    
    //Signals retrieved from the core
    input [XLEN-1:0]    IF_PC,
    input [31:0]        IF_EIB,

    input               WB_regfile_we,
    input [XLEN-1:0]    WB_RD_addr,
    input [XLEN-1:0]    WB_RD,

    //Outputs used for the framework
    output              commit_valid,
    output [XLEN-1:0]   commit_PC,
    output [4:0]        commit_rd_addr,
    output [XLEN-1:0]   commit_rd_value,
    output [31:0]       commit_instruction
);

//--------------------------Creation of new signals for non-WB stages
    //PC
reg [XLEN-1:0] ID_PC_EX;
reg [XLEN-1:0] EX_PC_MEM;
reg [XLEN-1:0] MEM_PC_WB;

always @(posedge clk) begin
    if (reset) begin        
        ID_PC_EX  <= 0;
        EX_PC_MEM <= 0;
        MEM_PC_WB <= 0;
    end
    else begin
        ID_PC_EX  <= IF_PC;
        EX_PC_MEM <= ID_PC_EX;
        MEM_PC_WB <= EX_PC_MEM;
    end
end

    //EIB
reg [31:0] ID_EIB_EX;
reg [31:0] EX_EIB_MEM;
reg [31:0] MEM_EIB_WB;

always @(posedge clk) begin
    if (reset) begin
        ID_EIB_EX  <= 0;
        EX_EIB_MEM <= 0;
        MEM_EIB_WB <= 0;        
    end
    else begin
        ID_EIB_EX  <= IF_EIB;
        EX_EIB_MEM <= ID_EIB_EX;
        MEM_EIB_WB <= EX_EIB_MEM;    
    end
end

//----------------------------Assignation of signals present in WB stage

assign commit_valid       = WB_regfile_we;
assign commit_PC          = MEM_PC_WB;
assign commit_rd_addr     = WB_RD_addr;
assign commit_rd_value    = WB_RD;
assign commit_instruction = MEM_EIB_WB;

endmodule