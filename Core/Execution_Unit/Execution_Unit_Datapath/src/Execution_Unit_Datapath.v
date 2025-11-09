`include "./EXEC_CONSTANTS.vh"

module Execution_Unit_Datapath(
    input clk,
    input reset,
    input we,
    
    input [1:0] sel_writer_bus,
    input [2:0] sel_source,
    input [2:0] sel_destination,
    
    
    input [1:0]  sel_opa,
    input [1:0]  sel_opb,
    input [3:0]  sel_operation,
    input [31:0] imm,               //Sign-extended Immediate
    
    input [4:0]  A_addr_regfile,
    input [4:0]  B_addr_regfile
    );

//Hardwired (fixed) signals for ALU operands (K)
wire [31:0] K_next_instr = 32'd4;
wire [31:0] K_lui = 32'd12;

// ALU operands
reg    [31:0] ALU_opa;
reg    [31:0] ALU_opb;

// T1 signals
wire    [31:0] ALU_write_T1;
wire    [31:0] A_write_T1;
wire    [31:0] A_read_T1;
wire    [31:0] B_write_T1;
wire    [31:0] B_read_T1;

// PC signals
wire    [31:0] A_write_PC;
wire    [31:0] A_read_PC;
wire    [31:0] B_write_PC;
wire    [31:0] B_read_PC;

// signals (Bus A)
wire    [31:0] A_write_regfile;
wire    [31:0] A_read_regfile;
wire    [31:0] A_bus_operand;
// signals (Bus B)
wire    [31:0] B_write_regfile;
wire    [31:0] B_read_regfile;
wire    [31:0] B_bus_operand;


always@(A_bus_operand,B_bus_operand,imm,sel_opa,sel_opb)begin
    case(sel_opa)
        `OP_BUS:              ALU_opa = A_bus_operand;
        `OP_K_NEXT_INSTR:     ALU_opa = K_next_instr;
        default:              ALU_opa = 32'd0; 
    endcase
    case(sel_opb)
        `OP_BUS:              ALU_opb = B_bus_operand;
        `OP_IMM:              ALU_opb = imm;
        default:              ALU_opa = 32'd0;
    endcase
end

// Instantiate the Regfile_and_Regbank module
Regfile_and_Regbank U_Regfile_and_Regbank (
    // Global
    .clk(clk),
    .reset(reset),
    .we(we),
    
    // Data input sources
    .A_wr(),
    .B_wr(),
    .ALU_wr_T1(),
    
    // Data outputs
    .A_rd(),
    .B_rd(),
    
    // Control
    .ALU_wr_en(),
    
    .A_addr_wr_regfile(),
    .B_addr_wr_regfile(),
    
    .A_addr_rd_regfile(),
    .B_addr_rd_regfile(),
    
    .A_sel_wr_device(),
    .B_sel_wr_device(),
    
    .A_sel_rd_device(),
    .B_sel_rd_device()
);


ALU U_ALU(
    .opa(ALU_opa),
    .opb(ALU_opb),
    .sel_operation(sel_operation),
    .alu_result(ALU_write_T1)
);


endmodule
