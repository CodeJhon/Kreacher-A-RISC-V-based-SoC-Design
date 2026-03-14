`include "../../include/CORE_CONSTANTS.vh"

module ALU #(parameter XLEN = 64)(
    //Global
    input clk,
    input reset_n,
    input pause,

    //Operands & Operation Type
    input signed [XLEN-1:0]  opa,
    input signed [XLEN-1:0]  opb,
    input [5:0]              sel_operation, 

    //Control
    output                   pause_to_calculate,

    //Results
    output reg               branch_condition,
    output signed [XLEN-1:0] ALU_result
);

//************Modules implementation********

//--------------------------------------------------------------------Multiplication and Division modules
localparam P_XLEN = XLEN*2; //Multiplication result -> Twice in size as operands
wire signed [P_XLEN-1:0] mul_result;
wire                     pause_to_muliply;
multiplier_top #(.XLEN(XLEN)) multiplier_top_inst (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause),

    //Operands & Operation Type
    .opa(opa),
    .opb(opb),
    .sel_operation(sel_operation),

    //Output Flags
    .pause_to_muliply(pause_to_muliply),

    //Result
    .mul_result(mul_result)
);

wire signed [XLEN-1:0] remainder_result;
wire signed [XLEN-1:0] quotient_result;
wire                   pause_to_divide;
divider_top #(.XLEN(64)) divider_top_inst (
    //Global
    .clk(clk),
    .reset_n(reset_n),
    .pause(pause),

    //Operands & Operation Type
    .opa(opa),
    .opb(opb),
    .sel_operation(sel_operation),

    //Output Flags
    .pause_to_divide(pause_to_divide),

    //Result
    .remainder_result(remainder_result),
    .quotient_result(quotient_result)
);


//--------------------------------------------------------------------Shifting opa by opb times
wire [5:0] shamt64 = opb[5:0];
//SLL(W)
wire [XLEN-1:0]        sll_result;
wire [XLEN-1:0]        sllw_result;
//SRL(W)
wire [XLEN-1:0]        srl_result;
wire [31:0]            srlw_result;
//SRA(W)
wire signed [XLEN-1:0] sra_result;
wire signed [31:0]     sraw_result;

opa_shift #(.XLEN(XLEN)) opa_shift_inst (
    //Inputs
    .opa(opa),
    .shamt64(shamt64),

    //Outputs
    //SLL(W)
    .sll_result(sll_result),
    .sllw_result(sllw_result),
    //SRL(W)
    .srl_result(srl_result),
    .srlw_result(srlw_result),
    //SRA(W)
    .sra_result(sra_result),
    .sraw_result(sraw_result)
);


//------------------------------------------------------------------Internal ALU result assignation
//Internal signals needed for ALU operations
wire opa_less_than_opb_unsigned = $unsigned(opa) < $unsigned(opb);
wire opa_less_than_opb          = (opa[XLEN-1] == opb[XLEN-1]) ? opa_less_than_opb_unsigned : opa[XLEN-1];
wire opa_equal_opb              = opa == opb;

wire signed [XLEN-1:0] opa_plus_opb = opa + opb;
wire signed [XLEN-1:0] opa_minus_opb = opa - opb;

//Internal ALU result assignation
reg signed [XLEN-1:0] internal_alu_result;
always@( * ) begin
    
    //Default values
    internal_alu_result = {XLEN{1'b0}};
    branch_condition    = 1'b0;

    case(sel_operation)
        //----------------------------------------------------------------INTERNAL ALU RESULT
        //Forwarding
        `ALU_FORWARD_A:          internal_alu_result = opa;
        `ALU_FORWARD_B:          internal_alu_result = opb;
        //Operations
        `ALU_ADD:                internal_alu_result = opa_plus_opb;
        `ALU_ADDW:               internal_alu_result = $signed(opa_plus_opb[31:0]);
        `ALU_SUB:                internal_alu_result = opa_minus_opb;
        `ALU_SUBW:               internal_alu_result = $signed(opa_minus_opb[31:0]);
        `ALU_SLT:                internal_alu_result = $unsigned(opa_less_than_opb); 
        `ALU_SLTU:               internal_alu_result = $unsigned(opa_less_than_opb_unsigned);
        `ALU_AND:                internal_alu_result = opa & opb;
        `ALU_OR:                 internal_alu_result = opa | opb;
        `ALU_XOR:                internal_alu_result = opa ^ opb;
        
        `ALU_SLL:                internal_alu_result = sll_result;
        `ALU_SLLW:               internal_alu_result = $signed(sllw_result[31:0]);

        `ALU_SRL:                internal_alu_result = srl_result;
        `ALU_SRLW:               internal_alu_result = $unsigned(srlw_result);

        `ALU_SRA:                internal_alu_result = sra_result;
        `ALU_SRAW:               internal_alu_result = $unsigned(sraw_result);

        //CSR Special
        `ALU_CSRRC:              internal_alu_result = opa & (~opb);

        //--- M-extension
        //Multiplication Instructions
        `ALU_MUL:                internal_alu_result = mul_result[XLEN-1:0];//Lower part retrieved
        
        `ALU_MULH, 
        `ALU_MULHU,
        `ALU_MULHSU:             internal_alu_result = mul_result[P_XLEN-1:XLEN];//Upper part retrieved
        
        `ALU_MULW:               internal_alu_result = $signed(mul_result[31:0]);//Sign-extension of lower 32 bits
        
        //Division Instructions
        `ALU_DIV, `ALU_DIVU:     internal_alu_result = quotient_result;
        `ALU_REM, `ALU_REMU:     internal_alu_result = remainder_result;

        `ALU_DIVW, `ALU_DIVUW:   internal_alu_result = $signed(quotient_result[31:0]);
        `ALU_REMW, `ALU_REMUW:   internal_alu_result = $signed(remainder_result[31:0]);
        
        //------------------------------------------------------------------BRANCH CONDITION
        `ALU_EQ:                 branch_condition = opa_equal_opb;
        `ALU_NE:                 branch_condition = ~opa_equal_opb;
        `ALU_LT:                 branch_condition = opa_less_than_opb;
        `ALU_GE:                 branch_condition = ~opa_less_than_opb;
        `ALU_LTU:                branch_condition = opa_less_than_opb_unsigned;
        `ALU_GEU:                branch_condition = ~opa_less_than_opb_unsigned;
        default: begin
            //Default values
            internal_alu_result = {XLEN{1'b0}};
            branch_condition    = 1'b0;
        end                 
    endcase
end

//Output assignment
assign ALU_result = internal_alu_result;

//Control
assign pause_to_calculate = pause_to_muliply | pause_to_divide;

endmodule