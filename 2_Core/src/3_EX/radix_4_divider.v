`include "../../include/CORE_CONSTANTS.vh"
module radix_4_divider#(
    parameter XLEN = 64
)(
    //Global
    input wire clk,
    input wire reset_n,
    input wire pause,

    //Control
    input  wire             start,
    input  wire             rs1_is_signed,
    input  wire             rs2_is_signed,

    //Operands & Result
    input  wire [XLEN-1:0]  dividend,
    input  wire [XLEN-1:0]  divisor,

    output wire [XLEN-1:0]  remainder,
    output wire [XLEN-1:0]  quotient,

    //Output flags
    output reg              busy,
    output reg              done
);

//Preparation of operands to work with

wire a_neg = rs1_is_signed & dividend[XLEN-1];
wire b_neg = rs2_is_signed & divisor[XLEN-1];

wire [XLEN-1:0] dividend_abs = a_neg ? (~dividend + 64'd1) : dividend;
wire [XLEN-1:0] divisor_abs  = b_neg ? (~divisor  + 64'd1) : divisor;

wire q_neg = a_neg ^ b_neg;

// ----------- FSM ----------------
reg [1:0] state;
reg [1:0] next_state;

always@(posedge clk or negedge reset_n)begin //update state block
    if(!reset_n)begin
        state <= `S_IDLE;
    end
    else if(!pause) begin
        state <= next_state;
    end
end

// Control Signals
reg clear_result;
reg load_operands;
reg iteration_en;

//Count register
reg [5:0] count_reg;

always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
            count_reg  <= XLEN;
    else if(!pause) begin
        if(clear_result)
            count_reg <= XLEN;
        else if(iteration_en)
            count_reg <= count_reg - 6'd2;
    end
end

//Next-State Logic
always@( * )begin 
    //Default
    busy = 1'b0;
    done = 1'b0;
    clear_result = 1'b0;
    load_operands = 1'b0;
    iteration_en = 1'b0;

    next_state = state;

    case(state)
        `S_IDLE:begin
            if(start)
                next_state = `S_LOAD;
         end
        `S_LOAD:begin
            busy = 1'b1;
            load_operands = 1'b1;
            next_state = `S_ITERATE;
         end
        `S_ITERATE:begin
            busy = 1'b1;
            iteration_en = 1'b1;
            if(count_reg <= 2)begin
                next_state = `S_DONE;
            end
         end
        `S_DONE:begin
            done = 1'b1;
            clear_result = 1'b1;
            next_state = `S_IDLE;
         end
    endcase
end


// ------------------------- Data Registers

//Dividend shift reg
reg [XLEN-1:0] dividend_shift_reg;
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
            dividend_shift_reg <= {XLEN{1'b0}};
    else if (!pause) begin
        if (load_operands)
            dividend_shift_reg <= dividend_abs;
        else if (iteration_en)
            dividend_shift_reg <= dividend_shift_reg << 2;
    end
end

//Remainder 
reg [XLEN+1:0] remainder_reg;
//                                                 MSB of divident shift register
wire [XLEN+1:0] rem_shifted = (remainder_reg << 2) | dividend_shift_reg[XLEN-1:XLEN-2];

wire [XLEN+1:0] divisor1 = {2'b00, divisor_abs};
wire [XLEN+1:0] divisor2 = divisor1 << 1;
wire [XLEN+1:0] divisor3 = divisor1 + divisor2;

always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
            remainder_reg <= {(XLEN+2){1'b0}};
    else if(!pause)begin
        if(clear_result)
            remainder_reg <= {(XLEN+2){1'b0}};
        else if (iteration_en) begin
            if($unsigned(rem_shifted) >= $unsigned({1'b0,divisor3}))
                remainder_reg <= rem_shifted - divisor3;
            else if($unsigned(rem_shifted) >= $unsigned({1'b0,divisor2}))
                remainder_reg <= rem_shifted - divisor2;
            else if($unsigned(rem_shifted) >= $unsigned({1'b0,divisor1}))
                remainder_reg <= rem_shifted - divisor1;
            else
                remainder_reg <= rem_shifted;
        end
    end
end

//Quotient
reg [XLEN-1:0] quotient_reg;
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        quotient_reg  <= {(XLEN){1'b0}};
    else if(!pause) begin
        if(clear_result)
            quotient_reg  <= {(XLEN){1'b0}};
        else if (iteration_en) begin
            if($unsigned(rem_shifted) >= $unsigned({1'b0,divisor3}))
                quotient_reg <= (quotient_reg << 2) | 64'd3;//11
            else if($unsigned(rem_shifted) >= $unsigned({1'b0,divisor2}))
                quotient_reg <= (quotient_reg << 2) | 64'd2;//10
            else if($unsigned(rem_shifted) >= $unsigned({1'b0,divisor1}))
                quotient_reg <= (quotient_reg << 2) | 64'd1;//01
            else
                quotient_reg <= (quotient_reg << 2) | 64'd0; //00
        end
    end
end

//--------------------------------- Obtention of magnitude
wire [XLEN-1:0] quotient_mag  = quotient_reg;
wire [XLEN:0]   remainder_mag = remainder_reg;

// sign-fix (2's complement)
wire [XLEN-1:0] quotient_fix =
    q_neg ? (~quotient_mag + 64'd1) : quotient_mag;

wire [XLEN:0] remainder_fix =
    a_neg ? (~remainder_mag + 65'd1) : remainder_mag;

//------------------------------- Output assignation
assign remainder = remainder_fix[XLEN-1:0];
assign quotient = quotient_fix;

endmodule