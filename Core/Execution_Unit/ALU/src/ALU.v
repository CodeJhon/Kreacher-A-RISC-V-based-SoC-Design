module ALU(
    input [31:0] opa,
    input [31:0] opb,
    input [4:0] sel_operation,
    output [31:0] alu_result
);

`include "../ALU_CONSTANTS.vh"


reg [31:0] internal_alu_result;
assign alu_result = internal_alu_result;

always@(opa,opb,sel_operation) begin
    case(sel_operation)
        ADD:                        internal_alu_result = opa + opb;
        SUBSTRACT:                  internal_alu_result = opa - opb;
        SET_LESS_THAN_SIGNED:       internal_alu_result = {31'd0,(opa[31] & opb[31]) ? opa < opb : opa[31]}; 
        SET_LESS_THAN_UNSIGNED:     internal_alu_result = {31'd0,opa < opb};
        BITWISE_AND:                internal_alu_result = opa & opb;
        BITWISE_OR:                 internal_alu_result = opa | opb;
        BITWISE_XOR:                internal_alu_result = opa ^ opb;
        SHIFT_LEFT_LOGICAL:         internal_alu_result = opa << opb[4:0];
        SHIFT_RIGHT_LOGICAL:        internal_alu_result = opa >> opb[4:0];
        
        default:         internal_alu_result = 32'd0;
    endcase
end

endmodule