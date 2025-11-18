`include "../CORE_CONSTANTS.vh"

module ALU #(parameter XLEN = 32)(
    input signed [XLEN-1:0] opa,
    input signed [XLEN-1:0] opb,
    input [4:0] sel_operation, 
    output signed [XLEN-1:0] ALU_result
);

localparam ZERO_PAD = XLEN-1;
reg signed [XLEN-1:0] internal_alu_result;
assign ALU_result = internal_alu_result;

always@(opa,opb,sel_operation) begin
    case(sel_operation)
        //Forwarding
        `ALU_FORWARD_A:          internal_alu_result = opa;
        //Operations
        `ALU_ADD:                internal_alu_result = opa + opb;
        `ALU_SUB:                internal_alu_result = opa - opb;
        `ALU_SLT:                internal_alu_result = {{ZERO_PAD{1'b0}},(opa[XLEN-1] == opb[XLEN-1]) ? opa < opb : opa[XLEN-1]}; 
        `ALU_SLTU:               internal_alu_result = {{ZERO_PAD{1'b0}},opa < opb};
        `ALU_AND:                internal_alu_result = opa & opb;
        `ALU_OR:                 internal_alu_result = opa | opb;
        `ALU_XOR:                internal_alu_result = opa ^ opb;
        `ALU_SLL:                internal_alu_result = opa << opb[4:0];
        `ALU_SRL:                internal_alu_result = opa >> opb[4:0];
        `ALU_SRA:                internal_alu_result = opa >>> opb[4:0];
        default:                 internal_alu_result = 0;
    endcase
end

endmodule