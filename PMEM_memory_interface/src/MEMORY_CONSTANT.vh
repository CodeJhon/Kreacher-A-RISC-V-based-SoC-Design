// -------------------------
// Memory Controller States
// -------------------------
`define S_IDLE    3'd0
`define S_START   3'd1
`define S_WAIT    3'd2
`define S_FIRST_FETCH 3'd3
`define S_SUCCESS 3'd4

// -------------------------
// Handler Codes
// -------------------------
`define HANDLER_0 2'b00
`define HANDLER_1 2'b01
`define HANDLER_2 2'b10
`define HANDLER_3 2'b11

// -------------------------
// PRAM Identifiers
// -------------------------
`define PRAM_0 3'b000
`define PRAM_1 3'b001
`define PRAM_2 3'b010
`define PRAM_3 3'b011
`define PRAM_4 3'b100
`define PRAM_5 3'b101
`define PRAM_6 3'b110
`define PRAM_7 3'b111
