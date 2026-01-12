`timescale 1ns/1ps
`include "MEMORY_CONSTANT.vh"

module PMEM_interface_top
#(
    parameter XLEN  = 64, // Full data width
    parameter IXLEN = 32, // Instruction width
    parameter ADDR_BYTE_W = 17,
    parameter WORDS = 1024
)
(
    // Memory controller interface
    input  [XLEN-1:0] inst_data_write,
    input  [ADDR_BYTE_W-1:0] data_read_write_adr,
    input  addr_data_valid,
    input  [ADDR_BYTE_W-1:0] inst_fetch_adr,
    input  addr_inst_valid,
    input  is_write_PRAM,
    output [XLEN-1:0] data_read,
    output [IXLEN-1:0] instruction_read,

    //PRAM
    input clk,
    input reset_n

);

    // -------------------------
    // Wires between modules
    // -------------------------
    //pmem and odd even handler
    wire  [XLEN-1:0]      data_in_w;
    wire  [ADDR_BYTE_W-1:0] addr_handler_w;
    wire  addr_data_valid_w;
    wire  addr_inst_valid_w;
    wire [IXLEN-1:0]     inst_out_w;
    wire  we0_w;
    wire  we1_w;
    wire  cs0_w;
    wire  cs1_w;
    wire [XLEN-1:0]      data_out_w;

    // PRAM interface
    wire  [IXLEN-1:0]     data_out_even_w;
    wire  [IXLEN-1:0]     data_out_odd_w;
    wire [IXLEN-1:0]     data_in_even_w;
    wire [IXLEN-1:0]     data_in_odd_w;
    wire [9:0]           addr_w;      // 2^10 = 1024
    wire cs_even_w;
    wire cs_odd_w;
    wire we_even_w;
    wire we_odd_w;

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
        .data_read(data_read),
        .instruction_read(instruction_read),

        // Odd-even handler interface
        .data_out1(data_out_w),
        .inst_out1(inst_out_w),
        .data_in(data_in_w),
        .addr_handler1(addr_handler_w),
        .cs_0(cs0_w),
        .cs_1(cs1_w),
        .we_0(we0_w),
        .we_1(we1_w),
        .addr_data_valid_h(addr_data_valid_w),
        .addr_inst_valid_h(addr_inst_valid_w)
    );

    // -------------------------
    // Odd-even handler instance
    // -------------------------
    odd_even_handler #(
        .IXLEN(IXLEN),
        .XLEN(XLEN),
        .ADDR_BYTE_W(ADDR_BYTE_W)
    ) odd_even (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in_w),
        .addr_handler(addr_handler_w),
        .addr_data_valid(addr_data_valid_w),
        .addr_inst_valid(addr_inst_valid_w),
        .inst_out(inst_out_w),
        .we0(we0_w),
        .we1(we1_w),
        .cs0(cs0_w),
        .cs1(cs1_w),
        .data_out(data_out_w),

        // PRAM interface
        .data_out_even(data_out_even_w),
        .data_out_odd(data_out_odd_w),
        .data_in_even(data_in_even_w),
        .data_in_odd(data_in_odd_w),
        .addr(addr_w),       // 2^10 = 1024
        .cs_even(cs_even_w),
        .cs_odd(cs_odd_w),
        .we_even(we_even_w),
        .we_odd(we_odd_w)
    );

    // -------------------------
    // PRAM instances
    // -------------------------
    RAM #(
        .ADDR_LINES(10),
        .WORDS  (1024),
        .FILE_LOAD(0),
        .ROW_WIDTH(32)
    ) PRAM_even (
        .clk(clk),
        .we(we_even_w),
        .cs(cs_even_w),
        .data_in(data_in_even_w),
        .addr(addr_w),
        .data_out(data_out_even_w)
    );

    RAM #(
        .ADDR_LINES(10),
        .WORDS  (1024),
        .FILE_LOAD(0),
        .ROW_WIDTH(32)
    ) PRAM_odd (
        .clk(clk),
        .we(we_odd_w),
        .cs(cs_odd_w),
        .data_in(data_in_odd_w),
        .addr(addr_w),
        .data_out(data_out_odd_w)
    );

endmodule
