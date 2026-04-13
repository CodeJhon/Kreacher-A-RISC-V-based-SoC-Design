 // =============================================================================
// File        : INIT_MEM_CONSTANTS.vh
// Author      : Sanjai Palanisamy
// Email       : sanjai.palanisamy171@gmail.com
// Description :
//   Defines constants for the memory controller FSM states and SPI interface control modes.
// =============================================================================

 // ================= Memory Controller States =================
`define S_IDLE                 4'd0
`define S_START                4'd1
`define S_WAIT                 4'd2
`define S_FIRST_FETCH          4'd3
`define S_NORMAL_OP            4'd4
`define S_PARTIAL_READ         4'd5
`define S_APPLY_MASK           4'd6
`define S_PARTIAL_WRITE        4'd7
`define S_PARTIAL_STORE_DONE   4'd8

 // ================= SPI rdata types ==========================
`define INITIALIZATION_R       2'b00
`define LOAD_STORE_OPERATION_R 2'b01
`define PARTIAL_WRITE          2'b10

 // ================= SPI write_enable states ==================
`define LOAD_STORE_OPERATION_W 2'd0
`define INITIALIZATION_W       2'd1
`define PARTIAL_READ           2'd2

 // ================= SPI write states =========================
`define NORMAL_WDATA           1'b0
`define MASKED_WDATA           1'b1

 // ================= word data states =========================
 `define INTERNAL              1'b0
 `define EXTERNAL              1'b1