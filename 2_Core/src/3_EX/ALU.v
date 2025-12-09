`include "../../include/CORE_CONSTANTS.vh"

module ALU #(parameter XLEN = 32)(
    input signed [XLEN-1:0]  opa,
    input signed [XLEN-1:0]  opb,
    input [4:0]              sel_operation, 

    output reg               branch_condition,
    output signed [XLEN-1:0] ALU_result
);

localparam ZERO_PAD = XLEN-1;

wire                  opa_less_than_opb;
wire                  opa_less_than_opb_unsigned;
wire                  opa_equal_opb;
reg signed [XLEN-1:0] internal_alu_result;


//Module implementation

assign opa_less_than_opb_unsigned = $unsigned(opa) < $unsigned(opb);
assign opa_less_than_opb          = (opa[XLEN-1] == opb[XLEN-1]) ? opa_less_than_opb_unsigned : opa[XLEN-1];
assign opa_equal_opb              = opa == opb;

always@(opa, opb , sel_operation, opa_equal_opb, opa_less_than_opb, opa_less_than_opb_unsigned) begin
    //Default values
    internal_alu_result = 0;
    branch_condition    = 0;

    case(sel_operation)
        //----------------------------------------------------------------INTERNAL ALU RESULT
        //Forwarding
        `ALU_FORWARD_B:          internal_alu_result = opb;
        //Operations
        `ALU_ADD:                internal_alu_result = opa + opb;
        `ALU_SUB:                internal_alu_result = opa - opb;
        `ALU_SLT:                internal_alu_result = {{ZERO_PAD{1'b0}},opa_less_than_opb}; 
        `ALU_SLTU:               internal_alu_result = {{ZERO_PAD{1'b0}},opa_less_than_opb_unsigned};
        `ALU_AND:                internal_alu_result = opa & opb;
        `ALU_OR:                 internal_alu_result = opa | opb;
        `ALU_XOR:                internal_alu_result = opa ^ opb;
        `ALU_SLL:                internal_alu_result = opa << opb[4:0];
        `ALU_SRL:                internal_alu_result = opa >> opb[4:0];
        `ALU_SRA:                internal_alu_result = opa >>> opb[4:0];
        //------------------------------------------------------------------BRANCH CONDITION
        `ALU_EQ:                 branch_condition = opa_equal_opb;
        `ALU_NE:                 branch_condition = ~opa_equal_opb;
        `ALU_LT:                 branch_condition = opa_less_than_opb;
        `ALU_GE:                 branch_condition = ~opa_less_than_opb;
        `ALU_LTU:                branch_condition = opa_less_than_opb_unsigned;
        `ALU_GEU:                branch_condition = ~opa_less_than_opb_unsigned;
        default: begin
            //Default values
            internal_alu_result = 0;
            branch_condition    = 0;
        end                 
    endcase
end


//Output assignment
assign ALU_result = internal_alu_result;


endmodule