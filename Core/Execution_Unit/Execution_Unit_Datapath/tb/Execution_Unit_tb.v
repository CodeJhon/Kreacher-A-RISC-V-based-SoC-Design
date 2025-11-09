`timescale 1ns / 1ps
`include "../src/EXEC_CONSTANTS.vh"
`include "../../ALU/src/ALU_CONSTANTS.vh"

module Execution_Unit_tb(
    );

    // Global signals
reg clk;
reg reset;
reg we;

// ALU control signals
reg [1:0]  sel_opa;
reg [1:0]  sel_opb;
reg [3:0]  sel_operation;
reg [31:0] imm;
reg ALU_wr_en;

// Bus A control signals
reg [1:0] A_sel_source;
reg [1:0] A_sel_dest;
reg [1:0] A_sel_wr_device;
reg [4:0] A_addr_wr_regfile;
reg [1:0] A_sel_rd_device;
reg [4:0] A_addr_rd_regfile;

// Bus B control signals
reg [1:0] B_sel_source;
reg [1:0] B_sel_dest;
reg [1:0] B_sel_wr_device;
reg [4:0] B_addr_wr_regfile;
reg [1:0] B_sel_rd_device;
reg [4:0] B_addr_rd_regfile;

// Instantiate the module
Execution_Unit_Datapath uut (
    // Global
    .clk(clk),
    .reset(reset),
    .we(we),

    // ALU control
    .sel_opa(sel_opa),
    .sel_opb(sel_opb),
    .sel_operation(sel_operation),
    .imm(imm),
    .ALU_wr_en(ALU_wr_en),

    // Bus A control
    .A_sel_source(A_sel_source),
    .A_sel_dest(A_sel_dest),
    .A_sel_wr_device(A_sel_wr_device),
    .A_addr_wr_regfile(A_addr_wr_regfile),
    .A_sel_rd_device(A_sel_rd_device),
    .A_addr_rd_regfile(A_addr_rd_regfile),

    // Bus B control
    .B_sel_source(B_sel_source),
    .B_sel_dest(B_sel_dest),
    .B_sel_wr_device(B_sel_wr_device),
    .B_addr_wr_regfile(B_addr_wr_regfile),
    .B_sel_rd_device(B_sel_rd_device),
    .B_addr_rd_regfile(B_addr_rd_regfile)
);

// Example clock generation
initial begin
    clk = 1;
    forever #5 clk = ~clk; // 100 MHz clock
end

// Example stimulus
initial begin
    /* TEMPLATE FOR COPYING
        //*******ALU********
    sel_opa = ; sel_opb = ; //imm = ;
    sel_operation = ; ALU_wr_en = 1'b1;
        //*******Bus A*******
    A_sel_source = ; A_sel_dest = ;
    //A_sel_wr_device = ; //A_addr_wr_regfile = 5'd0;
    A_sel_rd_device = ; //A_addr_rd_regfile = 5'd0;
        //*******Bus B*******
    B_sel_source = ; B_sel_dest = ;
    //B_sel_wr_device = ; //B_addr_wr_regfile = 5'd0;
    B_sel_rd_device = ; //B_addr_rd_regfile = 5'd0;
    */
    #1;
    //Initial values
    reset = 1; we = 0;
    #20
    reset = 0; we = 1; 
    
    /*
        X3 -> A -> ALU
       IMM -> ALU
    */
       //*******ALU********
    sel_opa = `OP_BUS; sel_opb = `OP_IMM; imm = 32'd20;
    sel_operation = `ALU_ADD; ALU_wr_en = 1'b1;
        //*******Bus A*******
    A_sel_source = `SEL_REGBANK; A_sel_dest =`SEL_ALU;
    //A_sel_wr_device = ; //A_addr_wr_regfile = ;
    A_sel_rd_device = `REGFILE; A_addr_rd_regfile = 5'd3;
    
    #10;
    
    #50 $stop;
end

    
endmodule
