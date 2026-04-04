// =============================================================================
// File        : ALU_tb.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Testbench for verifying ALU arithmetic, logic, and control behavior.
// =============================================================================

`timescale 1ns / 1ps

`include "../include/CORE_CONSTANTS.vh"

module tb_ALU_sim;

localparam XLEN = 64;

// Inputs
reg signed [XLEN-1:0] opa;
reg signed [XLEN-1:0] opb;
reg [4:0] sel_operation; // 5 bits now

// Outputs
wire signed [XLEN-1:0] ALU_result;
wire branch_condition;

// Instantiate the ALU
ALU #(XLEN) uut (
    .opa(opa),
    .opb(opb),
    .sel_operation(sel_operation),
    .ALU_result(ALU_result),
    .branch_condition(branch_condition)
);

initial begin    
    $display("---------ALU tests begin--------");
    // ---------------------------- //
    // ALU Operations
    // ---------------------------- //

    // ADD
    opa = 32'd15; opb = 32'd10; sel_operation = `ALU_ADD;
    #1 if (ALU_result !== 32'd25) $error("ADD failed: got %0d, expected 25", ALU_result);

    // SUB
    opa = 32'd20; opb = 32'd5; sel_operation = `ALU_SUB;
    #1 if (ALU_result !== 32'd15) $error("SUB failed: got %0d, expected 15", ALU_result);

    // SLT
    opa = -8; opb = -25; sel_operation = `ALU_SLT;
    #1 if (ALU_result !== 32'd0) $error("SLT failed: got %0d, expected 0", ALU_result);

    // SLTU
    opa = 32'd5; opb = 32'd10; sel_operation = `ALU_SLTU;
    #1 if (ALU_result !== 32'd1) $error("SLTU failed");

    // AND
    opa = 32'hF0F0F0F0; opb = 32'h0F0F0F0F; sel_operation = `ALU_AND;
    #1 if (ALU_result !== 32'h00000000) $error("AND failed");

    // OR
    opa = 32'hF0F0F0F0; opb = 32'h0F0F0F0F; sel_operation = `ALU_OR;
    #1 if (ALU_result !== 32'hFFFFFFFF) $error("OR failed");

    // XOR
    opa = 32'hAAAA5555; opb = 32'h5555AAAA; sel_operation = `ALU_XOR;
    #1 if (ALU_result !== 32'hFFFFFFFF) $error("XOR failed");

    // SLL
    opa = 32'h00000001; opb = 32'd4; sel_operation = `ALU_SLL;
    #1 if (ALU_result !== 32'h00000010) $error("SLL failed");

    // SRL
    opa = 32'h00000010; opb = 32'd2; sel_operation = `ALU_SRL;
    #1 if (ALU_result !== 32'h00000004) $error("SRL failed");

    // SRA
    opa = -8; opb = 32'd2; sel_operation = `ALU_SRA;
    #1 if (ALU_result !== -2) $error("SRA failed");

    // ---------------------------- //
    // Branch Conditions
    // ---------------------------- //

    // EQ true
    opa = 32'd7; opb = 32'd7; sel_operation = `ALU_EQ;
    #1 if (branch_condition !== 1'b1) $error("EQ failed");

    // NE true
    opa = 32'd7; opb = 32'd8; sel_operation = `ALU_NE;
    #1 if (branch_condition !== 1'b1) $error("NE failed");

    // LT signed
    opa = -5; opb = 3; sel_operation = `ALU_LT;
    #1 if (branch_condition !== 1'b1) $error("LT failed");

    // GE signed
    opa = 10; opb = 3; sel_operation = `ALU_GE;
    #1 if (branch_condition !== 1'b1) $error("GE failed");

    // LTU unsigned
    opa = 32'd5; opb = 32'd10; sel_operation = `ALU_LTU;
    #1 if (branch_condition !== 1'b1) $error("LTU failed");

    // GEU unsigned
    opa = 32'd10; opb = 32'd5; sel_operation = `ALU_GEU;
    #1 if (branch_condition !== 1'b1) $error("GEU failed");

    // ---------------------------- //
    // Finish simulation
    // ---------------------------- //
    $display("---------ALU tests finish--------");
    $stop;
end

endmodule
