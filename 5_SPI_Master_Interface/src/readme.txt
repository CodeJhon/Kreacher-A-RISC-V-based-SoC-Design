1.how to connect spi master interface and spi slave interface
spi_master_interface #(
  .ADDR_BYTE_W(17),
  .DATA_W(64)
) u_master (
  .I_CLK (clk),
  .I_RSTN(rstn),

  .start     (start),
  .is_write  (is_write),
  .byte_addr (byte_addr),
  .burst_len (burst_len),
  .wdata     (wdata),
  .rdata     (rdata),
  .rvalid    (rvalid),
  .busy      (busy),
  .done      (done),

  .O_SS   (ss_n),
  .O_MOSI (mosi),
  .I_MISO (miso)
);
2.how to connect spi slave interface and RAM
spi_slave_interface #(
  .XLEN(64),
  .DATA_W(64),
  .ADDR14_W(14)
) u_slave_if (
  .I_CLK    (clk),
  .I_RSTN   (rstn),

  .I_SS_N   (ss_n),
  .I_MOSI   (mosi),
  .O_MISO   (miso),

  .ram_we   (ram_we),
  .ram_cs   (ram_cs),
  .ram_addr (ram_addr),
  .ram_wdata(ram_wdata),
  .ram_rdata(ram_rdata)
);

RAM #(
  .XLEN(64),
  .DEPTH(1024),
  .MEM_FILE("file_example.txt"),
  .DELAY(4)
) u_ram (
  .clk     (clk),
  .reset   (~rstn),      // RAM reset high
  .we      (ram_we),
  .cs      (ram_cs),
  .data_in (ram_wdata),
  .addr    (ram_addr),   // byte address
  .data_out(ram_rdata)
);