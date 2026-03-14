module verification_commits  #(parameter XLEN = 32)(
    
    //Signals retrieved from the core
    input [XLEN-1:0]    IF_PC,
    input [31:0]        IF_canonical_instruction,

    input               WB_regfile_we,
    input               WB_csr_we,
    input [4:0]         WB_RD_addr,
    input [XLEN-1:0]    WB_RD,
    input [11:0]        WB_csr_addr,
    input [XLEN-1:0]    WB_csr,

    //Outputs used for the framework
    output              commit_valid,
    output              commit_csr_valid,
    output [XLEN-1:0]   commit_PC,
    output [4:0]        commit_rd_addr,
    output [XLEN-1:0]   commit_rd_value,
    output [11:0]       commit_csr_addr,
    output [XLEN-1:0]   commit_csr_value,
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

    //canonical_instruction
wire [31:0] ID_canonical_instruction_EX;
wire [31:0] EX_canonical_instruction_MEM;
wire [31:0] MEM_canonical_instruction_WB;

assign ID_canonical_instruction_EX  = IF_canonical_instruction;
assign EX_canonical_instruction_MEM = ID_canonical_instruction_EX;
assign MEM_canonical_instruction_WB = EX_canonical_instruction_MEM;

//----------------------------Assignation of signals present in WB stage

assign commit_valid       = WB_regfile_we;
assign commit_PC          = MEM_PC_WB;
assign commit_rd_addr     = WB_RD_addr;
assign commit_rd_value    = WB_RD;
assign commit_instruction = MEM_canonical_instruction_WB;

//----------------------------Assignation of signals related to CSR commits
assign commit_csr_valid     = WB_csr_we;
assign commit_csr_addr      = WB_csr_addr;
assign commit_csr_value     = WB_csr;

endmodule