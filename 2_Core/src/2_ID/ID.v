`include "../../include/CORE_CONSTANTS.vh"

module ID #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset,

    //----------------------------IF_HK Stage
    //Data from/to IF_HK stage
    input [XLEN-1:0]      IF_PC_4,
    input [XLEN-1:0]      IF_PC,
    input [31:0]          IF_EIB, 

    output [XLEN-1:0]     IF_exec_result,

    //Control from/to IF_HK stage
    output                IF_sel_next_PC,

    //----------------------------EX Stage
    //Data from/to EX stage
    input [XLEN-1:0]      EX_exec_result,
    input [XLEN-1:0]      EX_RD,
    input [4:0]           EX_RD_addr_in,

    output reg [XLEN-1:0] EX_PC_4,
    output reg [XLEN-1:0] EX_PC,
    output reg [XLEN-1:0] EX_RS1,
    output reg [XLEN-1:0] EX_RS2,
    output reg [4:0]      EX_RD_addr_out,
    output reg [XLEN-1:0] EX_imm,

    //Control from/to EX stage
    input                 EX_regfile_we_in,
    input  [1:0]          EX_sel_next_PC,

    output reg [1:0]      EX_sel_opb,
    output reg [4:0]      EX_sel_op,
    output reg            EX_regfile_we_out,
    output reg            EX_jump,
    output reg            EX_branch,
    output reg            EX_sel_exec_result,

    output reg            EX_mem_wr_en,
    output reg [2:0]      EX_val_rd_type,
    output reg [2:0]      EX_val_wr_type,
    output reg            EX_result_type,
    
    output reg [2:0]      EX_sel_writeback,

    //---------------------------- HCU (Hazard Control Unit)
    input                 ID_flush,
    input  [1:0]          ID_sel_RS1,
    input  [1:0]          ID_sel_RS2,
    
    output [4:0]          ID_RS1_addr,
    output [4:0]          ID_RS2_addr,


    output reg [4:0]      EX_RS1_addr,
    output reg [4:0]      EX_RS2_addr

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
    .opcode(IF_EIB[6:0]),
    .imm_I_10(IF_EIB[30]),
    .funct3(IF_EIB[14:12]),
    .funct7(IF_EIB[31:25]),

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
wire [XLEN-1:0] regfile_RS1;
wire [XLEN-1:0] regfile_RS2;
regfile #(.XLEN(XLEN)) u_regfile (
    .clk        (clk),
    .reset      (reset),

    // Addresses
    .RS1_addr   (IF_EIB[19:15]),
    .RS2_addr   (IF_EIB[24:20]),
    .RD_addr    (EX_RD_addr_in),

    // Sources & Destinations
    .RD         (EX_RD),
    .RS1        (regfile_RS1),
    .RS2        (regfile_RS2),

    // Control
    .regfile_we (EX_regfile_we_in)
);

// HCU Bypass muxes for RS1 & RS2
reg [XLEN-1:0] RS1;
reg [XLEN-1:0] RS2;
always @(regfile_RS1, regfile_RS2, EX_RD, ID_sel_RS1, ID_sel_RS2) begin
    case (ID_sel_RS1)
        `HCU_NO_BYPASS: RS1 = regfile_RS1;
        `HCU_BYPASS_WB: RS1 = EX_RD;
        default:        RS1 = 0;
    endcase
    case (ID_sel_RS2)
        `HCU_NO_BYPASS: RS2 = regfile_RS2;
        `HCU_BYPASS_WB: RS2 = EX_RD;
        default:        RS2 = 0;
    endcase
end

//Immediate Build (& Sign extension)
wire [XLEN-1:0] imm;
build_imm #(.XLEN(XLEN)) u_build_imm (
    .in(IF_EIB),
    .out(imm),
    .imm_type(imm_type)
);


// ------------------------------------- Connection to adjacent stage(s)
//IF_HK
assign IF_exec_result       = EX_exec_result;
assign IF_sel_next_PC       = EX_sel_next_PC;

//EX
always @(posedge clk) begin
    if(reset || ID_flush)begin
            //Data
        EX_PC_4              <= 0;
        EX_PC                <= 0;
        EX_RS1               <= 0;
        EX_RS2               <= 0;
        EX_RD_addr_out       <= 0;
        EX_imm               <= 0;
            //Control
        EX_sel_opb           <= 0;
        EX_sel_op            <= 0;
        EX_regfile_we_out    <= 0;
        EX_jump              <= 0;
        EX_branch            <= 0;
        EX_sel_exec_result   <= 0;

        EX_mem_wr_en         <= 0;
        EX_val_rd_type       <= 0;
        EX_val_wr_type       <= 0;
        EX_result_type       <= 0;

        EX_sel_writeback     <= 0; 
    end
    else begin
            //Data
        EX_PC_4              <= IF_PC_4;
        EX_PC                <= IF_PC;
        EX_RS1               <= RS1;
        EX_RS2               <= RS2;
        EX_RD_addr_out       <= IF_EIB[11:7];
        EX_imm               <= imm;
            //Control
        EX_sel_opb           <= sel_opb;
        EX_sel_op            <= sel_op;
        EX_regfile_we_out    <= regfile_we;
        EX_jump              <= jump;
        EX_branch            <= branch;
        EX_sel_exec_result   <= sel_exec_result;

        EX_mem_wr_en         <= mem_wr_en;
        EX_val_rd_type       <= val_rd_type;
        EX_val_wr_type       <= val_wr_type;
        EX_result_type       <= result_type;

        EX_sel_writeback     <= sel_writeback;
    end
end

//HCU
always@(posedge clk)begin
    if(reset)begin
        EX_RS1_addr          <= 0;
        EX_RS2_addr          <= 0;
    end
    else begin
        EX_RS1_addr          <= IF_EIB[19:15];
        EX_RS2_addr          <= IF_EIB[24:20];
    end
end

assign ID_RS1_addr           = IF_EIB[19:15];
assign ID_RS2_addr           = IF_EIB[24:20];

endmodule