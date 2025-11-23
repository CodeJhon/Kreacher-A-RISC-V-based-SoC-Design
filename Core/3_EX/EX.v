`include "../CORE_CONSTANTS.vh"

module EX #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //----------------------------ID Stage
    //Data from/to ID stage
    input [XLEN-1:0]  ID_PC_4,
    input [XLEN-1:0]  ID_PC,
    input [XLEN-1:0]  ID_RS1,
    input [XLEN-1:0]  ID_RS2,
    input [4:0]       ID_RD_addr_in,
    input [XLEN-1:0]  ID_imm,

    output [XLEN-1:0] ID_ALU_out,
    output [XLEN-1:0] ID_RD,
    output [4:0]      ID_RD_addr_out,

    //Control from/to ID stage
    input [1:0]       ID_sel_opa,
    input [1:0]       ID_sel_opb,
    input [4:0]       ID_sel_op,
    input             ID_regfile_we_in,
    input [1:0]       ID_sel_next_PC_in,

    input             ID_mem_wr_en,
    input [2:0]       ID_val_rd_type,
    input [2:0]       ID_val_wr_type,
    
    input [2:0]       ID_sel_writeback,
    output            ID_regfile_we_out,
    output [1:0]      ID_sel_next_PC_out,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0]  MEM_RD,
    input [4:0]       MEM_RD_addr_in,

    output [XLEN-1:0] MEM_PC_4,
    output [XLEN-1:0] MEM_ALU_out,
    output [XLEN-1:0] MEM_RS2,
    output [4:0]      MEM_RD_addr_out,


    //Control from/to MEM stage
    input             MEM_regfile_we_in,

    output            MEM_mem_wr_en,
    output [2:0]      MEM_val_rd_type,
    output [2:0]      MEM_val_wr_type,
    
    output            MEM_regfile_we_out,
    
    output [2:0]      MEM_sel_writeback
);

// ---------------------------------- Implementation of modules

//Muxes
reg  [XLEN-1:0]  ALU_opa;
reg  [XLEN-1:0]  ALU_opb;
always @(ID_sel_opa, ID_sel_opb, ID_PC, ID_RS1, ID_imm, ID_RS2) begin
    case (ID_sel_opa)
        `OPA_PC:  ALU_opa = ID_PC;
        `OPA_RS1: ALU_opa = ID_RS1;
        default:  ALU_opa = 0;
    endcase

    case (ID_sel_opb)
        `OPB_IMM: ALU_opb = ID_imm;
        `OPB_RS2: ALU_opb = ID_RS2;
        default:  ALU_opb = 0;
    endcase
end

//ALU
wire [XLEN-1:0]  ALU_out;
ALU #(.XLEN(XLEN)) u_ALU (
    .opa(ALU_opa),
    .opb(ALU_opb),
    .sel_operation(ID_sel_op),
    .ALU_result(ALU_out)
);


// ------------------------------------- Connection to adjacent stage(s)
//ID
assign ID_ALU_out           = ALU_out;
assign ID_RD                = MEM_RD;
assign ID_RD_addr_out       = MEM_RD_addr_in;
assign ID_regfile_we_out    = MEM_regfile_we_in;
assign ID_sel_next_PC_out   = ID_sel_next_PC_in;

//MEM
assign MEM_PC_4             = ID_PC_4;
assign MEM_ALU_out          = ALU_out;
assign MEM_RS2              = ID_RS2;
assign MEM_RD_addr_out      = ID_RD_addr_in;

assign MEM_mem_wr_en        = ID_mem_wr_en;
assign MEM_val_rd_type      = ID_val_rd_type;
assign MEM_val_wr_type      = ID_val_wr_type;

assign MEM_regfile_we_out   = ID_regfile_we_in;

assign MEM_sel_writeback    = ID_sel_writeback;

endmodule