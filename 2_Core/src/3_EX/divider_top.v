`include "../../include/CORE_CONSTANTS.vh"

module divider_top #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Operands & Operation Type
    input signed [XLEN-1:0]      opa,
    input signed [XLEN-1:0]      opb,
    input [5:0]                  sel_operation,

    //Output Flags
    output reg                   pause_to_divide,   

    //Result
    output reg signed [XLEN-1:0] remainder_result,
    output reg signed [XLEN-1:0] quotient_result
);

wire signed [XLEN-1:0] dividend = opa;
wire signed [XLEN-1:0] divisor = opb;

//Determining if operands are signed / unsigned -> Depending on the instruction
reg rs1_is_signed;
reg rs2_is_signed;
always @( * ) begin
    //Default values
    rs1_is_signed = 1'b0;
    rs2_is_signed = 1'b0;
    case (sel_operation)
        `ALU_DIV, `ALU_REM, `ALU_DIVW, `ALU_REMW:begin
            rs1_is_signed = 1'b1;
            rs2_is_signed = 1'b1;
        end
        `ALU_DIVU, `ALU_REMU, `ALU_DIVUW, `ALU_REMUW:begin //Unsigned
            rs1_is_signed = 1'b0;
            rs2_is_signed = 1'b0;
        end
    endcase
end

//Quick-Result cases: Allow us to throw a result in the same cycle and not use the dedicated divider module
// Cases: Divide by zero, divisor greater than divider, divide by same number ...busy
reg flag_result_one;
reg flag_division_by_zero;
reg flag_result_zero;

wire flag_quick_result =    flag_result_one         |
                            flag_division_by_zero   |
                            flag_result_zero;

always @( * ) begin
    flag_division_by_zero  = 1'b0;
    flag_result_zero       = 1'b0;
    flag_result_one        = 1'b0;

    if(divisor == {XLEN{1'b0}})
        flag_division_by_zero = 1'b1;
    else if(dividend == {XLEN{1'b0}})
        flag_result_zero      = 1'b1;
    else if((-divisor == dividend) || (divisor == dividend))
        flag_result_one       = 1'b1;
end

//Start signal
reg start;
always @( * ) begin
    start = 1'b0;
    if(!flag_quick_result)begin
        case (sel_operation)
            `ALU_DIV   , `ALU_REM,
            `ALU_DIVU  , `ALU_REMU,
            `ALU_DIVW  , `ALU_REMW,
            `ALU_DIVUW , `ALU_REMUW:
                start = 1'b1;
        endcase
    end
end

//Module containing the division algorithm (radix 4) hardware
wire busy;
wire done;
wire signed [XLEN-1:0]  remainder;
wire signed [XLEN-1:0]  quotient;
radix_4_divider #(.XLEN(64)) radix_4_divider_inst (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause),

    //Control
    .start(start),
    .rs1_is_signed(rs1_is_signed),
    .rs2_is_signed(rs2_is_signed),

    //Operands & Result
    .dividend(dividend),
    .divisor(divisor),

    .remainder(remainder),
    .quotient(quotient),

    //Output flags
    .busy(busy),
    .done(done)
);

//Output assignation

//Remainder result
wire instr_is_rem_signed = (sel_operation == `ALU_REM || sel_operation == `ALU_REMW);
always @( * ) begin
    //Default value
    remainder_result = remainder;

    //Quick-Result cases
    if ((flag_result_one && instr_is_rem_signed) || (flag_division_by_zero || flag_result_zero))begin
            remainder_result = {XLEN{1'b0}};
    end
            
    //-> For REM, the sign of the result equals the sign of the dividend
    else if (dividend[XLEN-1] && instr_is_rem_signed)
            remainder_result = $signed(-remainder); //Invert remainder sign
end

//Quotient result
wire instr_is_div_signed = (sel_operation == `ALU_DIV || sel_operation == `ALU_DIVW);
always @( * ) begin
    //Default value
    quotient_result = quotient;
    
    //Quick-Result cases
    if (flag_result_one)begin //Division by same magnitude
        if(rs1_is_signed == rs2_is_signed)
            quotient_result = $signed(1);
        else
            quotient_result = $signed(-1);
    end
    else if (flag_division_by_zero || flag_result_zero) // Division by 0 or by a/b (b>a)
            quotient_result = {XLEN{1'b0}};
end

//Pause signal
always @( * ) begin
    pause_to_divide = 1'b0;
    if(done)
        pause_to_divide = 1'b0;
    else if(start || busy)
        pause_to_divide = 1'b1;
end

endmodule