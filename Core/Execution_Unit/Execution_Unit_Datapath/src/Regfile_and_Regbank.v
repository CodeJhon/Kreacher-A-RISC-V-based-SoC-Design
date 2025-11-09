`include "./EXEC_CONSTANTS.vh"

module Regfile_and_Regbank(
    //Global
    input clk,
    input reset,
    input we,                
    
    //Data input sources
    input [31:0] A_write,
    input [31:0] B_write,
    input [31:0] ALU_wr_T1,
    
    //Data outputs
    output [31:0] A_read,
    output [31:0] B_read,
    
    //Control
    input ALU_wr_en,
    
    input [4:0] A_addr_wr_regfile,
    input [4:0] B_addr_wr_regfile,
    
    input [4:0] A_addr_rd_regfile,
    input [4:0] B_addr_rd_regfile,
    
    input [1:0] A_sel_wr_device,
    input [1:0] B_sel_wr_device,
    
    input [1:0] A_sel_rd_device,
    input [1:0] B_sel_rd_device
    
    );

localparam REGFILE_WIDTH = 32;
localparam EXTRA_REGS = 0; // Starting from T2 
localparam AMOUNT_REGISTERS = REGFILE_WIDTH + EXTRA_REGS + 2; // PC and T1 included here

//Registers
reg [31:0] regbank [AMOUNT_REGISTERS-1:1];//X0 not implemented here but in the assign statement
integer i;

//Internal signals
reg [1:0] sel_in [AMOUNT_REGISTERS-1:1]; 

reg [31:0] reg_in [AMOUNT_REGISTERS-1:1];

reg [31:0] A_read;
reg [31:0] B_read;

//Mux in
always@(*)begin
    for(i=1;i<=AMOUNT_REGISTERS-2;i=i+1)begin //Muxes for registers X1, X2, ..., XN, PC
        case(sel_in[i])
            2'b00: reg_in[i] = A_write;
            2'b01: reg_in[i] = B_write;
            default:; //Retain. reg_in[i] = reg_in[i]
        endcase  
    end
    //Mux for T1
    case(sel_in[AMOUNT_REGISTERS-1])
        2'b00: reg_in[AMOUNT_REGISTERS-1] = A_write;
        2'b01: reg_in[AMOUNT_REGISTERS-1] = B_write;
        2'b11: reg_in[AMOUNT_REGISTERS-1] = ALU_wr_T1;
        default:; //Retain. reg_in[i] = reg_in[i]
    endcase
end

//Mux out
always@(*)begin
    case(A_sel_rd_device)
        `INTERNAL_BUS:  A_read = regbank[A_addr_rd_regfile]; 
        `PC:            A_read = regbank[AMOUNT_REGISTERS-2];
        `T1:            A_read = regbank[AMOUNT_REGISTERS-1];
        default:;//Retain
    end
    case(B_sel_rd_device)
        `INTERNAL_BUS:  B_read = regbank[B_addr_rd_regfile]; 
        `PC:            B_read = regbank[AMOUNT_REGISTERS-2];
        `T1:            B_read = regbank[AMOUNT_REGISTERS-1];
        default:;//Retain
    end
end

//Register logic
always@(posedge clk)begin
    for(i=1;i<=AMOUNT_REGISTERS-1;i=i+1)begin
        if(reset)   regbank[i] <= 32'd0;
        else if(we) regbank[i] <= reg_in[i];
    end
end

//Internal control for writing logic
always@(A_addr_wr_regfile,B_addr_wr_regfile,_A_sel_wr_device,B_sel_wr_device)begin
    //Default
    for(i=1;i<=AMOUNT_REGISTERS-1;i=i+1)begin
        sel_in[i] = 2'b10;
    end
    
    case(A_sel_wr_device)
        `INTERNAL_BUS: sel_in[A_addr_wr_regfile] = 2'b00;
        `T1:           sel_in[AMOUNT_REGISTERS-1] = 2'b00;
        `PC:           sel_in[AMOUNT_REGISTERS-2] = 2'b00;
        default:; 
    endcase
    
    case(B_sel_wr_device)
        `INTERNAL_BUS: sel_in[B_addr_wr_regfile] = 2'b01;
        `T1:           sel_in[AMOUNT_REGISTERS-1] = 2'b01;
        `PC:           sel_in[AMOUNT_REGISTERS-2] = 2'b01;
        default:;
    endcase
    
    //T1 in case of written by ALU
    if(ALU_wr_en) sel_in[AMOUNT_REGISTERS-1] = 2'b11;
    
end
    
endmodule
