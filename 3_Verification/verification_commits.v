module verification_commits  #(parameter XLEN = 32)(
    
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
wire [XLEN-1:0] ID_PC_EX;
wire [XLEN-1:0] EX_PC_MEM;
wire [XLEN-1:0] MEM_PC_WB;

assign ID_PC_EX  = IF_PC;
assign EX_PC_MEM = ID_PC_EX;
assign MEM_PC_WB = EX_PC_MEM;

    //EIB
wire [31:0] ID_EIB_EX;
wire [31:0] EX_EIB_MEM;
wire [31:0] MEM_EIB_WB;

assign ID_EIB_EX  = IF_EIB;
assign EX_EIB_MEM = ID_EIB_EX;
assign MEM_EIB_WB = EX_EIB_MEM;

//----------------------------Assignation of signals present in WB stage

assign commit_valid       = WB_regfile_we;
assign commit_PC          = MEM_PC_WB;
assign commit_rd_addr     = WB_RD_addr;
assign commit_rd_value    = WB_RD;
assign commit_instruction = MEM_EIB_WB;

endmodule