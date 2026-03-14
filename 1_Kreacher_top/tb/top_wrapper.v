`timescale 1ns/1ps

module top_wrapper#(
  parameter ADDR_BYTE_W = 17,
  parameter DATA_W      = 64,
  parameter external_mem_WORDS   = 8192,
  parameter external_mem_ADDR_W  = 14
)(
    input I_CLK,
    input I_A_RESET_L,
    input  [1:0] I_INTR_H,
    output [1:0] O_INTR_ACK
);
    // ----------------------------
    // SPI interconnect wires
    // ----------------------------
    wire spi_ss_n;
    wire spi_mosi;
    wire spi_miso;
    wire spi_clk;
    
    //external memory
    wire                  external_mem_cs;
    wire                  external_mem_we;
    wire [external_mem_ADDR_W-1:0] external_mem_addr;
    wire [DATA_W-1:0]     external_mem_wdata;
    wire [DATA_W-1:0]     external_mem_rdata;

    wire interrupt_1, interrupt_2;
    wire ack_1, ack_2;
    assign interrupt_1 = I_INTR_H[0];
    assign interrupt_2 = I_INTR_H[1];
    assign ack_1 = O_INTR_ACK[0];
    assign ack_2 = O_INTR_ACK[1];



    kreacher_top u_kreacher_top (
        .I_CLK        (I_CLK),
        .I_A_RESET_L  (I_A_RESET_L),

        // SPI signals (MASTER side)
        .O_SS         (spi_ss_n),
        .O_MOSI       (spi_mosi),
        .O_MISO       (spi_miso),

        // Interrupt
        .I_INTR_H     (I_INTR_H),
        .O_INTR_ACK   (O_INTR_ACK)
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

        .external_mem_we    (external_mem_we),
        .external_mem_cs    (external_mem_cs),
        .external_mem_addr  (external_mem_addr),
        .external_mem_wdata (external_mem_wdata),
        .external_mem_rdata (external_mem_rdata)
    );
   
    RAM #(
        .ADDR_LINES(14),
        .WORDS  (8192),
        .FILE_LOAD(1),
        .ROW_WIDTH(64),
        .MEM_FILE("DMEM_content.mem")
    ) external_memory (
        .clk      (I_CLK),
        .cs       (external_mem_cs),
        .we       (external_mem_we),
        .addr     (external_mem_addr),
        .data_in  (external_mem_wdata),
        .data_out (external_mem_rdata)
    );

endmodule
