// =============================================================================
// File        : odd_even_handler.v
// Author      : Sanjai Palanisamy
// Email       : sanjai.palanisamy171@gmail.com
// Description :
//   Routes memory access signals by determining whether the address maps to the odd or 
// even memory macro and directing the signal flow accordingly.
// =============================================================================

module odd_even_handler
#(
    parameter IXLEN         = 32,      // Instruction width
    parameter XLEN          = 64,      // Full data width
    parameter ADDR_BYTE_W   = 17,      //Address width
    parameter ADDR_WORD_W   = 10
)
(
    // Internal memory interface
    input                    clk,
    input                    reset_n,
    input  [XLEN-1:0]        data_in,
    input  [ADDR_BYTE_W-1:0] addr_handler,
    input                    addr_data_valid,
    input                    addr_inst_valid,
    input [1:0]              we,
    input [1:0]              cs,
    input                    macro_sel_hold,
    input [XLEN-1:0]         init_internal_mask_odd_even,
    output [IXLEN-1:0]       inst_out,
    output [XLEN-1:0]        data_out,

    // PRAM interface
    input  [IXLEN-1:0]       data_out_even,
    input  [IXLEN-1:0]       data_out_odd,
    output [IXLEN-1:0]       data_in_even,
    output [IXLEN-1:0]       data_in_odd,
    output [ADDR_WORD_W-1:0] odd_addr,
    output [ADDR_WORD_W-1:0] even_addr,
    output                   cs_even,
    output                   cs_odd,
    output                   we_even,
    output                   we_odd,
    output [IXLEN-1:0]       init_internal_mask_odd,
    output [IXLEN-1:0]       init_internal_mask_even
);

    reg                      macro_sel_q;
    wire                     word_lane_sel;
    wire                     any_cs;
    wire [ADDR_WORD_W-1:0]   addr;
    wire [ADDR_WORD_W-1:0]   macro_addr_lower;
    wire [ADDR_WORD_W-1:0]   macro_addr_higher;
    wire [IXLEN-1:0]         init_internal_mask_lower;
    wire [IXLEN-1:0]         init_internal_mask_higher;
    wire [IXLEN-1:0]         data_in_lower;
    wire [IXLEN-1:0]         data_in_higher;

    assign word_lane_sel             = addr_handler[2];
    assign addr                      = addr_handler[ADDR_WORD_W+2:3];
    assign macro_addr_lower          = addr;
    assign macro_addr_higher         = (word_lane_sel && addr_data_valid) ? (addr + 10'd1) : addr;
    assign any_cs                    = cs[0] || cs[1];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            macro_sel_q              <= 1'b0;
        end
        else if (addr_inst_valid && !macro_sel_hold) begin
            macro_sel_q              <= word_lane_sel;
        end
    end

    // PRAM interface: split 64-bit access across even/odd 32-bit macros
    assign data_in_lower             = data_in[31:0];
    assign data_in_higher            = data_in[63:32];

    assign init_internal_mask_lower  = init_internal_mask_odd_even[31:0];
    assign init_internal_mask_higher = init_internal_mask_odd_even[63:32];
    
    assign odd_addr                  = word_lane_sel ? macro_addr_lower  : macro_addr_higher;
    assign even_addr                 = word_lane_sel ? macro_addr_higher : macro_addr_lower;

    assign cs_odd                    = addr_data_valid ? any_cs : cs[1];
    assign cs_even                   = addr_data_valid ? any_cs : cs[0];

    assign init_internal_mask_odd    = word_lane_sel ? init_internal_mask_lower  : init_internal_mask_higher;
    assign init_internal_mask_even   = word_lane_sel ? init_internal_mask_higher : init_internal_mask_lower;

    assign data_in_odd               = word_lane_sel ? data_in_lower  : data_in_higher;
    assign data_in_even              = word_lane_sel ? data_in_higher : data_in_lower;

    assign we_odd                    = we[1];
    assign we_even                   = we[0];

    assign data_out                  = {data_out_odd, data_out_even};
    assign inst_out                  = macro_sel_q ? data_out_odd : data_out_even;

endmodule

