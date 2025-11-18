`include "../CORE_CONSTANTS.vh"

module EX #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //----------------------------ID Stage
    //Data from/to ID stage
    input [XLEN-1:0] ID_PC_4,
    input [XLEN-1:0] ID_PC,
    input [XLEN-1:0] ID_RS1,
    input [XLEN-1:0] ID_RS2,
    input [XLEN-1:0] ID_imm,

    output [XLEN-1:0] ID_ALU_out,
    output [XLEN-1:0] ID_RD,

    //Control from/to ID stage
    input [1:0]      ID_sel_opa,
    input [1:0]      ID_sel_opb,
    input [4:0]      ID_sel_op,

    input            ID_mem_wr_en,
    input [2:0]      ID_val_rd_type,
    input [2:0]      ID_val_wr_type,
    
    input [2:0]      ID_sel_writeback,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0] MEM_RD,

    output [XLEN-1:0] MEM_PC_4,
    output [XLEN-1:0] MEM_adder_sum,
    output [XLEN-1:0] MEM_ALU_out,
    output [XLEN-1:0] MEM_RS2,


    //Control from/to MEM stage
    output            MEM_mem_wr_en,
    output [2:0]      MEM_val_rd_type,
    output [2:0]      MEM_val_wr_type,
    
    output [2:0]      MEM_sel_writeback
);

// ---------------------------------- Implementation of modules

//Muxes
reg  [XLEN-1:0]  ALU_opa;
reg  [XLEN-1:0]  ALU_opb;
always @(ID_sel_opa,ID_sel_opb) begin
    case (ID_sel_opa)
        `OPA_PC:  ALU_opa = ID_PC;
        `OPA_IMM: ALU_opa = ID_imm;
        `OPA_RS1: ALU_opa = ID_RS1;
        default:  ALU_opa = 0;
    endcase

    case (ID_sel_opb)
        `OPB_12:  ALU_opb = 12;
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

//Adder
wire [XLEN-1:0] adder_sum;
assign adder_sum = ID_PC + ALU_out;

// ------------------------------------- Connection to adjacent stage(s)
//ID
assign ID_ALU_out = ALU_out;
assign ID_RD = MEM_RD;
//MEM
assign MEM_PC_4 = ID_PC_4;
assign MEM_adder_sum = adder_sum;
assign MEM_ALU_out = ALU_out;
assign MEM_RS2 = ID_RS2;
assign MEM_mem_wr_en = ID_mem_wr_en;
assign MEM_val_rd_type = ID_val_rd_type;
assign MEM_val_wr_type = ID_val_wr_type;

assign MEM_sel_writeback = ID_sel_writeback;

endmodule