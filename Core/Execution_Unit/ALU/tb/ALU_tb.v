`timescale 1ns / 1ps

`include "./ALU_CONSTANTS.vh"

module ALU_tb;

localparam ALU_ADD                             = 5'b0000;
localparam ALU_SUB                             = 5'b0001;
localparam ALU_SLT                             = 5'b0010;
localparam ALU_SLTU                            = 5'b0011;
localparam ALU_AND                             = 5'b0100;
localparam ALU_OR                              = 5'b0101;
localparam ALU_XOR                             = 5'b0110;
localparam ALU_SLL                             = 5'b0111;
localparam ALU_SRL                             = 5'b1000;
localparam ALU_SRA                             = 5'b1001;

// Inputs
reg [31:0] opa;
reg [31:0] opb;
reg [3:0] sel_operation;

// Output
wire signed [31:0] ALU_result;

// Instantiate the ALU

ALU uut (
    .opa(opa),
    .opb(opb),
    .sel_operation(sel_operation),
    .ALU_result(ALU_result)
);

initial begin    
    // Example ALUI operation tests
    
    // ADD
    opa = 32'd15;
    opb = 32'd10;
    sel_operation = ALU_ADD;
    #1 if (ALU_result !== 32'd25) $error("ADD failed: got %0d, expected 25", ALU_result);
    
    // SUB
    opa = 32'd20;
    opb = 32'd5;
    sel_operation = ALU_SUB;
    #1 if (ALU_result !== 32'd15) $error("SUB failed: got %0d, expected 15", ALU_result);
    
    // AND
    opa = 32'hFF00FF00;
    opb = 32'h0F0F0F0F;
    sel_operation = ALU_AND;
    #1 if (ALU_result !== (opa & opb)) $error("AND failed");
    
    // OR
    opa = 32'h0000FF00;
    opb = 32'h000000F0;
    sel_operation = ALU_OR;
    #1 if (ALU_result !== (opa | opb)) $error("OR failed");
    
    // XOR
    opa = 32'hAAAA5555;
    opb = 32'h0F0F0F0F;
    sel_operation = ALU_XOR;
    #1 if (ALU_result !== (opa ^ opb)) $error("XOR failed");
    
    // SLTU
    opa = 32'd5;
    opb = 32'd10;
    sel_operation = ALU_SLTU;
    #1 if (ALU_result !== 32'd1) $error("SLTIU failed");
    
    // SLT
    opa = 32'hFFFFFFF8; //-8
    opb = 32'hFFFFFFE7; //-25
    sel_operation = ALU_SLT;
    #1 if (ALU_result !== 32'd0) $error("SLT failed");
    
    // SLL (shift left logical)
    opa = 32'h00000001;
    opb = 32'd4;
    sel_operation = ALU_SLL;
    #1 if (ALU_result !== 32'h00000010) $error("SLL failed");
    
    // SRLI (shift right logical)
    opa = 32'h00000010;
    opb = 32'd2;
    sel_operation = ALU_SRL;
    #1 if (ALU_result !== 32'h00000004) $error("SRL failed");
    
    // SRAI (shift right arithmetic)
    opa = 32'hFFFFFFF8; // negative number (-8)
    opb = 32'd2;
    sel_operation = ALU_SRA;
    #1 if (ALU_result !== (32'hFFFFFFFE )) $error("SRA failed");//Expected -2 as result
    
    // LUI
    opa = 32'h00012345; 
    opb = 32'd12;//For LUI, we ALWAYS shift by 12 bits
    sel_operation = ALU_SLL;
    #1 if (ALU_result !== (32'h12345000)) $error("LUI failed");//Expected -2 as result
    
    // Finish simulation
    $stop;
end

endmodule
