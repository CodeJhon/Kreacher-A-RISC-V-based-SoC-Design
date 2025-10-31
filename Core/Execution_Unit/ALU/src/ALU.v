module ALU(
    input [31:0] opa,
    input [31:0] opb,
    input [4:0] sel_operation,
    output [31:0] alu_result
);

localparam ADD                             = 5'b00000;
localparam SUBSTRACT                       = 5'b00001;
localparam SET_LESS_THAN_SIGNED            = 5'b00010;
localparam SET_LESS_THAN_UNSIGNED          = 5'b00011;
localparam BITWISE_AND                     = 5'b00100;
localparam BITWISE_OR                      = 5'b00101;
localparam BITWISE_XOR                     = 5'b00110;
localparam SHIFT_LEFT_LOGICAL              = 5'b00111;
localparam SHIFT_RIGHT_LOGICAL             = 5'b01000;
localparam SHIFT_RIGHT_ARITHMETIC          = 5'b01001;
localparam PASS_OPERAND                    = 5'b01010;

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