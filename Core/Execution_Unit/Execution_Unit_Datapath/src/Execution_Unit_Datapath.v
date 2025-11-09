`include "./EXEC_CONSTANTS.vh"

module Execution_Unit_Datapath(
    //Global
    input clk,
    input reset,
    input we,
    
    //Control ALU ------------------------------
    input [1:0]  sel_opa,
    input [1:0]  sel_opb,
    input [3:0]  sel_operation,
    input [31:0] imm,               //Sign-extended Immediate
    
    //Control Bus A ---------------------------
        //Source & Destination (Type of transaction)
    input [1:0] A_sel_source,
    input [1:0] A_sel_dest,
        //Write to ....?
    input [1:0] A_sel_wr_device,
    input [4:0] A_addr_wr_regfile,
        //Read from ....?
    input [1:0] A_sel_rd_device,
    input [4:0] A_addr_rd_regfile,
    
    //Control Bus B ---------------------------
        //Source & Destination (Type of transaction)
    input [1:0] B_sel_source,
    input [1:0] B_sel_dest,
        //Write to ....?
    input [1:0] B_sel_wr_device,
    input [4:0] B_addr_wr_regfile,
        //Read from ....?
    input [1:0] B_sel_rd_device,
    input [4:0] B_addr_rd_regfile

    );

//Hardwired (fixed) signals for ALU operands (K)
localparam K_NEXT_INSTR = 32'd4;
localparam K_LUI        = 32'd12;

// ALU operands
reg    [31:0] ALU_opa;
reg    [31:0] ALU_opb;

wire [31:0] A_bus_operand;
wire [31:0] B_bus_operand;

always@(A_bus_operand,B_bus_operand,imm,sel_opa,sel_opb)begin
    case(sel_opa)
        `OP_BUS:              ALU_opa = A_bus_operand;
        `OP_K_NEXT_INSTR:     ALU_opa = K_NEXT_INSTR;
        `OP_K_LUI:            ALU_opa = K_LUI;
        default:              ALU_opa = 32'd0; 
    endcase
    case(sel_opb)
        `OP_BUS:              ALU_opb = B_bus_operand;
        `OP_IMM:              ALU_opb = imm;
        default:              ALU_opa = 32'd0;
    endcase
end

// Instantiate the Regfile_and_Regbank module
wire [31:0] A_wr;
wire [31:0] A_rd;

wire [31:0] B_wr;
wire [31:0] B_rd;

wire [31:0] ALU_wr_T1;

wire A_ALU_wr_en;
wire B_ALU_wr_en;
wire ALU_wr_en;

assign ALU_wr_en = A_ALU_wr_en | B_ALU_wr_en;

Regfile_and_Regbank U_Regfile_and_Regbank (
    // Global
    .clk(clk),
    .reset(reset),
    .we(we),
    
    // Data input sources
    .A_wr(A_wr),
    .B_wr(B_wr),
    .ALU_wr_T1(ALU_wr_T1),
    
    // Data outputs
    .A_rd(A_rd),
    .B_rd(B_rd),
    
    // Control
    .ALU_wr_en(ALU_wr_en),
    
    .A_addr_wr_regfile(A_addr_wr_regfile),
    .B_addr_wr_regfile(B_addr_wr_regfile),
    
    .A_addr_rd_regfile(A_addr_rd_regfile),
    .B_addr_rd_regfile(B_addr_rd_regfile),
    
    .A_sel_wr_device(A_sel_wr_device),
    .B_sel_wr_device(B_sel_wr_device),
    
    .A_sel_rd_device(A_sel_rd_device),
    .B_sel_rd_device(B_sel_rd_device)
);

Internal_Bus Bus_A (
    // Sources
    .regbank_source(A_rd),
    
    // Destinations
    .regbank_dest(A_wr),
    .ALU_dest(A_bus_operand),
    
    // Control
    .sel_source(A_sel_source),
    .sel_dest(A_sel_dest),
    
    .ALU_wr_en(A_ALU_wr_en)
);

Internal_Bus Bus_B (
    // Sources
    .regbank_source(B_rd),
    
    // Destinations
    .regbank_dest(B_wr),
    .ALU_dest(B_bus_operand),
    
    // Control
    .sel_source(B_sel_source),
    .sel_dest(B_sel_dest),
    
    .ALU_wr_en(B_ALU_wr_en)
);

ALU U_ALU(
    .opa(ALU_opa),
    .opb(ALU_opb),
    .sel_operation(sel_operation),
    .alu_result(ALU_wr_T1)
);


endmodule
