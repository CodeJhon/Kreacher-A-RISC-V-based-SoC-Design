`timescale 1ns/1ps

module spi_slave_interface #(
  parameter integer XLEN     = 64,
  parameter integer DATA_W   = 64,
  parameter integer ADDR14_W = 14
)(
  input  wire                 I_CLK,
  input  wire                 I_RSTN,
  input  wire                 I_SS_N,
  input  wire                 I_MOSI,
  output reg                  O_MISO,

  // external memory interface
  output wire                 external_mem_we,
  output wire                 external_mem_cs,
  output reg  [ADDR14_W-1:0]  external_mem_addr,
  output wire [XLEN-1:0]      external_mem_wdata,
  input  wire [XLEN-1:0]      external_mem_rdata
);


  // ------------------------------------------------------------
  // FSM
  // ------------------------------------------------------------
  localparam [1:0]
    S_IDLE = 2'd0,
    S_HDR  = 2'd1,
    S_DATA = 2'd2;

  reg [1:0] state;

  assign external_mem_cs = state == S_DATA;

  // Header receive (MSB-first): [15]=RW, [14:1]=ADDR14, [0]=dummy
  reg [4:0]  hdr_cnt;
  reg        is_write;

  // Data path
  reg [DATA_W-1:0] rx_shift;
  reg [DATA_W-1:0] tx_shift;
  reg [6:0]        bit_cnt;

  // Drop one dummy bit-time after header
  reg dummy_skip;

  // First data bit of each read word uses RAM MSB directly
  reg rd_first_bit;

  // ------------------------------------------------------------
  // Write interface (capture on last data bit)
  // ------------------------------------------------------------
  assign external_mem_we =
      (state == S_DATA) && is_write && !dummy_skip && (bit_cnt == 7'd0);

  assign external_mem_wdata = {rx_shift[DATA_W-2:0], I_MOSI};

  // ------------------------------------------------------------
  // MISO output -> With a half-cycle delay to mimic real-life delays
  // ------------------------------------------------------------
  always @(negedge I_CLK, negedge I_RSTN) begin
    if (!I_RSTN) begin
      O_MISO <= 1'b0;
    end else if (I_SS_N) begin
      O_MISO <= 1'b0;
    end else if ((state == S_DATA) && !is_write && !dummy_skip) begin
      O_MISO <= rd_first_bit ? external_mem_rdata[DATA_W-1] : tx_shift[DATA_W-1];
    end else begin
      O_MISO <= 1'b0;
    end
  end

  // ------------------------------------------------------------
  // Sequential
  // ------------------------------------------------------------
  always @(posedge I_CLK or negedge I_RSTN) begin
    if (!I_RSTN) begin
      state             <= S_IDLE;
      hdr_cnt           <= 5'd0;
      is_write          <= 1'b0;
      external_mem_addr <= {ADDR14_W{1'b0}};

      rx_shift          <= {DATA_W{1'b0}};
      tx_shift          <= {DATA_W{1'b0}};
      bit_cnt           <= 7'd0;

      dummy_skip        <= 1'b0;
      rd_first_bit      <= 1'b0;

    end else begin
      if (I_SS_N) begin
        state        <= S_IDLE;
        hdr_cnt      <= 5'd0;
        bit_cnt      <= 7'd0;
        dummy_skip   <= 1'b0;
        rd_first_bit <= 1'b0;

      end else begin
        case (state)

          S_IDLE: begin
            state             <= S_HDR;
            hdr_cnt           <= 5'd14;
            is_write          <= I_MOSI;
            external_mem_addr <= {ADDR14_W{1'b0}};

            rx_shift          <= {DATA_W{1'b0}};
            tx_shift          <= {DATA_W{1'b0}};
            bit_cnt           <= 7'd0;

            dummy_skip        <= 1'b0;
            rd_first_bit      <= 1'b0;
          end

          S_HDR: begin
            // RW bit (first header bit)
            // Address bits [14:1], MSB-first
            if ((hdr_cnt <= 5'd14) && (hdr_cnt >= 5'd1)) begin
              external_mem_addr <= {external_mem_addr[ADDR14_W-2:0], I_MOSI};
            end

            // After receiving header[1], next bit-time is dummy (header[0])
            if (hdr_cnt == 5'd1) begin
              state        <= S_DATA;
              bit_cnt      <= DATA_W - 1;
              dummy_skip   <= 1'b1;
              rd_first_bit <= 1'b1;

              rx_shift     <= {DATA_W{1'b0}};
              tx_shift     <= {DATA_W{1'b0}};
            end else begin
              hdr_cnt <= hdr_cnt - 5'd1;
            end
          end

          S_DATA: begin
            // Dummy bit-time: ignore MOSI and do not advance counters
            if (dummy_skip) begin
              dummy_skip <= 1'b0;

            end else begin
              if (is_write) begin
                // Write: shift in data
                rx_shift <= {rx_shift[DATA_W-2:0], I_MOSI};

                if (bit_cnt != 0) begin
                  bit_cnt <= bit_cnt - 7'd1;
                end else begin
                  bit_cnt           <= DATA_W - 1;
                  external_mem_addr <= external_mem_addr + 1;
                end

              end else begin
                // Read: first bit uses RAM MSB, remaining bits use tx_shift
                if (rd_first_bit) begin
                  tx_shift     <= {external_mem_rdata[DATA_W-2:0], 1'b0};
                  rd_first_bit <= 1'b0;

                  if (bit_cnt != 0) begin
                    bit_cnt <= bit_cnt - 7'd1;
                  end else begin
                    bit_cnt      <= DATA_W - 1;
                    rd_first_bit <= 1'b1;
                  end

                end else begin
                  tx_shift <= {tx_shift[DATA_W-2:0], 1'b0};

                  // Prefetch next word early (sync RAM latency hiding)
                  if (bit_cnt == 32) begin
                    external_mem_addr <= external_mem_addr + 1;
                  end

                  if (bit_cnt != 0) begin
                    bit_cnt <= bit_cnt - 7'd1;
                  end else begin
                    bit_cnt      <= DATA_W - 1;
                    rd_first_bit <= 1'b1;
                    tx_shift     <= {DATA_W{1'b0}};
                  end
                end
              end
            end
          end

          default: begin
            state <= S_IDLE;
          end

        endcase
      end
    end
  end

endmodule
