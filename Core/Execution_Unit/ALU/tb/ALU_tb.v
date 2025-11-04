`timescale 1ns / 1ps

module ALU_tb;

localparam ALU_ADD                             = 5'b00000;
localparam ALU_SUB                             = 5'b00001;
localparam ALU_SLT                             = 5'b00010;
localparam ALU_SLTU                            = 5'b00011;
localparam ALU_AND                             = 5'b00100;
localparam ALU_OR                              = 5'b00101;
localparam ALU_XOR                             = 5'b00110;
localparam ALU_SLL                             = 5'b00111;
localparam ALU_SRL                             = 5'b01000;
localparam ALU_SRA                             = 5'b01001;
localparam ALU_PASS_OPERAND                    = 5'b01010;

// Inputs
reg [31:0] opa;
reg [31:0] opb;
reg [4:0] sel_operation;

// Output
wire signed [31:0] alu_result;

// Instantiate the ALU

ALU uut (
    .opa(opa),
    .opb(opb),
    .sel_operation(sel_operation),
    .alu_result(alu_result)
);

initial begin    
    // Example ALUI operation tests
    
    // ADD
    opa = 32'd15;
    opb = 32'd10;
    sel_operation = ALU_ADD;
    #1 if (alu_result !== 32'd25) $error("ADDI failed: got %0d, expected 25", alu_result);
    
    // SUB
    opa = 32'd20;
    opb = 32'd5;
    sel_operation = ALU_SUB;
    #1 if (alu_result !== 32'd15) $error("SUBI failed: got %0d, expected 15", alu_result);
    
    // AND
    opa = 32'hFF00FF00;
    opb = 32'h0F0F0F0F;
    sel_operation = ALU_AND;
    #1 if (alu_result !== (opa & opb)) $error("ANDI failed");
    
    // OR
    opa = 32'h0000FF00;
    opb = 32'h000000F0;
    sel_operation = ALU_OR;
    #1 if (alu_result !== (opa | opb)) $error("ORI failed");
    
    // XOR
    opa = 32'hAAAA5555;
    opb = 32'h0F0F0F0F;
    sel_operation = ALU_XOR;
    #1 if (alu_result !== (opa ^ opb)) $error("XORI failed");
    
    // SLTU
    opa = 32'd5;
    opb = 32'd10;
    sel_operation = ALU_SLTU;
    #1 if (alu_result !== 32'd1) $error("SLTIU failed");
    
    // SLT
    opa = 32'hFFFFFFF8; //-8
    opb = 32'hFFFFFFE7; //-25
    sel_operation = ALU_SLT;
    #1 if (alu_result !== 32'd0) $error("SLTI failed");
    
    // SLL (shift left logical)
    opa = 32'h00000001;
    opb = 32'd4;
    sel_operation = ALU_SLL;
    #1 if (alu_result !== 32'h00000010) $error("SLLI failed");
    
    // SRLI (shift right logical)
    opa = 32'h00000010;
    opb = 32'd2;
    sel_operation = ALU_SRL;
    #1 if (alu_result !== 32'h00000004) $error("SRLI failed");
    
    // SRAI (shift right arithmetic)
    opa = 32'hFFFFFFF8; // negative number (-8)
    opb = 32'd2;
    sel_operation = ALU_SRA;
    #1 if (alu_result !== (32'hFFFFFFFE )) $error("SRAI failed");//Expected -2 as result


    // Finish simulation
    $stop;
end

endmodule
