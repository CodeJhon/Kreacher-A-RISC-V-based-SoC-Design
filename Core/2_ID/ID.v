`include "../CORE_CONSTANTS.vh"

module ID #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    input [XLEN-1:0] IF_PC_4,
    input [XLEN-1:0] IF_PC,
    input [XLEN-1:0] IF_EIB, 

    output [XLEN-1:0] IF_ALU_out,

    //Control from/to IF_HK stage
    output [1:0] IF_sel_next_PC,

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0] EX_ALU_out,
    input [XLEN-1:0] EX_RD,

    output [XLEN-1:0] EX_PC_4,
    output [XLEN-1:0] EX_PC,
    output [XLEN-1:0] EX_RS1,
    output [XLEN-1:0] EX_RS2,
    output [XLEN-1:0] EX_imm,

    //Control from/to EX stage
    output [1:0]      EX_sel_opa,
    output [1:0]      EX_sel_opb,
    output [4:0]      EX_sel_op,

    output            EX_mem_wr_en,
    output [2:0]      EX_val_rd_type,
    output [2:0]      EX_val_wr_type,
    
    output [2:0]      EX_sel_writeback
    
);

// ---------------------------------- Implementation of modules

//Register File
wire regfile_we;
regfile #(.XLEN(XLEN)) u_regfile (
    .clk        (clk),
    .reset      (reset),

    // Addresses
    .RS1_addr   (IF_EIB[19:15]),
    .RS2_addr   (IF_EIB[24:20]),
    .RD_addr    (IF_EIB[11:7]),

    // Sources & Destinations
    .RD         (EX_RD),
    .RS1        (EX_RS1),
    .RS2        (EX_RS2),

    // Control
    .regfile_we (regfile_we)
);

//Immediate Sign-Extension
wire [2:0] imm_type;
extend_imm #(.XLEN(XLEN)) u_extend_imm (
    .in(IF_EIB),
    .out(EX_imm),
    .imm_type(imm_type)
);

//Controller (Decoder)
control u_control (
    //---------------------- Inputs
    .opcode(IF_EIB[6:0]),
    .funct3(IF_EIB[14:12]),
    .funct7(IF_EIB[31:25]),

    //----------------------- Outputs
    // IF
    .sel_next_pc(IF_sel_next_PC),

    // ID
    .regfile_we(regfile_we),
    .imm_type(imm_type),

    // EX
    .sel_opa(EX_sel_opa),
    .sel_opb(EX_sel_opb),
    .sel_op(EX_sel_op),

    // MEM
    .mem_wr_en(EX_mem_wr_en),
    .val_wr_type(EX_val_wr_type),
    .val_rd_type(EX_val_rd_type),

    // WB
    .sel_writeback(EX_sel_writeback)
);



// ------------------------------------- Connection to adjacent stage(s)
//IF_HK
assign IF_ALU_out = EX_ALU_out;
//EX
assign EX_PC_4 = IF_PC_4;
assign EX_PC = IF_PC;

endmodule