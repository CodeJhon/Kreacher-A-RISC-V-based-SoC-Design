// =============================================================================
// File        : opa_shift.v
// Author      : Jhon Steven Pinto Hernandez
// Email       : jhonstevenpintoh@gmail.com
// Description :
//   Performs operand shifting, alignment, and rotation support for execute-stage operations.
// =============================================================================

module opa_shift #(parameter XLEN = 64)(
    //Inputs
    input signed [XLEN-1:0]  opa,
    input [5:0]              shamt64,

    //Outputs
    //SLL(W)
    output [XLEN-1:0]        sll_result,
    output [XLEN-1:0]        sllw_result,
    //SRL(W)
    output [XLEN-1:0]        srl_result,
    output [31:0]            srlw_result,
    //SRA(W)
    output signed [XLEN-1:0] sra_result,
    output signed [31:0]     sraw_result
);

//------------------------------------------------ Internal Shifting Signals

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

// --- SRLW barrel shifter (32-bit logical right) ---
wire [31:0] opa_lo32 = opa[31:0];

wire [31:0] srlw_by_1;
wire [31:0] srlw_by_2;
wire [31:0] srlw_by_4;
wire [31:0] srlw_by_8;
wire [31:0] srlw_by_16;

assign srlw_by_1  = shamt64[0] ? (opa_lo32     >> 1)  : opa_lo32;
assign srlw_by_2  = shamt64[1] ? (srlw_by_1    >> 2)  : srlw_by_1;
assign srlw_by_4  = shamt64[2] ? (srlw_by_2    >> 4)  : srlw_by_2;
assign srlw_by_8  = shamt64[3] ? (srlw_by_4    >> 8)  : srlw_by_4;
assign srlw_by_16 = shamt64[4] ? (srlw_by_8    >> 16) : srlw_by_8;

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
    
//------------------------------------------------ Output assignation
//SLL(W)
assign sll_result  = sll_by_32;
assign sllw_result = sll_by_16;
//SRL(W)
assign srl_result  = srl_by_32;
assign srlw_result = srlw_by_16;
//SRA(W)
assign sra_result  = sra_by_32;
assign sraw_result = sraw_by_16;


endmodule