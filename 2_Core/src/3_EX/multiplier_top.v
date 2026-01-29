`include "../../include/CORE_CONSTANTS.vh"

module multiplier_top #(
    parameter XLEN   = 64,
    parameter P_XLEN = XLEN*2
)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Operands & Operation Type
    input signed [XLEN-1:0]    opa,
    input signed [XLEN-1:0]    opb,
    input [5:0]                sel_operation,

    //Output Flags
    output reg                 pause_to_muliply,   

    //Result
    output signed [P_XLEN-1:0] mul_result
);

//Start signal
reg start;
always @( * ) begin
    case (sel_operation)
        `ALU_MUL, `ALU_MULH, `ALU_MULW,
        `ALU_MULHU, `ALU_MULHSU:
            start = 1'b1;
        default:
            start = 1'b0;
    endcase
end

//Determining if operands are signed / unsigned -> Depending on the instructions
reg rs1_is_signed;
reg rs2_is_signed;
always @( * ) begin
    //Default values
    rs1_is_signed = 1'b0;
    rs2_is_signed = 1'b0;
    case (sel_operation)
        `ALU_MUL, `ALU_MULH, `ALU_MULW:begin
            rs1_is_signed = 1'b1;
            rs2_is_signed = 1'b1;
        end
        `ALU_MULHU:begin
            rs1_is_signed = 1'b0;
            rs2_is_signed = 1'b0;
        end
        `ALU_MULHSU:begin
            rs1_is_signed = 1'b1;
            rs2_is_signed = 1'b0;
        end
    endcase
end

//Build of the multiplicand & multiplier
reg signed [XLEN-1:0] multiplicand;
reg signed [XLEN-1:0] multiplier;
always @( * ) begin
    if(sel_operation == `ALU_MULW)begin
        //Sign-extension of the lower 32 bits
        multiplicand = $signed(opa[31:0]);
        multiplier   = $signed(opb[31:0]);
    end
    else begin
        multiplicand = opa;
        multiplier   = opb;
    end
end

//Module containin the Booth Algorithm (radix 4) hardware
wire busy;
wire done;
radix_4_booth_multiplier #(.XLEN(XLEN)) radix_4_booth_multiplier_inst (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause),

    //Control
    .start(start),
    .rs1_is_signed(rs1_is_signed),
    .rs2_is_signed(rs2_is_signed),

    //Operands & Result
    .in_multiplicand(multiplicand),
    .in_multiplier(multiplier),
    .prod_result(mul_result),

    //Output flags
    .busy(busy),
    .done(done)
);

//Pause signal
always @( * ) begin
    pause_to_muliply = 1'b0;
    if(done)
        pause_to_muliply = 1'b0;
    else if(start || busy)
        pause_to_muliply = 1'b1;
end


endmodule