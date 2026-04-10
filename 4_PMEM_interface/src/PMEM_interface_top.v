`timescale 1ns/1ps
`include "MEMORY_CONSTANT.vh"

module PMEM_interface_top
#(
    parameter XLEN              = 64,                              //Full data width
    parameter IXLEN             = 32,                              //Instruction width
    parameter ADDR_BYTE_W       = 17,                              //Address width
    parameter ADDR_WORD_W       = 10,                              //Word Address width
    parameter NUM_HANDLERS      = 4,                               //Handler count
    parameter PRAMS_PER_HANDLER = 2,                               //PRAMS per hanler
    parameter NUM_PRAMS         = NUM_HANDLERS * PRAMS_PER_HANDLER //PRAM count
)
(
    // Memory controller interface
    input  [XLEN-1:0]        inst_data_write,
    input  [ADDR_BYTE_W-1:0] data_read_write_adr,
    input                    addr_data_valid,
    input  [ADDR_BYTE_W-1:0] inst_fetch_adr,
    input                    addr_inst_valid,
    input                    is_write_PRAM,
    input  [XLEN-1:0]        init_internal_mask,
    output [XLEN-1:0]        data_read,
    output [IXLEN-1:0]       instruction_read,
    output                   pause_to_schedule,

    //PRAM
    input                    clk,
    input                    reset_n
);

parameter INITFILE = "none";
    // -------------------------
    // Wires between modules
    // -------------------------

    //pmem and odd even handler
    wire [XLEN-1:0]         data_in_w;
    wire                    addr_data_valid_w;
    wire                    addr_inst_valid_w;

    wire [(ADDR_BYTE_W*NUM_HANDLERS)-1:0] addr_handler_w;
    wire [(IXLEN*NUM_HANDLERS)-1:0] init_internal_mask_odd;
    wire [(IXLEN*NUM_HANDLERS)-1:0] init_internal_mask_even;

    wire [XLEN-1:0]         init_internal_mask_odd_even;
    wire [NUM_PRAMS-1:0]    we_w;
    wire [NUM_PRAMS-1:0]    cs_w;
    wire [(XLEN*NUM_HANDLERS)-1:0] data_out_w;
    wire [(IXLEN*NUM_HANDLERS)-1:0] inst_out_w;
    wire [NUM_HANDLERS-1:0] pause_to_schedule_odd_even_w;
    
    // PRAM interface
    wire [(IXLEN*NUM_HANDLERS)-1:0] data_out_even_w;
    wire [(IXLEN*NUM_HANDLERS)-1:0] data_out_odd_w;
    wire [(IXLEN*NUM_HANDLERS)-1:0] data_in_even_w;
    wire [(IXLEN*NUM_HANDLERS)-1:0] data_in_odd_w;
    wire[(ADDR_WORD_W*NUM_HANDLERS)-1:0]     odd_addr;
    wire[(ADDR_WORD_W*NUM_HANDLERS)-1:0]     even_addr;

    wire [NUM_HANDLERS-1:0] cs_even_w;
    wire [NUM_HANDLERS-1:0] cs_odd_w;
    wire [NUM_HANDLERS-1:0] we_even_w;
    wire [NUM_HANDLERS-1:0] we_odd_w;
    wire [1:0]              zeros;
    assign zeros     =      2'b00;

    // -------------------------
    // PMEM_interface instance
    // -------------------------
    PMEM_interface #(
        .XLEN(XLEN),
        .IXLEN(IXLEN),
        .ADDR_BYTE_W(ADDR_BYTE_W)
    ) pmem_if (
        .clk(clk),
        .reset_n(reset_n),
        .inst_data_write(inst_data_write),
        .data_read_write_adr(data_read_write_adr),
        .addr_data_valid(addr_data_valid),
        .inst_fetch_adr(inst_fetch_adr),
        .addr_inst_valid(addr_inst_valid),
        .is_write_PRAM(is_write_PRAM),
        .init_internal_mask(init_internal_mask),
        .EIB_instruction_read(instruction_read),
        .pause_to_schedule(pause_to_schedule),
        .data_read(data_read),
        .inst_out(inst_out_w),
        .data_out(data_out_w),
        .data_in(data_in_w),
        .addr_handler(addr_handler_w),
        .init_internal_mask_odd_even(init_internal_mask_odd_even),
        .addr_data_valid_h(addr_data_valid_w),
        .addr_inst_valid_h(addr_inst_valid_w),
        .cs(cs_w),
        .we(we_w),
        .pause_to_schedule_odd_even(pause_to_schedule_odd_even_w)
    );

    // -------------------------
    // Odd-even handler instance
    // -------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_HANDLERS; i = i + 1) begin : GEN_HANDLERS
            odd_even_handler #(
                .IXLEN(IXLEN),
                .XLEN(XLEN),
                .ADDR_BYTE_W(ADDR_BYTE_W)
            ) handler_i (
                .clk(clk),
                .reset_n(reset_n),

                .data_in(data_in_w),
                .addr_handler(addr_handler_w[(i+1)*ADDR_BYTE_W-1 -: ADDR_BYTE_W]),
                .addr_data_valid(addr_data_valid_w),
                .addr_inst_valid(addr_inst_valid_w),

                .inst_out(inst_out_w[(i+1)*IXLEN-1 -: IXLEN]),
                .data_out(data_out_w[(i+1)*XLEN-1 -: XLEN]),

                .we(we_w[((i*2)+1):(i*2)]),
                .cs(cs_w[((i*2)+1):(i*2)]),

                .macro_sel_hold(pause_to_schedule_odd_even_w[i]),
                .init_internal_mask_odd_even(init_internal_mask_odd_even),

                // PRAM interface
                .data_out_even(data_out_even_w[(i+1)*IXLEN-1 -: IXLEN]),
                .data_out_odd (data_out_odd_w[(i+1)*IXLEN-1 -: IXLEN]),
                .data_in_even (data_in_even_w[(i+1)*IXLEN-1 -: IXLEN]),
                .data_in_odd  (data_in_odd_w[(i+1)*IXLEN-1 -: IXLEN]),

                .odd_addr(odd_addr[(i+1)*ADDR_WORD_W-1 -: ADDR_WORD_W]),
                .even_addr(even_addr[(i+1)*ADDR_WORD_W-1 -: ADDR_WORD_W]),
                .cs_even(cs_even_w[i]),
                .cs_odd(cs_odd_w[i]),
                .we_even(we_even_w[i]),
                .we_odd(we_odd_w[i]),
                .init_internal_mask_odd(init_internal_mask_odd[(i+1)*IXLEN-1 -: IXLEN]),
                .init_internal_mask_even(init_internal_mask_even[(i+1)*IXLEN-1 -: IXLEN])
            );
        end
    endgenerate
    
    // -------------------------
    // PRAM instances
    // -------------------------
    genvar j;
    generate
        for (j = 0; j < NUM_HANDLERS; j = j + 1) begin : GEN_EVEN_MACROS
            HM_1P_1024x32_1cr #(
                .INITFILE (INITFILE)
            ) PRAM_even (
                .CLK_I(clk),
                .CS_I(cs_even_w[j]),
                .WE_I(we_even_w[j]),
                .RE_I(!we_even_w[j]),
                .ADDR_I(even_addr[(j+1)*ADDR_WORD_W-1 -: ADDR_WORD_W]),
                .BM_I(init_internal_mask_even[(j+1)*IXLEN-1 -: IXLEN]),
                .DW_I(data_in_even_w[(j+1)*IXLEN-1 -: IXLEN]),
                .DR_O(data_out_even_w[(j+1)*IXLEN-1 -: IXLEN]),
                .DLYCLK(zeros),
                .DLYH(zeros),
                .DLYL(zeros)
            );
        end
    endgenerate

    genvar k;
    generate
        for (k = 0; k < NUM_HANDLERS; k = k + 1) begin : GEN_ODD_MACROS
            HM_1P_1024x32_1cr #(
                .INITFILE (INITFILE)
            ) PRAM_odd (
                .CLK_I(clk),
                .CS_I(cs_odd_w[k]),
                .WE_I(we_odd_w[k]),
                .RE_I(!we_odd_w[k]),
                .ADDR_I(odd_addr[(k+1)*ADDR_WORD_W-1 -: ADDR_WORD_W]),
                .BM_I(init_internal_mask_odd[(k+1)*IXLEN-1 -: IXLEN]),
                .DW_I(data_in_odd_w[(k+1)*IXLEN-1 -: IXLEN]),
                .DR_O(data_out_odd_w[(k+1)*IXLEN-1 -: IXLEN]),
                .DLYCLK(zeros),
                .DLYH(zeros),
                .DLYL(zeros)
            );
        end
    endgenerate

endmodule
