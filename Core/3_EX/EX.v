`include "../CORE_CONSTANTS.vh"

module EX #(parameter XLEN = 32)(
    //Global
    input clk,
    input reset,

    //----------------------------ID Stage
    //Data from/to ID stage
    input [XLEN-1:0]      ID_PC_4,
    input [XLEN-1:0]      ID_PC,
    input [XLEN-1:0]      ID_RS1,
    input [XLEN-1:0]      ID_RS2,
    input [4:0]           ID_RD_addr_in,
    input [XLEN-1:0]      ID_imm,

    output [XLEN-1:0]     ID_ALU_out,
    output [XLEN-1:0]     ID_RD,
    output [4:0]          ID_RD_addr_out,

    //Control from/to ID stage
    input [1:0]           ID_sel_opa,
    input [1:0]           ID_sel_opb,
    input [4:0]           ID_sel_op,
    input                 ID_regfile_we_in,

    input                 ID_mem_wr_en,
    input [2:0]           ID_val_rd_type,
    input [2:0]           ID_val_wr_type,
    
    input [2:0]           ID_sel_writeback,
    output                ID_regfile_we_out,

    //----------------------------MEM Stage
    //Data from/to MEM stage
    input [XLEN-1:0]      MEM_RD,
    input [4:0]           MEM_RD_addr_in,
    input [XLEN-1:0]      MEM_FW_ALU_out,

    output reg [XLEN-1:0] MEM_PC_4,
    output reg [XLEN-1:0] MEM_ALU_out,
    output reg [XLEN-1:0] MEM_RS2,
    output reg [4:0]      MEM_RD_addr_out,


    //Control from/to MEM stage
    input                 MEM_regfile_we_in,

    output reg            MEM_mem_wr_en,
    output reg [2:0]      MEM_val_rd_type,
    output reg [2:0]      MEM_val_wr_type,
    
    output reg            MEM_regfile_we_out,
    
    output reg [2:0]      MEM_sel_writeback,
    
    //---------------------------- HCU (Hazard Control Unit)
    input [1:0] HCU_sel_RS1,
    input [1:0] HCU_sel_RS2

);

// ---------------------------------- Implementation of modules

//Muxes for RS1 & RS2 (left  muxes)
reg  [XLEN-1:0]  RS1;
reg  [XLEN-1:0]  RS2;
always @(HCU_sel_RS1, HCU_sel_RS2, ID_RS1, ID_RS2, MEM_FW_ALU_out, MEM_RD) begin
    case (HCU_sel_RS1)
        `HCU_NO_BYPASS:  RS1 = ID_RS1;
        `HCU_BYPASS_MEM: RS1 = MEM_FW_ALU_out;
        `HCU_BYPASS_WB:  RS1 = MEM_RD;
        default:         RS1 = 0;
    endcase
    case (HCU_sel_RS2)
        `HCU_NO_BYPASS:  RS2 = ID_RS2;
        `HCU_BYPASS_MEM: RS2 = MEM_FW_ALU_out;
        `HCU_BYPASS_WB:  RS2 = MEM_RD;
        default:         RS2 = 0;
    endcase
end

//Muxes for opa & opb (right muxes)
reg  [XLEN-1:0]  ALU_opa;
reg  [XLEN-1:0]  ALU_opb;
always @(ID_sel_opa, ID_sel_opb, ID_PC, RS1, RS2, ID_imm) begin
    case (ID_sel_opa)
        `OPA_PC:  ALU_opa = ID_PC;
        `OPA_RS1: ALU_opa = RS1;
        default:  ALU_opa = 0;
    endcase

    case (ID_sel_opb)
        `OPB_IMM: ALU_opb = ID_imm;
        `OPB_RS2: ALU_opb = RS2;
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

//MEM
always @(posedge clk) begin
    if(reset)begin
        MEM_PC_4             <= 0;
        MEM_ALU_out          <= 0;
        MEM_RS2              <= 0;
        MEM_RD_addr_out      <= 0;

        MEM_mem_wr_en        <= 0;
        MEM_val_rd_type      <= 0;
        MEM_val_wr_type      <= 0;

        MEM_regfile_we_out   <= 0;

        MEM_sel_writeback    <= 0;
    end
    else begin
        MEM_PC_4             <= ID_PC_4;
        MEM_ALU_out          <= ALU_out;
        MEM_RS2              <= RS2;
        MEM_RD_addr_out      <= ID_RD_addr_in;

        MEM_mem_wr_en        <= ID_mem_wr_en;
        MEM_val_rd_type      <= ID_val_rd_type;
        MEM_val_wr_type      <= ID_val_wr_type;

        MEM_regfile_we_out   <= ID_regfile_we_in;

        MEM_sel_writeback    <= ID_sel_writeback;
    end
end


endmodule