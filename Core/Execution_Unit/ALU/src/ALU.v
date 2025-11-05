module ALU(
    input signed [31:0] opa,
    input signed [31:0] opb,
    input [3:0] sel_operation,
    output signed [31:0] alu_result
);

`include "./ALU_CONSTANTS.vh"

reg signed [31:0] internal_alu_result;
assign alu_result = internal_alu_result;

always@(opa,opb,sel_operation) begin
    case(sel_operation)
        ALU_ADD:                internal_alu_result = opa + opb;
        ALU_SUB:                internal_alu_result = opa - opb;
        ALU_SLT:                internal_alu_result = {31'd0,(opa[31] == opb[31]) ? opa < opb : opa[31]}; 
        ALU_SLTU:               internal_alu_result = {31'd0,opa < opb};
        ALU_AND:                internal_alu_result = opa & opb;
        ALU_OR:                 internal_alu_result = opa | opb;
        ALU_XOR:                internal_alu_result = opa ^ opb;
        ALU_SLL:                internal_alu_result = opa << opb[4:0];
        ALU_SRL:                internal_alu_result = opa >> opb[4:0];
        ALU_SRA:                internal_alu_result = opa >>> opb[4:0];
        
        default:;
    endcase
end

endmodule