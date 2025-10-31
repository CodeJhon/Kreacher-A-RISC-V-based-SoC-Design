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
        ADD:             internal_alu_result = opa + opb;
        SUBSTRACT:       internal_alu_result = opa - opb;
        default:         internal_alu_result = 32'd0;
    endcase
end

endmodule