`include "../../include/CORE_CONSTANTS.vh"

module ID #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset,

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    input [XLEN-1:0]  IF_PC_4,
    input [XLEN-1:0]  IF_PC,
    input [31:0]      IF_canonical_instruction, 

    output [XLEN-1:0] IF_exec_result,

    //Control from/to IF_HK stage
    output            IF_sel_next_PC,

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0]  EX_exec_result,
    input [XLEN-1:0]  EX_RD,
    input [4:0]       EX_RD_addr_in,
    

    output [XLEN-1:0] EX_PC_4,
    output [XLEN-1:0] EX_PC,
    output [XLEN-1:0] EX_RS1,
    output [XLEN-1:0] EX_RS2,
    output [4:0]      EX_RD_addr_out,
    output [XLEN-1:0] EX_imm,

    //Control from/to EX stage
    input             EX_regfile_we_in,
    input             EX_sel_next_PC,

    output [1:0]      EX_sel_opb,
    output [4:0]      EX_sel_op,
    output            EX_regfile_we_out,
    output            EX_jump,
    output            EX_branch,
    output            EX_sel_exec_result,

    output            EX_mem_wr_en,
    output [2:0]      EX_val_rd_type,
    output [2:0]      EX_val_wr_type,
    output            EX_result_type,
    
    output [2:0]      EX_sel_writeback

);

// ---------------------------------- Implementation of modules

//Controller (Decoder)

wire            jump;
wire            branch;

wire [2:0]      imm_type;

wire [1:0]      sel_opb;
wire [4:0]      sel_op;
wire            regfile_we;
wire            sel_exec_result;

wire            mem_wr_en;
wire [2:0]      val_wr_type;
wire [2:0]      val_rd_type;
wire            result_type;

wire [2:0]      sel_writeback;

control u_control (
    //---------------------- Inputs
    .opcode(IF_canonical_instruction[6:0]),
    .imm_I_10(IF_canonical_instruction[30]),
    .funct3(IF_canonical_instruction[14:12]),
    .funct7(IF_canonical_instruction[31:25]),

    //----------------------- Outputs
    // ID
    .regfile_we(regfile_we),
    .imm_type(imm_type),

    // EX
    .sel_opb(sel_opb),
    .sel_op(sel_op),
    .sel_exec_result(sel_exec_result),
    .jump(jump),
    .branch(branch),

    // MEM
    .mem_wr_en(mem_wr_en),
    .val_wr_type(val_wr_type),
    .val_rd_type(val_rd_type),
    .result_type(result_type),

    // WB
    .sel_writeback(sel_writeback)
);

//Register File
wire [XLEN-1:0] RS1;
wire [XLEN-1:0] RS2;
regfile #(.XLEN(XLEN)) u_regfile (
    .clk        (clk),
    .reset      (reset),

    // Addresses
    .RS1_addr   (IF_canonical_instruction[19:15]),
    .RS2_addr   (IF_canonical_instruction[24:20]),
    .RD_addr    (EX_RD_addr_in),

    // Sources & Destinations
    .RD         (EX_RD),
    .RS1        (RS1),
    .RS2        (RS2),

    // Control
    .regfile_we (EX_regfile_we_in)
);

//Immediate Build (& Sign extension)
wire [XLEN-1:0] imm;
build_imm #(.XLEN(XLEN)) u_build_imm (
    .in(IF_canonical_instruction),
    .out(imm),
    .imm_type(imm_type)
);



// ------------------------------------- Connection to adjacent stage(s)
//IF_HK
assign IF_exec_result       = EX_exec_result;
assign IF_sel_next_PC       = EX_sel_next_PC;

//EX
    //Data
assign EX_PC_4              = IF_PC_4;
assign EX_PC                = IF_PC;
assign EX_RS1               = RS1;
assign EX_RS2               = RS2;
assign EX_RD_addr_out       = IF_canonical_instruction[11:7];
assign EX_imm               = imm;
    //Control
assign EX_sel_opb           = sel_opb;
assign EX_sel_op            = sel_op;
assign EX_regfile_we_out    = regfile_we;
assign EX_jump              = jump;
assign EX_branch            = branch;
assign EX_sel_exec_result   = sel_exec_result;

assign EX_mem_wr_en         = mem_wr_en;
assign EX_val_rd_type       = val_rd_type;
assign EX_val_wr_type       = val_wr_type;
assign EX_result_type       = result_type;

assign EX_sel_writeback     = sel_writeback;

endmodule