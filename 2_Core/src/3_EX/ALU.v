`include "../../include/CORE_CONSTANTS.vh"

module ALU #(parameter XLEN = 64)(
    input signed [XLEN-1:0]  opa,
    input signed [XLEN-1:0]  opb,
    input [4:0]              sel_operation, 

    output reg               branch_condition,
    output signed [XLEN-1:0] ALU_result
);

localparam ZERO_PAD = XLEN-1;
localparam PAD_32   = 32;

wire                  opa_less_than_opb;
wire                  opa_less_than_opb_unsigned;
wire                  opa_equal_opb;
reg signed [XLEN-1:0] internal_alu_result;


//Module implementation

assign opa_less_than_opb_unsigned = $unsigned(opa) < $unsigned(opb);
assign opa_less_than_opb          = (opa[XLEN-1] == opb[XLEN-1]) ? opa_less_than_opb_unsigned : opa[XLEN-1];
assign opa_equal_opb              = opa == opb;

//--------------------------------------------------------------------Shift signals
wire [5:0] shamt64 = opb[5:0];

// --- SLL(W) barrel shifter (logical left) ---

wire [XLEN-1:0] sll_by_1;
wire [XLEN-1:0] sll_by_2;
wire [XLEN-1:0] sll_by_4;
wire [XLEN-1:0] sll_by_8;
wire [XLEN-1:0] sll_by_16;
wire [XLEN-1:0] sll_by_32;

assign sll_by_1  = shamt64[0] ? (opa      << 1)  : opa;
assign sll_by_2  = shamt64[1] ? (sll_by_1   << 2)  : sll_by_1;
assign sll_by_4  = shamt64[2] ? (sll_by_2   << 4)  : sll_by_2;
assign sll_by_8  = shamt64[3] ? (sll_by_4   << 8)  : sll_by_4;
assign sll_by_16 = shamt64[4] ? (sll_by_8   << 16) : sll_by_8;
assign sll_by_32 = shamt64[5] ? (sll_by_16  << 32) : sll_by_16;

wire [XLEN-1:0] sll_result = sll_by_32;
wire [XLEN-1:0] sllw_result = sll_by_16;

// --- SRL barrel shifter (logical right) ---
wire [XLEN-1:0] srl_by_1;
wire [XLEN-1:0] srl_by_2;
wire [XLEN-1:0] srl_by_4;
wire [XLEN-1:0] srl_by_8;
wire [XLEN-1:0] srl_by_16;
wire [XLEN-1:0] srl_by_32;

assign srl_by_1  = shamt64[0] ? (opa      >> 1)   : opa;
assign srl_by_2  = shamt64[1] ? (srl_by_1   >> 2)  : srl_by_1;
assign srl_by_4  = shamt64[2] ? (srl_by_2   >> 4)  : srl_by_2;
assign srl_by_8  = shamt64[3] ? (srl_by_4   >> 8)  : srl_by_4;
assign srl_by_16 = shamt64[4] ? (srl_by_8   >> 16) : srl_by_8;
assign srl_by_32 = shamt64[5] ? (srl_by_16  >> 32) : srl_by_16;

wire [XLEN-1:0] srl_result = srl_by_32;

// --- SRLW barrel shifter (32-bit logical right) ---
wire [31:0] opa_lo32 = opa[31:0];

wire [31:0] srlw_by_1;
wire [31:0] srlw_by_2;
wire [31:0] srlw_by_4;
wire [31:0] srlw_by_8;
wire [31:0] srlw_by_16;

wire [31:0] opa_lo32 = opa[31:0];

assign srlw_by_1  = shamt64[0] ? (opa_lo32     >> 1)  : opa_lo32;
assign srlw_by_2  = shamt64[1] ? (srlw_by_1    >> 2)  : srlw_by_1;
assign srlw_by_4  = shamt64[2] ? (srlw_by_2    >> 4)  : srlw_by_2;
assign srlw_by_8  = shamt64[3] ? (srlw_by_4    >> 8)  : srlw_by_4;
assign srlw_by_16 = shamt64[4] ? (srlw_by_8    >> 16) : srlw_by_8;

wire [31:0] srlw_result = srlw_by_16;

// --- SRA barrel shifter (arithmetic right) ---
wire signed [XLEN-1:0] sra_by_1;
wire signed [XLEN-1:0] sra_by_2;
wire signed [XLEN-1:0] sra_by_4;
wire signed [XLEN-1:0] sra_by_8;
wire signed [XLEN-1:0] sra_by_16;
wire signed [XLEN-1:0] sra_by_32;

assign sra_by_1  = shamt64[0] ? (opa        >>> 1)  : opa;
assign sra_by_2  = shamt64[1] ? (sra_by_1   >>> 2)  : sra_by_1;
assign sra_by_4  = shamt64[2] ? (sra_by_2   >>> 4)  : sra_by_2;
assign sra_by_8  = shamt64[3] ? (sra_by_4   >>> 8)  : sra_by_4;
assign sra_by_16 = shamt64[4] ? (sra_by_8   >>> 16) : sra_by_8;
assign sra_by_32 = shamt64[5] ? (sra_by_16  >>> 32) : sra_by_16;

wire signed [XLEN-1:0] sra_result = sra_by_32;

// --- SRAW barrel shifter (32-bit arithmetic right) ---
wire signed [31:0] opa_lo32_s = opa[31:0];

wire signed [31:0] sraw_by_1;
wire signed [31:0] sraw_by_2;
wire signed [31:0] sraw_by_4;
wire signed [31:0] sraw_by_8;
wire signed [31:0] sraw_by_16;

assign sraw_by_1  = shamt64[0] ? (opa_lo32_s    >>> 1)  : opa_lo32_s;
assign sraw_by_2  = shamt64[1] ? (sraw_by_1     >>> 2)  : sraw_by_1;
assign sraw_by_4  = shamt64[2] ? (sraw_by_2     >>> 4)  : sraw_by_2;
assign sraw_by_8  = shamt64[3] ? (sraw_by_4     >>> 8)  : sraw_by_4;
assign sraw_by_16 = shamt64[4] ? (sraw_by_8     >>> 16) : sraw_by_8;

wire signed [31:0] sraw_result = sraw_by_16;


always@(opa, opb , sel_operation, opa_equal_opb, opa_less_than_opb, opa_less_than_opb_unsigned,
        sll_result, sllw_result, srl_result, srlw_result, sra_result, sraw_result) begin
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
        
        `ALU_SLL:                internal_alu_result = sll_result;
        `ALU_SLLW:               internal_alu_result = sllw_result;

        `ALU_SRL:                internal_alu_result = srl_result;
        `ALU_SRLW:               internal_alu_result = {32'd0, srlw_result};

        `ALU_SRA:                internal_alu_result = sra_result;
        `ALU_SRAW:               internal_alu_result = {32'd0, sraw_result};
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