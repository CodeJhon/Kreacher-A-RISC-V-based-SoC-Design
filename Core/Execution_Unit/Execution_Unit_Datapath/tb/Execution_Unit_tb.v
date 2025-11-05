`timescale 1ns / 1ps
`include "../src/EXEC_CONSTANTS.vh"
`include "../../ALU/src/ALU_CONSTANTS.vh"

module Execution_Unit_tb(
    );

reg clk;
reg reset;
reg we;

// Control signals
reg [1:0] sel_writer_bus;
reg [2:0] sel_source;
reg [2:0] sel_destination;
reg [1:0] sel_opa;
reg [1:0] sel_opb;
reg [3:0] sel_operation;
reg [31:0] imm;
reg [4:0] A_addr_regfile;
reg [4:0] B_addr_regfile;

// Instantiate the Execution Unit Datapath
Execution_Unit_Datapath uut (
    .clk(clk),
    .reset(reset),
    .we(we),
    .sel_writer_bus(sel_writer_bus),
    .sel_source(sel_source),
    .sel_destination(sel_destination),
    .sel_opa(sel_opa),
    .sel_opb(sel_opb),
    .sel_operation(sel_operation),
    .imm(imm),
    .A_addr_regfile(A_addr_regfile),
    .B_addr_regfile(B_addr_regfile)
);

// Example clock generation
initial begin
    clk = 1;
    forever #5 clk = ~clk; // 100 MHz clock
end

// Example stimulus
initial begin
    #1;
    //Initial values
    reset = 1;
    we = 0;
    #20 reset = 0; // Release reset
    we = 1; 
    
    // All registers must be resetted at this point
    // Example operation: 
    // X5 -> A -> ALU
    // imm -> A -> ALU
    sel_operation = `ALU_ADD;
    sel_writer_bus = `SEL_ALU_OUT;
    sel_source = `SEL_REGFILE;
    A_addr_regfile = 5'd5;
    sel_destination = `SEL_OPERAND;
    sel_opa = `OP_BUS;
    sel_opb = `OP_IMM;
    imm = 32'd50;
    #10;
    
    //Example operation:
    // T1 -> A -> X5
    sel_writer_bus = `SEL_BUS_A;
    sel_source = `SEL_T1;
    sel_destination = `SEL_REGFILE;
    A_addr_regfile = 5'd5;
    
    #10;
    
    #50 $stop;
end

    
endmodule
