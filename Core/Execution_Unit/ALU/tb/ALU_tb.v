`timescale 1ns / 1ps

module ALU_tb;

localparam ADD                             = 5'b00000;
localparam SUBSTRACT                       = 5'b00001;
localparam SET_LESS_THAN_SIGNED            = 5'b00010;
localparam SET_LESS_THAN_UNSIGNED          = 5'b00011;
localparam BITWISE_AND                     = 5'b00100;
localparam BITWISE_OR                      = 5'b00101;
localparam BITWISE_XOR                     = 5'b00110;
localparam SHIFT_LEFT_LOGICAL              = 5'b00111;
localparam SHIFT_RIGHT_LOGICAL             = 5'b01000;
localparam SHIFT_RIGHT_ARITHMETIC          = 5'b01001;
localparam PASS_OPERAND                    = 5'b01010;

// Inputs
reg [31:0] opa;
reg [31:0] opb;
reg [4:0] sel_operation;

// Output
wire [31:0] alu_result;

// Instantiate the ALU

ALU uut (
    .opa(opa),
    .opb(opb),
    .sel_operation(sel_operation),
    .alu_result(alu_result)
);

initial begin

    // Test ADD
    opa = 32'd15;
    opb = 32'd10;
    sel_operation = ADD;
    #10; // wait for result

    // Test SUBSTRACT
    opa = 32'd20;
    opb = 32'd5;
    sel_operation = SUBSTRACT;
    #10;

    // Test default (should output 0)
    sel_operation = 5'b11111;
    #10;

    // Finish simulation
    $stop;
end

endmodule
