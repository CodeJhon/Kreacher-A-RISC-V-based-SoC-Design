`timescale 1ns/1ps

module top_wrapper#(
  parameter ADDR_BYTE_W = 17,
  parameter DATA_W      = 64,
  parameter RAM_WORDS   = 8192,
  parameter RAM_ADDR_W  = 14
)(
    `ifndef SYNTHESIS 
        output           commit_valid,
        output [DATA_W-1:0]   commit_PC,
        output [31:0]   commit_instruction,
        output [4:0]     commit_rd_addr,
        output [DATA_W-1:0]   commit_rd_value,
    `endif
    
    input I_CLK,
    input I_A_RESET_L,
    input I_INTR_H,
    output O_INTR_ACK
);
    // ----------------------------
    // SPI interconnect wires
    // ----------------------------
    wire spi_ss_n;
    wire spi_mosi;
    wire spi_miso;
    wire spi_clk;
    
    //RAM
    wire                  ram_cs;
    wire                  ram_we;
    wire [RAM_ADDR_W-1:0] ram_addr;
    wire [DATA_W-1:0]     ram_wdata;
    wire [DATA_W-1:0]     ram_rdata;

    // ----------------------------
    // Interrupt wires
    // ----------------------------
    wire intr_h;
    wire intr_ack;

    kreacher_top s (
        `ifndef SYNTHESIS
            .commit_valid(commit_valid),
            .commit_PC(commit_PC),
            .commit_instruction(commit_instruction),
            .commit_rd_addr(commit_rd_addr),
            .commit_rd_value(commit_rd_value),
        `endif

        .I_CLK        (I_CLK),
        .I_A_RESET_L  (I_A_RESET_L),

        // SPI signals (MASTER side)
        .O_SS         (spi_ss_n),
        .O_MOSI       (spi_mosi),
        .O_MISO       (spi_miso),

        // Interrupt
        .I_INTR_H     (intr_h),
        .O_INTR_ACK   (intr_ack)
    );

     spi_slave_interface #(
        .XLEN     (64),
        .DATA_W   (64),
        .ADDR14_W (14)
    ) u_spi_slave (
        .I_CLK     (I_CLK),
        .I_RSTN    (I_A_RESET_L),

        .I_SS_N    (spi_ss_n),
        .I_MOSI    (spi_mosi),
        .O_MISO    (spi_miso),

        .ram_we    (ram_we),
        .ram_cs    (ram_cs),
        .ram_addr  (ram_addr),
        .ram_wdata (ram_wdata),
        .ram_rdata (ram_rdata)
    );
   
    RAM #(
        .WORDS  (8192),
        .ADDR_W (14),
        .IXLEN  (64)
    ) u_ram (
        .clk      (I_CLK),
        .reset    (~I_A_RESET_L),

        .cs       (ram_cs),
        .we       (ram_we),

        .addr     (ram_addr),
        .data_in  (ram_wdata),
        .data_out (ram_rdata)
    );

endmodule
