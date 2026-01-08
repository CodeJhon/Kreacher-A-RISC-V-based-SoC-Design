`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for spi_master_interface
// - Uses a simple behavioral SPI slave model
// - Slave only looks at CS/SCK/MOSI, never peeks inside DUT
//////////////////////////////////////////////////////////////////////////////////

module tb_spi;

  // ----------------------------------------------------------------
  // clock / reset
  // ----------------------------------------------------------------
  reg  I_CLK  = 1'b0;
  reg  I_RSTN = 1'b0;

  // 50 MHz system clock => 20 ns period
  localparam real TCK = 20.0;   // ns
  always #(TCK/2.0) I_CLK = ~I_CLK;


  // ----------------------------------------------------------------
  // DUT ports
  // ----------------------------------------------------------------
  reg         start;
  reg         is_write;
  reg  [13:0] byte_addr;       // matches ADDR_BYTE_W=14
  reg  [15:0] burst_len;
  reg  [63:0] wdata;

  wire [63:0] rdata;
  wire        rvalid;
  wire        busy, done;

  wire        O_SS;
  wire        O_MOSI;
  reg         I_MISO;

  // ----------------------------------------------------------------
  // DUT instance
  // ----------------------------------------------------------------
  spi_master_interface #(
    .ADDR_BYTE_W(14),
    .DATA_W     (64)
  ) dut (
    .I_CLK   (I_CLK),
    .I_RSTN  (I_RSTN),
    .start   (start),
    .is_write(is_write),
    .byte_addr(byte_addr),
    .burst_len(burst_len),
    .wdata   (wdata),
    .rdata   (rdata),
    .rvalid  (rvalid),
    .busy    (busy),
    .done    (done),
    .O_SS    (O_SS),
    .O_MOSI  (O_MOSI),
    .I_MISO  (I_MISO)
  );

  // ----------------------------------------------------------------
  // Simple behavioral SPI slave
  //
  // Protocol assumptions (aligned with spi_master_interface):
  //  - CS (O_SS) active low
  //  - Mode 0 style timing:
  //      * Master changes MOSI on negedge I_CLK
  //      * Slave samples MOSI on posedge I_CLK
  //      * Slave changes MISO on negedge I_CLK
  //      * Master samples MISO on posedge I_CLK
  //  - Transaction format:
  //      CS low ->
  //        16-bit header MSB-first:
  //          header[15] = is_write (1=write, 0=read)
  //          header[14:1] = byte_addr[13:0]
  //          header[0]    = dummy_bit (1 if burst, else 0)
  //        then N x 64-bit data words MSB-first
  //
  // This slave:
  //  - For read transactions: drives a sequence of 64-bit words on MISO
  //  - For write transactions: reconstructs 64-bit words from MOSI and prints them
  // ----------------------------------------------------------------

  // Predefined read data words (slave will send these back, in order)
  reg [63:0] read_q [0:15];
  integer    rq_rd_ptr;
  reg [15:0] header_full;  // holds the full 16-bit header for this last bit
  initial begin
    read_q[0] = 64'h1122_3344_5566_7788;
    read_q[1] = 64'hA1A2_A3A4_A5A6_A7A8;
    read_q[2] = 64'hB1B2_B3B4_B5B6_B7B8;
    read_q[3] = 64'hC1C2_C3C4_C5C6_C7C8;
    read_q[4] = 64'hD1D2_D3D4_D5D6_D7D8;
    read_q[5] = 64'hE1E2_E3E4_E5E6_E7E8;
    rq_rd_ptr = 0;
  end
  // ----------------------------------------------------------------
  // Write-data queue: each entry is one 64-bit word for burst write
  // ----------------------------------------------------------------
  reg [63:0] write_q [0:15];

  initial begin
    // You can customize these patterns as you like
    write_q[0] = 64'h0101_0101_0101_0101;
    write_q[1] = 64'h0202_0202_0202_0202;
    write_q[2] = 64'h0303_0303_0303_0303;
    write_q[3] = 64'h0404_0404_0404_0404;
    write_q[4] = 64'h0505_0505_0505_0505;
    write_q[5] = 64'h0606_0606_0606_0606;
    write_q[6] = 64'h0707_0707_0707_0707;
    write_q[7] = 64'h0808_0808_0808_0808;
  end

  // Internal state of slave
  reg [15:0] hdr_sr;          // header shift register
  reg [4:0]  hdr_bit_cnt;     // counts 0..15 header bits
  reg [6:0]  data_bit_cnt;    // counts 0..63 data bits

  reg        in_hdr;          // currently receiving header
  reg        in_data;         // currently in data phase
  reg        rw_is_write;     // 1=write, 0=read
  reg        skip_first_edge; // skip first posedge after CS low (no header bit yet)

  reg [63:0] miso_sr;         // data to be sent to master (for reads)
  reg [63:0] mosi_sr;         // data received from master (for writes)
  reg [63:0] write_word;

  // Start of a transaction: CS goes low
  always @(negedge O_SS or negedge I_RSTN) begin
    if (!I_RSTN) begin
      in_hdr         <= 1'b0;
      in_data        <= 1'b0;
      hdr_bit_cnt    <= 5'd0;
      data_bit_cnt   <= 7'd0;
      hdr_sr         <= 16'd0;
      rw_is_write    <= 1'b0;
      skip_first_edge<= 1'b0;
      miso_sr        <= 64'd0;
      mosi_sr        <= 64'd0;
      I_MISO         <= 1'b0;
    end else begin
      // new transaction
      in_hdr         <= 1'b1;
      in_data        <= 1'b0;
      hdr_bit_cnt    <= 5'd0;
      data_bit_cnt   <= 7'd0;
      hdr_sr         <= 16'd0;
      rw_is_write    <= 1'b0;
      skip_first_edge<= 1'b1;   // first posedge after CS low is still in S_CS_LOW
      miso_sr        <= 64'd0;
      mosi_sr        <= 64'd0;
      // do not change rq_rd_ptr here, so multiple transactions can walk through queue
    end
  end

  // End of transaction: CS goes high
  always @(posedge O_SS or negedge I_RSTN) begin
    if (!I_RSTN) begin
      in_hdr   <= 1'b0;
      in_data  <= 1'b0;
      I_MISO   <= 1'b0;
    end else begin
      in_hdr   <= 1'b0;
      in_data  <= 1'b0;
      I_MISO   <= 1'b0;
    end
  end

  // Posedge: sample MOSI (header + write data), update counters
always @(posedge I_CLK or negedge I_RSTN) begin
  if (!I_RSTN) begin
    hdr_sr          <= 16'd0;
    hdr_bit_cnt     <= 5'd0;
    data_bit_cnt    <= 7'd0;
    in_hdr          <= 1'b0;
    in_data         <= 1'b0;
    rw_is_write     <= 1'b0;
    skip_first_edge <= 1'b0;
    mosi_sr         <= 64'd0;
    header_full     <= 16'd0;
  end else if (!O_SS) begin
    // only active when CS is low
    if (in_hdr) begin
      // ignore first posedge after CS low (still S_CS_LOW on master side)
      if (skip_first_edge) begin
        skip_first_edge <= 1'b0;
      end else begin
        // build the new header value (MSB-first)
        header_full = {hdr_sr[14:0], O_MOSI};
        hdr_sr      <= header_full;

        if (hdr_bit_cnt == 5'd15) begin
          // header complete on this cycle
          rw_is_write <= header_full[15];

          $display("[%0t] SLV: header received = 0x%04h (is_write=%0d)",
                   $time, header_full, header_full[15]);

          in_hdr       <= 1'b0;
          in_data      <= 1'b1;
          hdr_bit_cnt  <= 5'd0;
          data_bit_cnt <= 7'd0;

          if (!header_full[15]) begin
            // read transaction: prepare first 64-bit word
            miso_sr <= read_q[rq_rd_ptr];
            $display("[%0t] SLV: prepare read word 0 = 0x%016h",
                     $time, read_q[rq_rd_ptr]);
          end
        end else begin
          hdr_bit_cnt <= hdr_bit_cnt + 5'd1;
        end
      end

    end else if (in_data) begin
      // data phase (保持你原来的写代码)
      if (rw_is_write) begin
        // collect write data from MOSI, MSB-first
        mosi_sr <= {mosi_sr[62:0], O_MOSI};
      end

      if (data_bit_cnt == 7'd63) begin
          if (rw_is_write) begin
          // Compose the full 64-bit word (MSB-first)
             write_word = {mosi_sr[62:0], O_MOSI};

             $display("[%0t] SLV: received WRITE word = 0x%016h",
                       $time, write_word);

             // Option A: clear shift register for next word
             mosi_sr <= 64'd0;
          end else begin
          rq_rd_ptr <= rq_rd_ptr + 1;
          miso_sr   <= read_q[rq_rd_ptr + 1];
          $display("[%0t] SLV: prepare next READ word = 0x%016h",
                   $time, read_q[rq_rd_ptr + 1]);
        end
        data_bit_cnt <= 7'd0;
      end else begin
        data_bit_cnt <= data_bit_cnt + 7'd1;
      end
    end
  end
end


  // Nedge: drive MISO during read data phase (MSB-first)
  always @(negedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) begin
      I_MISO <= 1'b0;
    end else if (!O_SS && in_data && !rw_is_write) begin
      // read transaction: drive miso_sr[63:0], MSB-first
      I_MISO <= miso_sr[63];
      miso_sr <= {miso_sr[62:0], 1'b0};
    end else begin
      // during header or write, MISO is 0
      I_MISO <= 1'b0;
    end
  end

  // ----------------------------------------------------------------
  // Monitor DUT read data
  // ----------------------------------------------------------------
  always @(posedge I_CLK) begin
    if (rvalid) begin
      $display("[%0t] MON: DUT rdata (rvalid=1) = 0x%016h",
               $time, rdata);
    end
  end

  // ----------------------------------------------------------------
  // Stimulus tasks for the master interface
  // ----------------------------------------------------------------
  task do_single_read(input [13:0] addr);
    begin
      @(negedge I_CLK);
      is_write  <= 1'b0;
      byte_addr <= addr;
      burst_len <= 16'd1;
      start     <= 1'b1;
      @(negedge I_CLK);
      start     <= 1'b0;
      wait(done);
      @(negedge I_CLK);
    end
  endtask

  task do_single_write(input [13:0] addr, input [63:0] data);
    begin
      @(negedge I_CLK);
      is_write  <= 1'b1;
      byte_addr <= addr;
      burst_len <= 16'd1;
      wdata     <= data;
      start     <= 1'b1;
      @(negedge I_CLK);
      start     <= 1'b0;
      wait(done);
      @(negedge I_CLK);
    end
  endtask

  task do_burst_read(input [13:0] addr, input [15:0] words);
    begin
      @(negedge I_CLK);
      is_write  <= 1'b0;
      byte_addr <= addr;
      burst_len <= words;
      start     <= 1'b1;
      @(negedge I_CLK);
      start     <= 1'b0;
      wait(done);
      @(negedge I_CLK);
    end
  endtask

task do_burst_write(input [13:0] addr, input [15:0] words);
    integer i;
    begin
      @(negedge I_CLK);
      is_write  <= 1'b1;
      byte_addr <= addr;
      burst_len <= words;

      // Load first word from write_q[0]
      wdata     <= write_q[0];
      start     <= 1'b1;
      @(negedge I_CLK);
      start     <= 1'b0;

      // For each subsequent word, update wdata once per 64-bit frame
      // NOTE: this is an approximate timing model (no ready/valid handshake)
      for (i = 1; i < words; i = i + 1) begin
        repeat (60) @(negedge I_CLK);   // ~ one 64-bit word time
        wdata <= write_q[i];
      end

      // Wait until DUT finishes the whole burst
      wait(done);
      @(negedge I_CLK);
    end
endtask


  // ----------------------------------------------------------------
  // Testbench main sequence
  // ----------------------------------------------------------------
  initial begin
    // Dump VCD for waveform viewing if using Icarus/GTKWave etc.
    $dumpfile("spi_tb.vcd");
    $dumpvars(0, tb_spi);

    // Init
    start     = 1'b0;
    is_write  = 1'b0;
    byte_addr = 14'h0000;
    burst_len = 16'd0;
    wdata     = 64'h0;
    I_MISO    = 1'b0;

    // Reset
    #(10*TCK);
    I_RSTN = 1'b1;

    // 1) Single read
    do_single_read(14'h0100);

    // 2) Single write
    do_single_write(14'h0200, 64'hDEAD_BEEF_CAFE_BABE);
    //do_single_write(14'h0200, 64'h0000_0000_0001_0001);
    // 3) Burst read of 3 words
    do_burst_read(14'h0300, 16'd3);

    // 4) Burst write of 3 words
    do_burst_write(14'h0400, 16'd3);

    // Let simulation run a little more then finish
    #(5_000);   // 5 us
    $finish;
  end

endmodule

