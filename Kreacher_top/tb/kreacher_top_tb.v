`include "../../Core/CORE_CONSTANTS.vh"

`timescale 1ns/1ps

module kreacher_top_tb;

// Parameters
localparam XLEN = 32;

// Signals
reg clk;
reg reset;

reg [1:0]  sel_next_PC;
reg [2:0]  imm_type;
reg        regfile_we;

reg [1:0]  sel_opa;
reg [1:0]  sel_opb;
reg [4:0]  sel_op;

reg        mem_wr_en;
reg [2:0]  val_rd_type;
reg [2:0]  val_wr_type;

reg [2:0]  sel_writeback;

// Instantiate DUT
kreacher_top #(.XLEN(XLEN)) dut (
    .clk(clk),
    .reset(reset),
    //TEMPORARY (ONLY FOR TB PURPOSES)
    .sel_next_PC(sel_next_PC),
    .imm_type(imm_type),
    .regfile_we(regfile_we),
    .sel_opa(sel_opa),
    .sel_opb(sel_opb),
    .sel_op(sel_op),
    .mem_wr_en(mem_wr_en),
    .val_rd_type(val_rd_type),
    .val_wr_type(val_wr_type),
    .sel_writeback(sel_writeback)
);

// Clock generation
initial clk = 0;
always #5 clk = ~clk;  // 100 MHz clock

// Reset logic
initial begin
    reset = 1;
    #20;
    reset = 0;
end

// Stimulus
initial begin

    // Wait for reset release
    @(negedge reset);

    // Instruction #1: ADDI X4, X2, 12
    #10;
    sel_next_PC = `NEXT_PC_4;

    imm_type    = `I_IMMEDIATE;
    regfile_we  = 1;

    sel_opa     = `OPA_RS1;
    sel_opb     = `OPB_IMM;
    sel_op      = `ALU_ADD;
    
    mem_wr_en   = 0;
    //val_rd_type = 3'b001;
    //val_wr_type = 3'b010;

    sel_writeback = `WBACK_ALU_OUT;

    // Wait some cycles
    #50;

    // Finish simulation
    $stop;
end

endmodule
