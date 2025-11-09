`include "./EXEC_CONSTANTS.vh"

module Regfile_and_Regbank(
    //Global
    input clk,
    input reset,
    input we,                
    
    //Data input sources
    input [31:0] A_wr,
    input [31:0] B_wr,
    input [31:0] ALU_wr_T1,
    
    //Data outputs
    output reg [31:0] A_rd,
    output reg [31:0] B_rd,
    
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
localparam TEMP_REGS = 1;  

//Registers
reg [31:0] regfile [REGFILE_WIDTH-1:1];//X0 not implemented here but in the assign statement
reg [31:0] PC;  
reg [31:0] T1; 

integer i;

//Internal Data signals
reg [31:0] regfile_in [REGFILE_WIDTH-1:1];
reg [31:0] PC_in;
reg [31:0] T1_in;

//Internal Control signals
reg [1:0] sel_regfile [REGFILE_WIDTH-1:1]; 
reg [1:0] sel_T1;
reg [1:0] sel_PC;

//Mux in
always@(*)begin
    //Muxes for regfile X1, X2, ..., XN--------------------------------
    for(i=1;i<=REGFILE_WIDTH-1;i=i+1)begin 
        case(sel_regfile[i])
            2'b00: regfile_in[i] = A_wr;
            2'b01: regfile_in[i] = B_wr;
            default:; //Retain. 
        endcase  
    end
    //Mux for PC --------------------------------------------------------
    case(sel_PC)
        2'b00: PC_in = A_wr;
        2'b01: PC_in = B_wr;
        default:; //Retain. 
    endcase      
    //Mux for T1--------------------------------------------------------
    case(sel_T1)
        2'b00: T1_in = A_wr;
        2'b01: T1_in = B_wr;
        2'b11: T1_in = ALU_wr_T1;
        default:; //Retain. 
    endcase
end

//Mux out
always@(*)begin
    case(A_sel_rd_device)
        `INTERNAL_BUS:  A_rd = regfile[A_addr_rd_regfile]; 
        `PC:            A_rd = PC;
        `T1:            A_rd = T1;
        default:;//Retain
    endcase
    case(B_sel_rd_device)
        `INTERNAL_BUS:  B_rd = regfile[B_addr_rd_regfile]; 
        `PC:            B_rd = PC;
        `T1:            B_rd = T1;
        default:;//Retain
    endcase
end

//Register logic
always@(posedge clk)begin
    if(reset)begin
        for(i=1;i<=REGFILE_WIDTH-1;i=i+1)begin
            regfile[i] <= 32'd0;
        end
        PC <= 32'd0;
        T1 <= 32'd0;
    end
    else if(we)begin
        for(i=1;i<=REGFILE_WIDTH-1;i=i+1)begin
            regfile[i] <= regfile_in[i];
        end
        PC <= PC_in;
        T1 <= T1_in;
    end   
end

//Internal control for writing logic
always@(A_addr_wr_regfile,B_addr_wr_regfile,A_sel_wr_device,B_sel_wr_device,ALU_wr_en)begin
    //Default: Retain
    for(i=1;i<=REGFILE_WIDTH-1;i=i+1)begin
        sel_regfile[i] = 2'b10;
    end
    sel_PC = 2'b10;
    sel_T1 = 2'b10;
    
    //Case: Driven by A
    case(A_sel_wr_device)
        `INTERNAL_BUS: sel_regfile[A_addr_wr_regfile] = 2'b00;
        `T1:                                   sel_T1 = 2'b00;
        `PC:                                   sel_PC = 2'b00;
        default:; 
    endcase
    
    //Case Driven by B
    case(B_sel_wr_device)
        `INTERNAL_BUS: sel_regfile[B_addr_wr_regfile] = 2'b01;
        `T1:                                   sel_T1 = 2'b01;
        `PC:                                   sel_PC = 2'b01;
        default:;
    endcase
    
    //Special case: T1 written by ALU
    if(ALU_wr_en) sel_T1 = 2'b11;
    
end
    
endmodule
