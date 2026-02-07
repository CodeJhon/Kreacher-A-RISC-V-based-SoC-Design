`include "../../include/CORE_CONSTANTS.vh"

module radix_4_booth_multiplier #(
    parameter XLEN   = 64,
    parameter P_XLEN = XLEN*2
)(
    //Global
    input  wire clk,
    input  wire reset_n,
    input       pause,

    //Control
    input  wire start,
    input  wire rs1_is_signed,
    input  wire rs2_is_signed,

    //Operands & Result
    input  wire signed [XLEN-1:0] in_multiplicand,
    input  wire signed [XLEN-1:0] in_multiplier, 
    output reg [P_XLEN-1:0] prod_result,

    //Output flags
    output reg busy,
    output reg done
);

// --------------- FSM --------------------
//Control signals of the FSMs
reg load_operands;
reg move_to_next_group;
reg clean_result;

reg [6:0] iteration_counter;
localparam MAX_ITERATIONS = 7'd32;
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        iteration_counter <= 7'd0;
    else if(!pause)begin
        if(clean_result)
            iteration_counter <= 7'd0;
        else if(move_to_next_group)
            iteration_counter <= iteration_counter + 7'd1;
    end
end

reg [1:0] state;
reg [1:0] next_state;

always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        state <= `S_IDLE;
    else if(!pause)
        state <= next_state;
end

// Next state logic

always @( * ) begin
    busy               = 1'b0;
    done               = 1'b0;
    load_operands      = 1'b0;
    move_to_next_group = 1'b0;
    clean_result       = 1'b0;
    
    next_state = state;

    case(state)
        `S_IDLE: begin
            clean_result = 1'b1;
            if(start) 
                next_state = `S_LOAD;                
        end

        `S_LOAD: begin
            busy          = 1'b1;
            load_operands = 1'b1;
            next_state = `S_ITERATE;
        end

        `S_ITERATE: begin
            busy = 1'b1;
            move_to_next_group = 1'b1;
            if(iteration_counter >= MAX_ITERATIONS)//0 or 1
                next_state = `S_DONE;
            else
                next_state = `S_ITERATE;
        end

        `S_DONE: begin
            done         = 1'b1;
            next_state = `S_IDLE;
        end
    endcase
end

localparam INTERNAL_LEN = XLEN + 2;

wire [INTERNAL_LEN-1:0] A_ext =
    rs1_is_signed ? {{2{in_multiplicand[XLEN-1]}}, in_multiplicand} :
                    {2'b00,in_multiplicand};

wire [INTERNAL_LEN-1:0] B_ext =
    rs2_is_signed ? {{2{in_multiplier[XLEN-1]}}, in_multiplier} :
                    {2'b00,in_multiplier};

//Register that will be right-shifted every time move_to_next_group is active and a clock edge is up
reg [INTERNAL_LEN:0] B_shifting;

always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        B_shifting <= {(INTERNAL_LEN+1){1'b0}};
    else if(!pause)begin
        if(load_operands)
            //Add an extra 0 at the LSB
            B_shifting <= {B_ext, 1'b0};
        else if(move_to_next_group)
            B_shifting <=  B_shifting >> 2; 
    end
end


//Obtention of the partial product from the bit groups 
wire [2:0] bit_group = B_shifting[2:0];
reg [INTERNAL_LEN-1:0] partial_product;

localparam EXT_AMOUNT_PROD = P_XLEN - INTERNAL_LEN;

//Extend the partiail product (pp)
wire [P_XLEN-1:0] pp_extended = 
    {{EXT_AMOUNT_PROD{partial_product[INTERNAL_LEN-1]}} , partial_product};

always @( * ) begin
    case (bit_group)
        3'b001, 3'b010: 
            partial_product = A_ext; // A 
        3'b011:
            partial_product = A_ext << 1; // 2A
        3'b101, 3'b110:
            partial_product = ((~A_ext) + {{(INTERNAL_LEN-2){1'b0}}, 2'd1}); // -A
        3'b100:
            partial_product = (~(A_ext<<1) + {{(INTERNAL_LEN-2){1'b0}}, 2'd1}); // -2A
        default: 
            partial_product = {INTERNAL_LEN{1'b0}}; //0
    endcase
end

// Shifting the final product
reg [6:0] shift_amount;

always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        shift_amount <= 7'd0;
    else if(!pause)begin
        if(clean_result)//Clean the result when finished
            shift_amount <= 7'd0;
        else if(move_to_next_group)
            shift_amount <= shift_amount + 7'd2;    
    end
    
end

//Partial Product (pp) shifted
wire [P_XLEN-1:0] pp_shift_by_1;
wire [P_XLEN-1:0] pp_shift_by_2;
wire [P_XLEN-1:0] pp_shift_by_4;
wire [P_XLEN-1:0] pp_shift_by_8;
wire [P_XLEN-1:0] pp_shift_by_16;
wire [P_XLEN-1:0] pp_shift_by_32;
wire [P_XLEN-1:0] pp_shift_by_64;

assign pp_shift_by_1  = shift_amount[0] ? (pp_extended << 1)     : pp_extended;
assign pp_shift_by_2  = shift_amount[1] ? (pp_shift_by_1 << 2)   : pp_shift_by_1;
assign pp_shift_by_4  = shift_amount[2] ? (pp_shift_by_2 << 4)   : pp_shift_by_2;
assign pp_shift_by_8  = shift_amount[3] ? (pp_shift_by_4 << 8)   : pp_shift_by_4;
assign pp_shift_by_16 = shift_amount[4] ? (pp_shift_by_8 << 16)  : pp_shift_by_8;
assign pp_shift_by_32 = shift_amount[5] ? (pp_shift_by_16 << 32) : pp_shift_by_16;
assign pp_shift_by_64 = shift_amount[6] ? (pp_shift_by_32 << 64) : pp_shift_by_32;

wire [P_XLEN-1:0] pp_shifted = pp_shift_by_64;

//Suming up the partial products
always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
        prod_result <= {P_XLEN{1'b0}};
    else if(!pause)begin
        if(clean_result)//Clean the result when finished
            prod_result <= {P_XLEN{1'b0}};
        else if(move_to_next_group)
            prod_result <= prod_result + pp_shifted;    
    end
end

endmodule
